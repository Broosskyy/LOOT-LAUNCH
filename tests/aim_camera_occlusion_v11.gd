extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node("GameState")
	game_state.settings.quality = 1
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1111, "session_id": "aim-camera-v11"}, "bouncer", "standard", false, 0)
	await process_frame

	var source_gate: Node3D = world.get_node("JumpGate01")
	assert(absf(source_gate.global_position.x - world.ROUTE_CENTERS[0].x) >= 4.0,
		"Jump obstacle must stay out of the centre camera corridor")
	var first_arch: Node3D = world.get_node("SideArch02")
	assert(absf(first_arch.global_position.x - world.ROUTE_CENTERS[1].x) >= 4.5,
		"Target arch must frame the route from the side")

	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.9).timeout
	assert(world.hop_state == world.HopState.AIMING)
	assert(world.camera.global_position.distance_to(world.cannon_pivot.global_position) >= 6.0,
		"Over-cannon camera needs enough distance for situational awareness")
	var camera_distance: float = world.camera.global_position.distance_to(world.cannon_pivot.global_position)
	assert(world.camera.fov >= 69.0, "Aim view uses a readable portrait FOV")
	assert(world.trajectory_root.get_child_count() == 8, "Preview reveals only the first flight phase")
	assert(world.predicted_landing_valid, "Balanced default aim should show a valid green landing marker")
	var target: Vector3 = world.ROUTE_CENTERS[1]
	var predicted_distance := Vector2(world.predicted_landing_position.x - target.x,
		world.predicted_landing_position.z - target.z).length()
	assert(predicted_distance <= world.ROUTE_RADII[1] * 0.82,
		"Landing marker must be computed on the actual target island")

	var initial_yaw: float = world.aim_yaw
	var initial_pitch: float = world.aim_pitch
	assert(world.debug_begin_aim(Vector2(540, 820)))
	world.debug_drag_aim(Vector2(680, 670))
	assert(world.aim_yaw > initial_yaw, "Swipe right turns the cannon right")
	assert(world.aim_pitch > initial_pitch, "Swipe up raises the cannon")
	world.active_pointer = -999

	var focus: Vector3 = world.cannon_pivot.global_position + Vector3.UP * 1.2
	var desired: Vector3 = focus + Vector3(0.0, 2.0, 7.0)
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 3.0, 1.0)
	collision.shape = box
	blocker.add_child(collision)
	world.add_child(blocker)
	blocker.global_position = focus.lerp(desired, 0.5)
	await physics_frame
	var resolved: Vector3 = world._resolve_camera_occlusion(focus, desired)
	assert(resolved.distance_to(focus) < desired.distance_to(focus) - 0.4,
		"Camera collision solver must pull the view in front of an obstruction")

	for island_index in range(world.ROUTE_CENTERS.size() - 1):
		world.current_island_index = island_index
		world._activate_route_cannon(island_index)
		world._set_state(world.HopState.AIMING)
		world._update_trajectory()
		assert(world.predicted_landing_valid,
			"Default cannon calibration must show a valid marker for hop %d" % (island_index + 1))

	print("LOOT LAUNCH v11 aim/camera passed: fov=", snapped(world.camera.fov, 0.1),
		" camera_distance=", snapped(camera_distance, 0.1),
		" predicted_distance=", snapped(predicted_distance, 0.1))
	quit(0)
