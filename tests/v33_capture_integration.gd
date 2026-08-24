extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)
const STEP := 0.033


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
	for _i in range(16):
		await process_frame
	var world = main.world
	world.debug_advance_to_island(5)
	await process_frame
	world.orbit_yaw = 18.0
	world.orbit_pitch = 24.0
	world.target_orbit_pitch = 24.0
	world.player.global_position = Vector3(world.route_centers[5]) + Vector3(-6.0, 1.2, -2.5) + Vector3(0.0, 0.84, 0.0)
	for _i in range(20):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v33_real_game_integration.png")
	print("V33 real game integration screenshot saved")
	quit(0)


func _save(viewport: SubViewport, output_rel: String) -> void:
	await RenderingServer.frame_post_draw
	await process_frame
	var image: Image = viewport.get_texture().get_image()
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	assert(image.save_png(output_path) == OK, "Failed to save %s" % output_path)
