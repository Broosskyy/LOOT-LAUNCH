extends SceneTree

var state

func _init():
	call_deferred("_run")

func _run():
	state=load("res://scripts/core/game_state.gd").new();root.add_child(state);await process_frame
	state.wallet={"coins":1500,"crystals":25,"trophies":100};state.energy={"current":10,"maximum":10,"next_regeneration_unix":int(Time.get_unix_time_from_system())+600};state.buildings=state.START_BUILDINGS.duplicate(true);state.processed_launches={};state.processed_upgrades={};state.launch_stats={"launches":0,"objects_hit":0,"upgrades":0,"objectives":0,"chests":0,"specials":0,"best_combo":0};state.mission_claims={};state.friends=[];state.activity=[]
	await state.login_guest();assert(state.authenticated)
	var profile=await state.reserve_profile("smoke_player","Smoke Player","bouncer");assert(profile.ok)
	var cancelled=await state.start_launch();assert(cancelled.ok);assert(state.energy.current==9);var cancellation=await state.cancel_launch(cancelled.session_id);assert(cancellation.ok);assert(state.energy.current==10)
	var launch=await state.start_launch();assert(launch.ok);assert(state.energy.current==9)
	var events:=[]
	for i in 5:events.append({"sequence":i,"type":"coin","speed":8.0,"value":25})
	var submission={"session_id":launch.session_id,"events":events,"angle":48.0,"power":0.8}
	var first=await state.submit_launch(submission);var replay=await state.submit_launch(submission);assert(first.coins==125);assert(replay.already_processed);assert(state.wallet.coins==1625);assert(state.launch_stats.objects_hit==5)
	var upgrade=await state.upgrade_building("island_core","smoke-upgrade");assert(upgrade.ok);assert(state.buildings.island_core==2);assert(state.wallet.coins==1475)
	state.launch_stats.objects_hit=12;state.launch_stats.objectives=3;state.launch_stats.chests=3
	var mission=await state.claim_missions();assert(mission.ok);assert(mission.claimed==5);assert(mission.crystals==2);var mission_replay=await state.claim_missions();assert(not mission_replay.ok)
	state.mine_last_claim_unix=int(Time.get_unix_time_from_system())-1200;var mine=await state.claim_mine();assert(mine.ok);assert(mine.crystals==2)
	var search=await state.search_players("moss");assert(search.ok);assert(search.items.size()==1);var friend=await state.add_friend(search.items[0]);assert(friend.ok);assert(state.friends.size()==1);var duplicate_friend=await state.add_friend(search.items[0]);assert(not duplicate_friend.ok)
	var target_result=await state.find_target();var attack_result=await state.start_attack(target_result.target);var final={}
	for number in range(1,4):final=await state.submit_attack_shot({"number":number,"impact_speed":10.0,"idempotency_key":attack_result.attack.id+":"+str(number)})
	assert(final.complete);assert(final.hits==3)
	var boss_before:int=state.world_boss_state.current;var boss=await state.contribute_world_boss(500);assert(boss.ok);assert(state.world_boss_state.current==boss_before-500)
	var removed=await state.remove_friend(search.items[0].public_id);assert(removed.ok);assert(state.friends.is_empty())
	print("LOOT LAUNCH local backend smoke test passed")
	quit(0)
