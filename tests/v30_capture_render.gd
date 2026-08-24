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
	for _i in range(14):
		await process_frame
	var world = main.world
	assert(world != null, "Gameplay world required")
	world.bootstrap_gameplay_camera()
	for _i in range(28):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v30_iteration_a_macro.png")
	for _i in range(10):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v30_iteration_b_composition.png")
	for _i in range(8):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v30_iteration_c_render.png")
	for _i in range(6):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v30_reference_match_final.png")
	world.debug_advance_to_island(1)
	await process_frame
	for _i in range(20):
		world._process(0.033)
		world._physics_process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, "res://artifacts/screenshots/v30_after_island_transition.png")
	print("V30 polish screenshots saved")
	quit(0)


func _save(viewport: SubViewport, output_rel: String) -> void:
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var err: Error = viewport.get_texture().get_image().save_png(output_path)
	assert(err == OK, "Failed to save %s" % output_path)
