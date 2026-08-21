extends Node

var base_url:String
var publishable_key:String
var functions_url:String
var access_token := ""
var refresh_token := ""

func _init(url:String, key:String, functions:String):
	base_url = url.trim_suffix("/")
	publishable_key = key
	functions_url = functions.trim_suffix("/") if not functions.is_empty() else base_url + "/functions/v1"
	if key.to_lower().contains("service_role"): push_error("Never place a service-role key in Godot.")

func register(email:String, password:String): return await _auth("/auth/v1/signup", {"email":email,"password":password})
func login(email:String, password:String): return await _auth("/auth/v1/token?grant_type=password", {"email":email,"password":password})
func reset_password(email:String):
	if not email.contains("@"):return {"ok":false,"error":"Bitte eine gültige E-Mail-Adresse eingeben."}
	var result=await _request(base_url+"/auth/v1/recover",{"email":email},false)
	return {"ok":result.get("ok",false),"error":result.get("error","")}

func reserve_profile(username:String, display_name:String, avatar:String): return await _edge("profile-reserve", {"username":username,"display_name":display_name,"avatar_key":avatar})

func load_cloud_save():
	var result = await _edge("cloud-save", {})
	return {"ok":result.get("ok",false),"data":result,"error":result.get("error","")}

func start_launch(lootling:String, cannon:String, world_key:="wolkengarten"):
	var r = await _edge("launch-start", {"lootling":lootling,"cannon":cannon,"world_key":world_key})
	if not r.get("ok",false): return r
	return {"ok":true,"session_id":r.get("SessionId",""),"seed":r.get("Seed",0),"expires_unix":int(Time.get_unix_time_from_system())+900,"max_coins":r.get("MaxCoins",500),"max_crystals":r.get("MaxCrystals",5),"world_key":r.get("WorldKey",world_key),"level_key":r.get("LevelKey","")}

func submit_launch(submission:Dictionary):
	var outbound := {"SessionId":submission.get("session_id",""),"Angle":submission.get("angle",0),"Power":submission.get("power",0),"AbilityTime":submission.get("ability_time",-1),"Events":[],"Checksum":submission.get("checksum","")}
	for event in submission.get("events",[]):
		outbound.Events.append({"Sequence":event.get("sequence",0),"EventType":event.get("type",""),"TargetId":event.get("target",""),"Time":event.get("time",0),"X":event.get("x",0),"Y":event.get("y",0),"Speed":event.get("speed",0),"Value":event.get("value",0)})
	var r = await _edge("launch-submit",outbound)
	if not r.get("ok",false):return r
	return {"ok":true,"coins":r.get("Coins",0),"crystals":r.get("Crystals",0),"combo":r.get("Combo",0),"rare":r.get("RareHit",false),"already_processed":r.get("WasAlreadyProcessed",false)}
func cancel_launch(_session_id:String):return {"ok":false,"error":"Eine gestartete Live-Session kann nicht zurückgenommen werden."}
func upgrade_building(kind:String, key:String): return await _edge("building-upgrade", {"building_kind":kind,"idempotency_key":key})
func find_target(allow_training:bool):
	var r=await _edge("matchmake", {"allow_training":allow_training})
	if not r.get("ok",false):return r
	return {"ok":true,"target":{"public_id":r.get("PublicId",""),"username":r.get("Username",""),"display_name":r.get("DisplayName",""),"avatar":r.get("AvatarKey","bouncer"),"island_level":r.get("IslandLevel",1),"trophies":r.get("Trophies",0),"training_bot":r.get("IsTrainingBot",false)}}

func start_attack(target:Dictionary):
	var r=await _edge("attack-start", {"target_public_id":target.public_id,"revenge_attack_id":null})
	if not r.get("ok",false):return r
	return {"ok":true,"attack":{"id":r.get("AttackId",""),"target":target,"shots":0,"hits":0,"coins":0,"seed":r.get("Seed",0)}}

func submit_attack_shot(shot:Dictionary):
	var r=await _edge("attack-submit", shot)
	if not r.get("ok",false):return r
	return {"ok":true,"complete":r.get("Complete",false),"hits":r.get("BuildingsHit",0),"coins":r.get("CoinsStolen",0),"trophy_delta":r.get("TrophyDelta",0)}

func get_leaderboard():
	var r=await _edge("leaderboard-global", {})
	if not r.get("ok",false):return r
	var items:=[]
	for row in r.get("items",[]): items.append({"name":row.get("Profile",{}).get("DisplayName","Player"),"score":row.get("Score",0),"training_bot":row.get("Profile",{}).get("IsTrainingBot",false)})
	return {"ok":true,"items":items}

func get_world_boss():
	var r=await _edge("world-boss", {})
	if not r.get("ok",false):return r
	return {"ok":true,"name":r.get("Name","World Boss"),"current":r.get("CurrentHealth",0),"maximum":r.get("MaximumHealth",1),"personal":r.get("PersonalContribution",0),"training":false}

func contribute_world_boss(damage:int):
	var r=await _edge("world-boss-contribute",{"score":damage,"idempotency_key":"boss-%x-%x"%[Time.get_ticks_usec(),randi()]})
	if not r.get("ok",false):return r
	return {"ok":true,"damage":mini(1000,damage),"coins":0,"current":r.get("CurrentHealth",0),"personal":r.get("PersonalContribution",0)}

func claim_mine():
	var r=await _edge("mine-claim",{"idempotency_key":"mine-%x-%x"%[Time.get_ticks_usec(),randi()]})
	if not r.get("ok",false):return r
	return {"ok":true,"crystals":r.get("Crystals",0)}

func claim_missions():
	var r=await _edge("missions-claim",{"idempotency_key":"missions-%x-%x"%[Time.get_ticks_usec(),randi()]})
	if not r.get("ok",false):return r
	return {"ok":true,"claimed":r.get("Claimed",0),"coins":r.get("Coins",0),"crystals":r.get("Crystals",0)}

func search_players(query:String):
	var r=await _edge("friends-search",{"username":query})
	if not r.get("ok",false):return r
	var items:=[]
	for row in r.get("items",[]):items.append({"public_id":row.get("PublicId",""),"username":row.get("Username",""),"display_name":row.get("DisplayName","Spieler"),"avatar":row.get("AvatarKey","bouncer"),"island_level":row.get("IslandLevel",1),"trophies":row.get("Trophies",0),"training_bot":row.get("IsTrainingBot",false)})
	return {"ok":true,"items":items}

func add_friend(player:Dictionary):
	return await _edge("friends-request",{"target_public_id":player.get("public_id","")})

func remove_friend(public_id:String):
	return await _edge("friends-remove",{"target_public_id":public_id})

func _auth(path:String, body:Dictionary):
	var result = await _request(base_url+path, body, false)
	if result.ok and result.data.has("access_token"):
		access_token = result.data.access_token; refresh_token = result.data.get("refresh_token", "")
		return {"ok":true}
	if result.ok and result.data.has("user"): return {"ok":false,"error":"Verify your email, then log in."}
	return {"ok":false,"error":result.error}

func _edge(function_name:String, body:Dictionary):
	var result = await _request(functions_url+"/"+function_name, body, true)
	if result.ok:
		var data:Dictionary = result.data
		data.ok = true
		return data
	return {"ok":false,"error":result.error}

func _request(url:String, body:Dictionary, authenticated:bool):
	var http := HTTPRequest.new(); add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json", "apikey: "+publishable_key])
	if authenticated: headers.append("Authorization: Bearer "+access_token)
	var error := http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK: http.queue_free(); return {"ok":false,"error":"Network request could not start."}
	var response = await http.request_completed; http.queue_free()
	var code:int = response[1]; var raw:PackedByteArray = response[3]; var parsed = JSON.parse_string(raw.get_string_from_utf8())
	if code >= 200 and code < 300: return {"ok":true,"data":parsed if parsed is Dictionary else {}}
	return {"ok":false,"error":str(parsed.get("error","Request failed (%d)."%code)) if parsed is Dictionary else "Request failed (%d)."%code}
