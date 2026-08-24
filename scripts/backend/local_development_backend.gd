extends RefCounted

var state
var random := RandomNumberGenerator.new()
var shot_results := {}
var launch_sessions := {}

func _init(game_state):
	state = game_state
	random.seed = 7331

func register(email:String, password:String):
	await state.get_tree().process_frame
	if not email.contains("@") or password.length() < 8: return {"ok":false, "error":"Valid email and 8+ password characters required."}
	return {"ok":true, "local":true}

func login(email:String, password:String): return await register(email, password)
func reset_password(_email:String):return {"ok":false,"error":"Passwort-Reset benötigt das Live-Backend."}

func reserve_profile(username:String, _display_name:String, avatar:String):
	await state.get_tree().process_frame
	var valid := RegEx.new(); valid.compile("^[a-z0-9_]{3,20}$")
	if valid.search(username.to_lower()) == null: return {"ok":false, "error":"Username must be 3–20 letters, numbers or underscores."}
	if avatar not in state.lootlings: return {"ok":false, "error":"Unknown avatar."}
	return {"ok":true}

func start_launch(_lootling:String, _cannon:String, _world_key:="wolkengarten"):
	await state.get_tree().process_frame
	state.refresh_energy()
	if state.energy.current <= 0: return {"ok":false, "error":"No energy available."}
	state.energy.current -= 1
	if _world_key not in ["wolkengarten","crystal_forge","v41_benchmark"]:return {"ok":false,"error":"Unknown expedition."}
	var session_id:=_id();var session:={"ok":true,"session_id":session_id,"seed":random.randi(),"expires_unix":int(Time.get_unix_time_from_system())+900,"max_coins":1500,"max_crystals":10,"lootling":_lootling,"cannon":_cannon,"world_key":_world_key,"level_key":"kristallschmiede_expedition_v1" if _world_key=="crystal_forge" else "wolkengarten_expedition_v1"}
	launch_sessions[session_id]=session.duplicate(true)
	state._save_local_state()
	return session

func submit_launch(submission:Dictionary):
	await state.get_tree().process_frame
	var id:String = submission.get("session_id", "")
	if state.processed_launches.has(id):
		var replay:Dictionary = state.processed_launches[id].duplicate(true); replay.already_processed = true; return replay
	if not launch_sessions.has(id):return {"ok":false,"error":"Unknown or expired launch session."}
	var session:Dictionary=launch_sessions[id]
	if int(Time.get_unix_time_from_system())>int(session.expires_unix):return {"ok":false,"error":"Launch session expired."}
	var angle:=float(submission.get("angle",-1));var power:=float(submission.get("power",-1))
	if angle<18.0 or angle>82.0 or power<0.2 or power>1.01:return {"ok":false,"error":"Invalid launch parameters."}
	var submitted_events:Array=submission.get("events",[])
	if submitted_events.size()>160:return {"ok":false,"error":"Too many launch events."}
	var coins := 0; var crystals := 0; var combo := 0
	var expected_sequence:=0
	for event in submitted_events:
		if int(event.get("sequence",-1))!=expected_sequence:continue
		expected_sequence+=1
		if float(event.get("speed", 0)) > 60.0: continue
		match event.get("type", ""):
			"coin": coins += mini(25, int(event.get("value", 0)))
			"crystal": crystals += mini(1, int(event.get("value", 0)))
			"treasure": coins += 100
		combo += 1
	coins = mini(int(session.get("max_coins",1500)), coins); crystals = mini(int(session.get("max_crystals",10)), crystals)
	state.wallet.coins += coins; state.wallet.crystals += crystals
	var result := {"ok":true, "coins":coins, "crystals":crystals, "combo":combo, "rare":crystals>0 or coins>=250, "already_processed":false}
	state.processed_launches[id] = result.duplicate(true)
	launch_sessions.erase(id)
	state.add_activity("Launch secured %d coins and %d crystals." % [coins, crystals])
	state.state_changed.emit()
	return result

func cancel_launch(session_id:String):
	await state.get_tree().process_frame
	if not launch_sessions.has(session_id):return {"ok":false,"error":"Abschuss wurde bereits verarbeitet."}
	launch_sessions.erase(session_id);state.energy.current=mini(int(state.energy.maximum),int(state.energy.current)+1);state._save_local_state()
	return {"ok":true,"energy_refunded":true}

func upgrade_building(kind:String, key:String):
	await state.get_tree().process_frame
	if state.processed_upgrades.has(key): return {"ok":true, "already_processed":true}
	if not state.buildings.has(kind): return {"ok":false, "error":"Building not found."}
	var level:int = state.buildings[kind]
	if level >= 5: return {"ok":false, "error":"Building is already max level."}
	var cost:int = state.upgrade_cost(level)
	if state.wallet.coins < cost: return {"ok":false, "error":"Not enough coins."}
	state.wallet.coins -= cost; state.buildings[kind] = level + 1; state.profile.island_level = state.island_level(); state.processed_upgrades[key] = true
	state.add_activity("%s reached level %d." % [kind.replace("_", " ").capitalize(), level+1]); state.state_changed.emit()
	return {"ok":true, "level":level+1, "cost":cost}

func find_target(allow_training:bool):
	await state.get_tree().process_frame
	if not allow_training: return {"ok":false, "error":"LOCAL DEV contains no registered players."}
	var bots := [
		{"public_id":"training-cog", "username":"cog_cadet_bot", "display_name":"Cog Cadet", "avatar":"blasto", "island_level":1, "trophies":92, "training_bot":true},
		{"public_id":"training-moss", "username":"moss_mate_bot", "display_name":"Moss Mate", "avatar":"magneto", "island_level":2, "trophies":118, "training_bot":true},
		{"public_id":"training-zap", "username":"zap_scout_bot", "display_name":"Zap Scout", "avatar":"blink", "island_level":1, "trophies":104, "training_bot":true},
	]
	return {"ok":true, "target":bots[random.randi_range(0, bots.size()-1)]}

func start_attack(target:Dictionary):
	await state.get_tree().process_frame
	if target.is_empty() or target.get("public_id","")==state.profile.get("public_id",""):return {"ok":false,"error":"Invalid attack target."}
	state.current_attack = {"id":_id(), "target":target, "shots":0, "hits":0, "coins":0, "seed":random.randi()}
	return {"ok":true, "attack":state.current_attack}

func submit_attack_shot(shot:Dictionary):
	await state.get_tree().process_frame
	var key:String = shot.get("idempotency_key", "")
	if key.is_empty():return {"ok":false,"error":"Missing idempotency key."}
	if shot_results.has(key): return shot_results[key]
	var attack:Dictionary = state.current_attack
	if attack.is_empty() or int(shot.get("number", 0)) != int(attack.shots)+1: return {"ok":false, "error":"Invalid shot order."}
	attack.shots += 1
	if float(shot.get("impact_speed", 0)) >= 2.0:
		attack.hits += 1; attack.coins += clampi(int(float(shot.impact_speed)*6.0), 20, 180)
	var complete:bool = attack.shots == 3
	var result := {"ok":true, "complete":complete, "hits":attack.hits, "coins":attack.coins if complete else 0, "trophy_delta":clampi(attack.hits*4-4,-4,8) if complete else 0}
	shot_results[key] = result.duplicate(true)
	if complete:
		state.wallet.coins += result.coins; state.wallet.trophies = maxi(0, state.wallet.trophies+result.trophy_delta); state.profile.trophies = state.wallet.trophies
		state.add_activity("Training attack: %d/3 hits, +%d coins, %+d trophies." % [result.hits,result.coins,result.trophy_delta])
	return result

func get_leaderboard():
	await state.get_tree().process_frame
	var items:=[{"name":"Moss Mate", "score":118, "training_bot":true},{"name":state.profile.display_name,"score":state.wallet.trophies,"training_bot":false},{"name":"Zap Scout","score":104,"training_bot":true}]
	for friend in state.friends:items.append({"name":friend.get("display_name","Crewmitglied"),"score":friend.get("trophies",100),"training_bot":true})
	return {"ok":true,"items":items}

func get_world_boss():
	await state.get_tree().process_frame
	return {"ok":true,"name":state.world_boss_state.name,"current":state.world_boss_state.current,"maximum":state.world_boss_state.maximum,"personal":state.world_boss_state.personal,"training":true}

func contribute_world_boss(damage:int):
	await state.get_tree().process_frame
	var accepted:=clampi(damage,10,5000)
	state.world_boss_state.current=maxi(0,int(state.world_boss_state.current)-accepted)
	state.world_boss_state.personal=int(state.world_boss_state.personal)+accepted
	var coins:=clampi(int(accepted/20.0),10,250);state.wallet.coins+=coins
	state.add_activity("Weltboss: %d Schaden verursacht, +%d Münzen."%[accepted,coins])
	return {"ok":true,"damage":accepted,"coins":coins,"current":state.world_boss_state.current,"personal":state.world_boss_state.personal}

func claim_mine():
	await state.get_tree().process_frame
	var now:=int(Time.get_unix_time_from_system());var elapsed:=now-int(state.mine_last_claim_unix);var amount:=mini(6,int(floor(elapsed/600.0)))
	if amount<=0:return {"ok":false,"error":"Die Kristallmine produziert noch.","remaining":600-elapsed}
	var cycles:=amount
	amount=cycles*int(state.buildings.get("crystal_mine",1))
	state.mine_last_claim_unix+=cycles*600
	state.wallet.crystals+=amount
	state.add_activity("Kristallmine: %d Kristalle eingesammelt."%amount)
	return {"ok":true,"crystals":amount}

func claim_missions():
	await state.get_tree().process_frame
	state.ensure_mission_day();state._normalize_launch_stats()
	var day:=str(int(Time.get_unix_time_from_system()/86400.0));var checks:=[int(state.launch_stats.launches)>=1,int(state.launch_stats.objects_hit)>=12,int(state.launch_stats.objectives)>=3,int(state.launch_stats.chests)>=3,int(state.launch_stats.upgrades)>=1];var claimed:=0
	for i in checks.size():
		var key:=day+":"+str(i)
		if checks[i] and not state.mission_claims.has(key):state.mission_claims[key]=true;claimed+=1
	if claimed==0:return {"ok":false,"error":"Noch keine neue Missionsbelohnung verfügbar."}
	var coins:=claimed*140;var crystals:=2 if claimed==5 else 0;state.wallet.coins+=coins;state.wallet.crystals+=crystals
	state.add_activity("Tagesmissionen: +%d Münzen, +%d Kristalle."%[coins,crystals])
	return {"ok":true,"claimed":claimed,"coins":coins,"crystals":crystals}

func search_players(query:String):
	await state.get_tree().process_frame
	var normalized:=query.strip_edges().to_lower();var results:=[]
	for player in _training_players():
		if normalized.is_empty() or str(player.username).contains(normalized) or str(player.display_name).to_lower().contains(normalized):results.append(player)
	return {"ok":true,"items":results}

func add_friend(player:Dictionary):
	await state.get_tree().process_frame
	var public_id:=str(player.get("public_id",""))
	if public_id.is_empty():return {"ok":false,"error":"Spieler nicht gefunden."}
	for friend in state.friends:
		if friend.get("public_id","")==public_id:return {"ok":false,"error":"Bereits in deiner Freundesliste."}
	state.friends.append(player.duplicate(true));state.add_activity("%s ist jetzt in deiner Himmelscrew."%player.get("display_name","Spieler"))
	return {"ok":true}

func remove_friend(public_id:String):
	await state.get_tree().process_frame
	for i in range(state.friends.size()-1,-1,-1):
		if state.friends[i].get("public_id","")==public_id:state.friends.remove_at(i);return {"ok":true}
	return {"ok":false,"error":"Freund nicht gefunden."}

func _training_players()->Array:
	return [
		{"public_id":"training-cog","username":"cog_cadet_bot","display_name":"Cog Cadet","avatar":"blasto","island_level":1,"trophies":92,"training_bot":true},
		{"public_id":"training-moss","username":"moss_mate_bot","display_name":"Moss Mate","avatar":"magneto","island_level":2,"trophies":118,"training_bot":true},
		{"public_id":"training-zap","username":"zap_scout_bot","display_name":"Zap Scout","avatar":"blink","island_level":1,"trophies":104,"training_bot":true},
	]

func _id() -> String: return "%08x%08x" % [random.randi(), random.randi()]
