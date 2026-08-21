extends Node

signal state_changed
signal activity_received(text)

const START_BUILDINGS := {
	"island_core": 1,
	"lootling_house": 1,
	"cannon_workshop": 1,
	"crystal_mine": 1,
	"airship_harbor": 1,
}
const LOCAL_SAVE_PATH := "user://loot_launch_local_save.json"

var live_mode := false
var authenticated := false
var is_guest := true
var profile := {"public_id":"local-player", "username":"launch_rookie", "display_name":"Launch Rookie", "avatar":"bouncer", "island_level":1, "trophies":100}
var wallet := {"coins":1500, "crystals":25, "trophies":100}
var energy := {"current":10, "maximum":10, "next_regeneration_unix":0}
var buildings := START_BUILDINGS.duplicate(true)
var lootlings := ["bouncer", "magneto", "blasto", "blink"]
var cannons := ["standard", "thunder", "portal"]
var worlds := ["wolkengarten", "crystal_forge"]
var selected_lootling := "bouncer"
var selected_cannon := "standard"
var selected_world := "wolkengarten"
var activity := []
var processed_launches := {}
var processed_upgrades := {}
var current_attack := {}
var settings := {"music":0.75, "sound":0.9, "vibration":true, "quality":2}
var friends := []
var relics := ["wind_splinter"]
var mission_claims := {}
var launch_stats := {"launches":0,"objects_hit":0,"upgrades":0,"objectives":0,"chests":0,"specials":0,"best_combo":0,"wolkengarten_runs":0,"crystal_forge_runs":0}
var mission_day := int(Time.get_unix_time_from_system() / 86400.0)
var world_boss_state := {"name":"Der Tresorwal","current":720000,"maximum":1000000,"personal":0}
var mine_last_claim_unix := 0
var pending_world_boss := false
var backend

func _ready():
	energy.next_regeneration_unix = int(Time.get_unix_time_from_system()) + 600
	backend = preload("res://scripts/backend/local_development_backend.gd").new(self)
	_load_backend_config()
	_load_settings()
	_load_local_save()
	AudioManager.apply_settings(settings)

func use_supabase(url:String, publishable_key:String, functions_url:String):
	backend = preload("res://scripts/backend/supabase_backend.gd").new(url, publishable_key, functions_url)
	add_child(backend)
	live_mode = true

func login_guest():
	await get_tree().process_frame
	authenticated = true
	is_guest = true
	_save_local_state()
	return {"ok":true}

func register(email:String, password:String):
	var result = await backend.register(email, password)
	if result.get("ok", false):
		authenticated = true
		if live_mode: await sync_cloud_save()
	return result

func login(email:String, password:String):
	var result = await backend.login(email, password)
	if result.get("ok", false):
		authenticated = true
		if live_mode: await sync_cloud_save()
	return result

func reset_password(email:String):
	if not backend.has_method("reset_password"):return {"ok":false,"error":"Passwort-Reset benötigt das Live-Backend."}
	return await backend.reset_password(email)

func reserve_profile(username:String, display_name:String, avatar:String):
	var result = await backend.reserve_profile(username, display_name, avatar)
	if result.get("ok", false):
		profile.username = username.to_lower()
		profile.display_name = display_name if not display_name.strip_edges().is_empty() else username
		profile.avatar = avatar
		state_changed.emit()
		_save_local_state()
	return result

func start_launch():
	ensure_mission_day()
	return await backend.start_launch(selected_lootling, selected_cannon, selected_world)

func cancel_launch(session_id:String):
	var result=await backend.cancel_launch(session_id)
	if result.get("ok",false):_save_local_state()
	return result

func submit_launch(submission:Dictionary):
	var result = await backend.submit_launch(submission)
	if result.get("ok",false) and not result.get("already_processed",false):
		launch_stats.launches = int(launch_stats.launches)+1
		for event in submission.get("events",[]):
			if event.get("type","") in ["coin","crystal","treasure","portal","bounce"]:
				launch_stats.objects_hit = int(launch_stats.objects_hit)+1
			if str(event.get("target","")).begins_with("objective_island_"):
				launch_stats.objectives = int(launch_stats.get("objectives",0))+1
			if event.get("type","")=="treasure":launch_stats.chests=int(launch_stats.get("chests",0))+1
			if event.get("type","")=="ability":launch_stats.specials=int(launch_stats.get("specials",0))+1
		launch_stats.best_combo=maxi(int(launch_stats.get("best_combo",0)),int(result.get("combo",0)))
		var completed_world:=str(submission.get("world_key",selected_world))
		var world_stat:="crystal_forge_runs" if completed_world=="crystal_forge" else "wolkengarten_runs"
		launch_stats[world_stat]=int(launch_stats.get(world_stat,0))+1
		_save_local_state()
	if live_mode and result.get("ok",false): await sync_cloud_save()
	return result

func upgrade_building(kind:String, key:String):
	ensure_mission_day()
	var result = await backend.upgrade_building(kind, key)
	if result.get("ok",false) and not result.get("already_processed",false):
		launch_stats.upgrades = int(launch_stats.upgrades)+1
		_save_local_state()
	if live_mode and result.get("ok",false): await sync_cloud_save()
	return result

func find_target():
	return await backend.find_target(true)

func start_attack(target:Dictionary):
	return await backend.start_attack(target)

func submit_attack_shot(shot:Dictionary):
	var result = await backend.submit_attack_shot(shot)
	if result.get("ok",false) and result.get("complete",false): _save_local_state()
	if live_mode and result.get("ok",false) and result.get("complete",false): await sync_cloud_save()
	return result

func get_leaderboard():
	return await backend.get_leaderboard()

func get_world_boss():
	return await backend.get_world_boss()

func contribute_world_boss(damage:int):
	var result=await backend.contribute_world_boss(damage)
	if result.get("ok",false): _save_local_state()
	return result

func claim_mine():
	var result=await backend.claim_mine()
	if result.get("ok",false): _save_local_state()
	return result

func claim_missions():
	var result=await backend.claim_missions()
	if result.get("ok",false): _save_local_state()
	return result

func search_players(query:String): return await backend.search_players(query)

func add_friend(player:Dictionary):
	var result=await backend.add_friend(player)
	if result.get("ok",false): _save_local_state()
	return result

func remove_friend(public_id:String):
	var result=await backend.remove_friend(public_id)
	if result.get("ok",false): _save_local_state()
	return result

func select_loadout(lootling_key:String,cannon_key:String):
	if lootling_key in lootlings: selected_lootling=lootling_key
	if cannon_key in cannons: selected_cannon=cannon_key
	_save_local_state()
	state_changed.emit()

func select_world(world_key:String):
	if world_key in worlds:selected_world=world_key
	_save_local_state()
	state_changed.emit()

func sync_cloud_save():
	if not live_mode or not backend.has_method("load_cloud_save"):
		return
	var result = await backend.load_cloud_save()
	if not result.get("ok", false):
		return
	var data:Dictionary = result.get("data", {})
	var p:Dictionary = data.get("Profile", {})
	var w:Dictionary = data.get("Wallet", {})
	var e:Dictionary = data.get("Energy", {})
	profile = {"public_id":p.get("PublicId",""),"username":p.get("Username",""),"display_name":p.get("DisplayName","Sky Rookie"),"avatar":p.get("AvatarKey","bouncer"),"island_level":p.get("IslandLevel",1),"trophies":p.get("Trophies",100)}
	wallet = {"coins":w.get("Coins",0),"crystals":w.get("Crystals",0),"trophies":w.get("Trophies",0)}
	energy = {"current":e.get("Current",0),"maximum":e.get("Maximum",10),"next_regeneration_unix":int(Time.get_unix_time_from_system())+600}
	for building in data.get("Buildings", []):
		var keys := ["island_core","lootling_house","cannon_workshop","crystal_mine","airship_harbor"]
		var index := clampi(int(building.get("Kind",0)),0,4)
		buildings[keys[index]] = int(building.get("Level",1))
	selected_lootling=["bouncer","magneto","blasto","blink"][clampi(int(data.get("EquippedLootling",0)),0,3)]
	selected_cannon=["standard","thunder","portal"][clampi(int(data.get("EquippedCannon",0)),0,2)]
	activity=[]
	for item in data.get("Activity",[]):
		activity.append(str(item.get("Message",item.get("message","Aktivität"))) if item is Dictionary else str(item))
	state_changed.emit()

func logout():
	_save_local_state()
	authenticated = false
	state_changed.emit()

func add_activity(text:String):
	activity.push_front(text)
	if activity.size() > 20: activity.resize(20)
	activity_received.emit(text)

func refresh_energy():
	var now := int(Time.get_unix_time_from_system())
	while energy.current < energy.maximum and now >= energy.next_regeneration_unix:
		energy.current += 1
		energy.next_regeneration_unix += 600
	state_changed.emit()

func ensure_mission_day():
	var today:=int(Time.get_unix_time_from_system()/86400.0)
	if today==mission_day:return
	mission_day=today
	launch_stats={"launches":0,"objects_hit":0,"upgrades":0,"objectives":0,"chests":0,"specials":0,"best_combo":0,"wolkengarten_runs":0,"crystal_forge_runs":0}
	_save_local_state()
	state_changed.emit()

func island_level() -> int:
	var total := 0
	for value in buildings.values(): total += int(value)
	return maxi(1, int(floor(total / 5.0)))

func upgrade_cost(level:int) -> int: return 0 if level >= 5 else 150 * level * level

func save_setting(key:String, value):
	settings[key] = value
	var cfg := ConfigFile.new()
	for k in settings: cfg.set_value("settings", k, settings[k])
	cfg.save("user://settings.cfg")
	AudioManager.apply_settings(settings)

func _load_settings():
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK: return
	for key in settings: settings[key] = cfg.get_value("settings", key, settings[key])

func _load_backend_config():
	if not FileAccess.file_exists("res://config/backend.json"):
		return
	var file := FileAccess.open("res://config/backend.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and not str(parsed.get("supabase_url", "")).is_empty() and not str(parsed.get("publishable_key", "")).is_empty():
		use_supabase(str(parsed.supabase_url), str(parsed.publishable_key), str(parsed.get("functions_url", "")))

func _save_local_state():
	if live_mode: return
	var data:={
		"profile":profile,"wallet":wallet,"energy":energy,"buildings":buildings,
		"selected_lootling":selected_lootling,"selected_cannon":selected_cannon,"selected_world":selected_world,
		"activity":activity,"friends":friends,"relics":relics,"mission_claims":mission_claims,
		"launch_stats":launch_stats,"mission_day":mission_day,"world_boss_state":world_boss_state,
		"mine_last_claim_unix":mine_last_claim_unix
	}
	var file:=FileAccess.open(LOCAL_SAVE_PATH,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(data))

func _load_local_save():
	if live_mode or not FileAccess.file_exists(LOCAL_SAVE_PATH):
		if mine_last_claim_unix==0: mine_last_claim_unix=int(Time.get_unix_time_from_system())-600
		return
	var file:=FileAccess.open(LOCAL_SAVE_PATH,FileAccess.READ)
	if file==null:return
	var data=JSON.parse_string(file.get_as_text())
	if not data is Dictionary:return
	profile=data.get("profile",profile);wallet=data.get("wallet",wallet);energy=data.get("energy",energy);buildings=data.get("buildings",buildings)
	selected_lootling=str(data.get("selected_lootling",selected_lootling));selected_cannon=str(data.get("selected_cannon",selected_cannon));selected_world=str(data.get("selected_world",selected_world))
	if selected_world not in worlds:selected_world="wolkengarten"
	activity=data.get("activity",activity);friends=data.get("friends",friends);relics=data.get("relics",relics);mission_claims=data.get("mission_claims",mission_claims)
	launch_stats=data.get("launch_stats",launch_stats);_normalize_launch_stats();mission_day=int(data.get("mission_day",mission_day));world_boss_state=data.get("world_boss_state",world_boss_state)
	mine_last_claim_unix=int(data.get("mine_last_claim_unix",int(Time.get_unix_time_from_system())-600))
	ensure_mission_day()
	refresh_energy()


func _normalize_launch_stats():
	for key in ["launches","objects_hit","upgrades","objectives","chests","specials","best_combo","wolkengarten_runs","crystal_forge_runs"]:
		if not launch_stats.has(key):launch_stats[key]=0
