extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state = root.get_node("GameState")
	game_state.energy.current = game_state.energy.maximum
	var session: Dictionary = await game_state.start_launch()
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin(session, "bouncer", "standard", false, 0)
	await process_frame
	var press := InputEventScreenTouch.new()
	press.index = 3; press.position = Vector2(540, 700); press.pressed = true
	world._input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 3; drag.position = Vector2(780, 620)
	world._input(drag)
	var release := InputEventScreenTouch.new()
	release.index = 3; release.position = drag.position; release.pressed = false
	world._input(release)
	await create_timer(0.2).timeout
	assert(absf(world.target_orbit_yaw) > 20.0, "Swipe changes free camera yaw")
	assert(world.orbit_pitch >= 9.0 and world.orbit_pitch <= 42.0, "Orbit pitch remains bounded")
	world.orbit_yaw = 90.0; world.target_orbit_yaw = 90.0
	var start: Vector3 = world.player.global_position
	world.set_move_button(Vector2.UP, true)
	await create_timer(0.25).timeout
	world.set_move_button(Vector2.UP, false)
	assert(world.player.global_position.x < start.x, "Forward movement follows camera orientation")
	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.75).timeout
	assert(world.hop_state == world.HopState.AIMING)
	assert(world.camera.global_position.distance_to(world.cannon_pivot.global_position) > 4.5, "Cannon camera stays behind the barrel")
	assert(world.camera.fov > 63.0, "Cannon view uses a wider situational FOV")
	assert(not world.debug_begin_aim(Vector2(540, 1600)), "Bottom UI cannot start an aim gesture")
	assert(world.debug_begin_aim(Vector2(540, 720)))
	world.debug_drag_aim(Vector2(552, 730))
	world.debug_release_aim()
	assert(not world.fired and world.hop_state == world.HopState.AIMING, "Short aim drag does not fire")
	print("LOOT LAUNCH v10 camera controls passed: yaw=", snapped(world.orbit_yaw, 0.1),
		" pitch=", snapped(world.orbit_pitch, 0.1), " cannon_distance=",
		snapped(world.camera.global_position.distance_to(world.cannon_pivot.global_position), 0.1))
	quit(0)
