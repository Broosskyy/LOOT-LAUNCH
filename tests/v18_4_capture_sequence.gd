extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	root.add_child(viewport)
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.show_launch_loadout()
	await process_frame
	await main.start_launch()
	for _i in range(12):
		await process_frame
	var world = main.world
	assert(world != null, "Gameplay world must exist")
	assert(world.camera_bootstrapped, "Camera must be bootstrapped before first gameplay frame")
	world.assert_camera_composition_valid("frame_001")
	_save(viewport, "res://artifacts/screenshots/v18_4_frame_001.png")
	for _i in range(30):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v18_4_after_1_second.png")
	world.set_move_vector(Vector2(0.0, -1.0))
	for _i in range(12):
		world._physics_process(0.033)
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	world.set_move_vector(Vector2.ZERO)
	world.assert_camera_composition_valid("forward_move")
	_save(viewport, "res://artifacts/screenshots/v18_4_forward_move.png")
	world.target_orbit_yaw += 18.0
	world.orbit_yaw = world.target_orbit_yaw
	for _i in range(12):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v18_4_after_camera_swipe.png")
	world.debug_advance_to_island(1)
	for _i in range(20):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	world.assert_camera_composition_valid("after_island_transition")
	_save(viewport, "res://artifacts/screenshots/v18_4_after_island_transition.png")
	print("V18.4 screenshot sequence passed")
	quit(0)


func _save(viewport: SubViewport, output_rel: String) -> void:
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var err: Error = viewport.get_texture().get_image().save_png(output_path)
	assert(err == OK, "Failed to save %s" % output_path)
	print("Saved ", output_path)
