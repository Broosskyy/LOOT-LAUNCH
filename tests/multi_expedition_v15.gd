extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node("GameState")
	game_state.energy.current = game_state.energy.maximum
	game_state.select_world("crystal_forge")
	var session: Dictionary = await game_state.start_launch()
	assert(session.get("ok", false) and session.get("world_key", "") == "crystal_forge",
		"The chosen expedition is part of the authoritative launch session")

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.show_launch_loadout()
	await process_frame
	assert(main.screen.find_child("WorldChoice_wolkengarten", true, false) != null)
	assert(main.screen.find_child("WorldChoice_crystal_forge", true, false) != null,
		"Both expeditions are directly selectable from preflight")
	main.queue_free()
	await process_frame

	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	var completed := {"done": false, "submission": {}}
	world.finished.connect(func(value): completed.done = true; completed.submission = value)
	world.begin(session, "bouncer", "standard", false, 0)
	await process_frame
	assert(world.expedition_key == "crystal_forge")
	assert(world.route_centers == world.CRYSTAL_ROUTE_CENTERS and world.route_radii == world.CRYSTAL_ROUTE_RADII)
	assert(world._island_name(3) == "PRISMENFELD" and world._objective_label(5).contains("KRONENSIEGEL"))
	assert(world.mats.grass_light.albedo_color != Color("88d46f"),
		"Kristallschmiede has a distinct material and lighting identity")
	for i in range(6):
		assert(world.get_node_or_null("BiomeLandmark%02d" % (i + 1)) != null,
			"Every crystal-forge island has a landmark")

	var durations: Array[float] = []
	for destination in range(1, world.route_centers.size()):
		world.debug_place_near_cannon()
		world.primary_action()
		await create_timer(0.55).timeout
		assert(world.debug_begin_aim(Vector2(540, 820)))
		await create_timer(0.72).timeout
		world.debug_release_aim()
		var elapsed := 0.0
		while world.hop_state == world.HopState.FLYING and elapsed < 9.0:
			await create_timer(0.05).timeout
			elapsed += 0.05
		assert(world.hop_state == world.HopState.LANDED,
			"Crystal-forge default ballistics land naturally on hop %d" % destination)
		durations.append(elapsed)
		world.debug_complete_current_objective()
		world.player.global_position = world.target_chest.global_position + Vector3(0.4, world.FLOOR_OFFSET, 0.4)
		world.primary_action()
		await create_timer(0.1).timeout
		assert(world.opened_chests.has(destination))
	while not completed.done:
		await process_frame
	var result: Dictionary = await game_state.submit_launch(completed.submission)
	assert(result.get("ok", false) and int(game_state.launch_stats.crystal_forge_runs) == 1,
		"A completed authoritative crystal run advances its mastery exactly once")
	print("LOOT LAUNCH v15 multi-expedition passed: crystal durations=", durations,
		" landmarks=6 world=", session.world_key, " mastery=", game_state.launch_stats.crystal_forge_runs)
	quit(0)
