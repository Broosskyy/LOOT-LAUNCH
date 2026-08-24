extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	viewport.add_child(world)
	world.begin({"seed": 2323, "session_id": "v23-camera", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	assert(world.camera_bootstrapped, "Camera must bootstrap synchronously in begin()")
	await process_frame
	world.assert_camera_composition_valid("spawn")
	world.assert_world_composition_valid("spawn")
	world._set_state(world.HopState.LANDED)
	world._update_camera(0.016)
	world.assert_camera_composition_valid("landed_same_island")
	var basis: Dictionary = world._camera_movement_basis()
	var start_pos: Vector3 = world.player.global_position
	world.set_move_vector(Vector2(0.0, -1.0))
	for _i in range(6):
		world._physics_process(0.05)
	world.set_move_vector(Vector2.ZERO)
	var moved: Vector3 = world.player.global_position - start_pos
	moved.y = 0.0
	assert(moved.length() > 0.05, "Joystick input must move player")
	assert(basis.forward.dot(moved.normalized()) > 0.2, "Joystick forward must move along camera forward")
	world.debug_advance_to_island(1)
	await process_frame
	world._update_camera(0.016)
	world.assert_camera_composition_valid("after_island_transition")
	var spawn_state: Dictionary = world.capture_gameplay_camera_state()
	assert(spawn_state.fov > 50.0 and spawn_state.fov < 56.0, "Stylized FOV must stay in composition band")
	print("V23 camera/input regression passed")
	quit(0)
