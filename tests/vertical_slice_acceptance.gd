extends SceneTree

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var game_state = root.get_node("GameState")
	game_state.energy.current = game_state.energy.maximum
	var server_session: Dictionary = await game_state.start_launch()
	assert(server_session.get("ok", false))
	var World = load("res://scripts/gameplay/launch_world.gd")
	var world = World.new()
	root.add_child(world)
	var run := {"done":false, "submission":{}}
	world.finished.connect(func(value): run.submission = value; run.done = true)
	world.begin(server_session, "bouncer", "standard", false, 0)
	await process_frame
	var cannon_screen: Vector2 = world.camera.unproject_position(world.cannon_root.global_position + Vector3(0.5, 0.05, 0))
	assert(world.debug_begin_gesture(cannon_screen))
	world.debug_drag_gesture(cannon_screen + Vector2(-185, 235))
	world.debug_release_gesture()
	await create_timer(0.5).timeout
	world.activate_special()
	while not run.done: await process_frame
	var submission: Dictionary = run.submission
	var visible_coins := 0
	var visible_crystals := 0
	for event in submission.events:
		match event.get("type", ""):
			"coin": visible_coins += mini(25, int(event.get("value", 0)))
			"crystal": visible_crystals += mini(1, int(event.get("value", 0)))
			"treasure": visible_coins += 100
	var wallet_before := int(game_state.wallet.coins)
	var result: Dictionary = await game_state.submit_launch(submission)
	assert(result.get("ok", false))
	assert(int(result.coins) == mini(500, visible_coins))
	assert(int(result.crystals) == mini(5, visible_crystals))
	assert(int(game_state.wallet.coins) == wallet_before + int(result.coins))
	var wallet_after := int(game_state.wallet.coins)
	var replay: Dictionary = await game_state.submit_launch(submission)
	assert(replay.get("already_processed", false))
	assert(int(game_state.wallet.coins) == wallet_after)
	print("LOOT LAUNCH vertical slice acceptance passed: coins=", result.coins,
		" crystals=", result.crystals, " combo=", result.combo)
	quit(0)
