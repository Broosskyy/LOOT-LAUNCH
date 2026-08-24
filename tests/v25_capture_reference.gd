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
	assert(world != null, "Gameplay world required")
	world.bootstrap_gameplay_camera()
	for _i in range(24):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v25_iteration_a_macro.png")
	world.target_orbit_yaw += 4.0
	world.orbit_yaw = world.target_orbit_yaw
	for _i in range(12):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v25_iteration_b_mid.png")
	world.target_orbit_yaw -= 2.0
	world.orbit_yaw = world.target_orbit_yaw
	for _i in range(10):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v25_iteration_c_color.png")
	for _i in range(8):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v25_reference_match_final.png")
	print("V25 reference screenshots saved")
	quit(0)


func _save(viewport: SubViewport, output_rel: String) -> void:
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var err: Error = viewport.get_texture().get_image().save_png(output_path)
	assert(err == OK, "Failed to save %s" % output_path)
