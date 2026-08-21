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
	var flight_durations: Array[float] = []
	for destination in range(1, world.ROUTE_CENTERS.size()):
		world.debug_place_near_cannon()
		world.primary_action()
		await create_timer(0.55).timeout
		assert(world.hop_state == world.HopState.AIMING, "Cannon entry reaches aiming on every route island")
		assert(world.debug_begin_aim(Vector2(540, 820)), "Aim gesture starts outside the HUD")
		await create_timer(0.72).timeout
		world.debug_release_aim()
		var elapsed := 0.0
		while world.hop_state == world.HopState.FLYING and elapsed < 9.0:
			await create_timer(0.05).timeout
			elapsed += 0.05
		assert(world.hop_state == world.HopState.LANDED, "Default charged ballistics must naturally land hop %d" % destination)
		assert(elapsed >= 0.9, "Every route flight must remain steerable rather than resolving instantly")
		flight_durations.append(elapsed)
		assert(world.current_island_index == destination, "Natural landing advances exactly one route checkpoint")
		world.debug_complete_current_objective()
		assert(world._objective_complete(destination), "Island contract must unlock chest %d" % destination)
		world.player.global_position = world.target_chest.global_position + Vector3(0.4, world.FLOOR_OFFSET, 0.4)
		world.primary_action()
		await create_timer(0.1).timeout
		assert(world.opened_chests.has(destination), "Natural route requires and opens chest %d" % destination)
	print("LOOT LAUNCH v10 all-hop ballistics passed: durations=", flight_durations,
		" events=", world.events.size(), " route_attempt=", world.route_attempt)
	quit(0)
