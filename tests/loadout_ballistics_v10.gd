extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state = root.get_node("GameState")
	game_state.settings.quality = 0
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var durations := {}
	for cannon_key in ["standard","thunder","portal"]:
		var world = World.new()
		root.add_child(world)
		world.begin({"seed":4040,"session_id":"cannon-"+cannon_key},"bouncer",cannon_key,false,0)
		await process_frame
		world.debug_place_near_cannon()
		world.primary_action()
		await create_timer(0.55).timeout
		world.debug_begin_aim(Vector2(540,820))
		await create_timer(0.72).timeout
		world.debug_release_aim()
		var elapsed:=0.0
		while world.hop_state==world.HopState.FLYING and elapsed<9.0:
			await create_timer(0.05).timeout
			elapsed+=0.05
		assert(world.hop_state==world.HopState.LANDED,"Balanced default gesture must land with "+cannon_key)
		durations[cannon_key]=elapsed
		world.queue_free()
		await process_frame
	print("LOOT LAUNCH v10 cannon balance passed: ",durations)
	quit(0)
