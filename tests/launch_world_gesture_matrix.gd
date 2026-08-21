extends SceneTree

var results: Array = []

func _init() -> void: call_deferred("_run")

func _run() -> void:
	await _run_shot("weak", Vector2(-80, 92), false, 8101)
	await _run_shot("medium", Vector2(-185, 235), true, 8102)
	await _run_shot("strong", Vector2(-275, 315), true, 8103)
	assert(results.size() == 3)
	for result in results:
		assert(result.finished)
		assert(result.duration <= 15.2)
		assert(result.fire_count == 1)
		assert(result.events > 0)
	assert(int(results[1].coins) > int(results[0].coins))
	assert(int(results[2].coins) > int(results[0].coins))
	print("LOOT LAUNCH 3D gesture matrix passed: ", JSON.stringify(results))
	quit(0)

func _run_shot(label: String, drag: Vector2, use_special: bool, seed: int) -> void:
	var World = load("res://scripts/gameplay/launch_world.gd")
	var world = World.new()
	root.add_child(world)
	var run := {"done":false, "submission":{}, "fire_count":0}
	world.launched.connect(func(): run.fire_count = int(run.fire_count) + 1)
	world.finished.connect(func(value): run.submission = value; run.done = true)
	world.begin({"session_id":"matrix-" + label, "seed":seed}, "bouncer", "standard", false, 0)
	await process_frame
	var cannon_screen: Vector2 = world.camera.unproject_position(world.cannon_root.global_position + Vector3(0.5, 0.05, 0))
	assert(world.debug_begin_gesture(cannon_screen))
	world.debug_drag_gesture(cannon_screen + drag)
	world.debug_release_gesture()
	assert(world.fired)
	if use_special:
		await create_timer(0.35).timeout
		world.activate_special()
	var started := Time.get_ticks_msec()
	while not run.done and Time.get_ticks_msec() - started < 15200:
		await process_frame
	var submission: Dictionary = run.submission
	var coins := 0
	var crystals := 0
	for event in submission.get("events", []):
		if event.get("type", "") == "coin": coins += int(event.get("value", 0))
		elif event.get("type", "") == "crystal": crystals += int(event.get("value", 0))
	results.append({"label":label, "finished":run.done, "duration":world.elapsed, "fire_count":run.fire_count,
		"events":submission.get("events", []).size(), "coins":coins, "crystals":crystals,
		"angle":world.angle, "power":world.power, "special":world.ability_used})
	world.queue_free()
	await process_frame
