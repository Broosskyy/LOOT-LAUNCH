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
	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.7).timeout
	world.debug_begin_aim(Vector2(540, 820))
	await create_timer(0.72).timeout
	world.debug_release_aim()
	var projectile_id: int = world.projectile.get_instance_id()
	world.debug_release_aim()
	assert(world.projectile.get_instance_id() == projectile_id, "Release fires exactly once")
	var elapsed := 0.0
	while world.hop_state == world.HopState.FLYING and elapsed < 9.5:
		await create_timer(0.1).timeout
		elapsed += 0.1
	assert(world.hop_state == world.HopState.LANDED, "A correctly charged shot reaches the target island")
	assert(elapsed <= 8.5, "Flight resolves promptly")
	print("LOOT LAUNCH v10 ballistics passed: flight=", snapped(elapsed, 0.1),
		"s events=", world.events.size(), " target=", world.player.global_position)
	quit(0)
