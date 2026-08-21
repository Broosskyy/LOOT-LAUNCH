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
	await create_timer(0.25).timeout
	assert(world.ROUTE_CENTERS.size() == 6, "Six playable expedition islands exist")
	for radius in world.ROUTE_RADII:
		assert(float(radius) >= 8.0, "Playable islands use the larger v9 scale")
	assert(world.get_node_or_null("JumpGate01") != null, "The first island contains a real collidable jump obstacle")
	var ground_y: float = world.player.global_position.y
	world.request_jump()
	await create_timer(0.18).timeout
	assert(world.player.global_position.y > ground_y + 0.2, "Jump button produces vertical movement")
	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.55).timeout
	world.debug_begin_aim(Vector2(540, 720))
	await create_timer(0.35).timeout
	world.debug_release_aim()
	await create_timer(0.05).timeout
	world.projectile.global_position.y = world.ROUTE_CENTERS[1].y - 19.0
	world._physics_process(0.05)
	assert(world.hop_state == world.HopState.FAILED, "Missing every island creates a real failed state")
	world.primary_action()
	assert(world.current_island_index == 0 and world.hop_state == world.HopState.ON_FOOT, "Retry restores the last checkpoint")
	var completed := {"done": false}
	world.finished.connect(func(_submission): completed.done = true)
	for destination in range(1, world.ROUTE_CENTERS.size()):
		world.debug_place_near_cannon()
		world.primary_action()
		await create_timer(0.55).timeout
		assert(world.hop_state == world.HopState.AIMING)
		world.debug_begin_aim(Vector2(540, 720))
		await create_timer(0.72).timeout
		world.debug_release_aim()
		await create_timer(0.05).timeout
		world.debug_collect_and_land()
		await process_frame
		assert(world.current_island_index == destination, "Landing advances the route checkpoint")
		world.player.global_position = world.target_chest.global_position + Vector3(0.4, world.FLOOR_OFFSET, 0.4)
		world.primary_action()
		await create_timer(0.08).timeout
		assert(world.opened_chests.has(destination), "Every reached island has a playable chest objective")
	while not completed.done:
		await process_frame
	assert(world.opened_chests.size() == 5, "All five destination islands were completed")
	print("LOOT LAUNCH v13 platform route passed: islands=", world.ROUTE_CENTERS.size(),
		" attempts=", world.route_attempt, " events=", world.events.size())
	quit(0)
