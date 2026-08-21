extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state = root.get_node("GameState")
	game_state.energy.current = game_state.energy.maximum
	var session: Dictionary = await game_state.start_launch()
	assert(session.get("ok", false), "Launch session must start")
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	var result_state := {"done": false, "submission": {}}
	world.finished.connect(func(value): result_state.submission = value; result_state.done = true)
	world.begin(session, "bouncer", "standard", false, 0)
	await process_frame
	assert(world.hop_state == world.HopState.ON_FOOT, "Route starts on foot")
	var start_position: Vector3 = world.player.global_position
	world.set_move_button(Vector2.RIGHT, true)
	await create_timer(0.22).timeout
	world.set_move_button(Vector2.RIGHT, false)
	assert(world.player.global_position.x > start_position.x, "On-screen movement changes player position")
	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.7).timeout
	assert(world.hop_state == world.HopState.AIMING, "Action enters cannon aiming mode")
	assert(world.debug_begin_aim(Vector2(540, 720)), "Aim starts outside UI")
	world.debug_drag_aim(Vector2(610, 965))
	assert(world.aim_power > 0.3, "Drag charges cannon")
	world.debug_release_aim()
	await create_timer(0.12).timeout
	assert(world.hop_state == world.HopState.FLYING, "Valid release fires once")
	assert(world.projectile != null, "Lootling leaves cannon as projectile")
	world.activate_special()
	assert(world.ability_used, "Special impulse works during flight")
	world.debug_collect_and_land()
	await process_frame
	assert(world.hop_state == world.HopState.LANDED, "Lootling lands on target island")
	assert(world.events.size() >= 5, "Visible route pickups create reward events")
	world.debug_open_chest_and_finish()
	while not result_state.done:
		await process_frame
	var submission: Dictionary = result_state.submission
	assert(submission.get("events", []).size() >= 6, "Chest is included in final event data")
	var wallet_before := int(game_state.wallet.coins)
	var result: Dictionary = await game_state.submit_launch(submission)
	assert(result.get("ok", false), "Server adapter accepts valid route")
	assert(int(result.get("coins", 0)) > 0, "Successful route never reports zero coins")
	assert(int(game_state.wallet.coins) == wallet_before + int(result.coins), "Wallet matches accepted reward")
	var wallet_after := int(game_state.wallet.coins)
	var replay: Dictionary = await game_state.submit_launch(submission)
	assert(replay.get("already_processed", false), "Duplicate submission is idempotent")
	assert(int(game_state.wallet.coins) == wallet_after, "Duplicate cannot credit wallet twice")
	print("LOOT LAUNCH v10 island hopping passed: events=", submission.events.size(),
		" coins=", result.coins, " crystals=", result.crystals)
	quit(0)
