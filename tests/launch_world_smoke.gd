extends SceneTree

var completed := false
var submission := {}

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var World = load("res://scripts/gameplay/launch_world.gd")
	var world = World.new()
	root.add_child(world)
	world.finished.connect(func(value): submission = value; completed = true)
	world.begin({"session_id":"world-smoke", "seed":7331}, "bouncer", "standard", false, 0)
	await process_frame
	assert(not world.fired)
	assert(world.launch_state == world.LaunchState.READY)
	var outside := InputEventScreenTouch.new()
	outside.index = 0; outside.position = Vector2(900, 500); outside.pressed = true
	world._input(outside)
	assert(world.launch_state == world.LaunchState.READY)
	var cannon_screen: Vector2 = world.camera.unproject_position(world.cannon_root.global_position + Vector3(0.5, 0.05, 0))
	assert(world.debug_begin_gesture(cannon_screen))
	world.debug_drag_gesture(cannon_screen + Vector2(-12, 18))
	world.debug_release_gesture()
	assert(not world.fired)
	assert(world.launch_state == world.LaunchState.READY)
	assert(world.debug_begin_gesture(cannon_screen))
	world.debug_drag_gesture(cannon_screen + Vector2(-230, 285))
	world.debug_release_gesture()
	assert(world.fired)
	assert(world.projectile != null)
	assert(world.launch_state == world.LaunchState.SPECIAL_AVAILABLE)
	world.activate_special()
	assert(world.ability_used)
	world._record("coin", "smoke_coin", 25, world.projectile.position, 10.0)
	world._finish()
	await create_timer(0.7).timeout
	assert(completed)
	assert(submission.session_id == "world-smoke")
	assert(submission.events.size() >= 2)
	print("LOOT LAUNCH 3D launch world smoke test passed")
	quit(0)
