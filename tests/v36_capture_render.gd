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
	viewport.transparent_bg = false
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
	assert(world != null, "Gameplay world required")
	world.bootstrap_gameplay_camera()
	await _pose(world, 18.0, 24.0, 0, Vector3(-3.5, 0.0, 1.5))
	await _save(viewport, "res://artifacts/screenshots/v36_baseline.png")
	await _pose(world, 14.0, 22.0, 0, Vector3(-2.0, 0.0, 2.0))
	await _save(viewport, "res://artifacts/screenshots/v36_iteration_a_lighting.png")
	await _pose(world, 8.0, 20.0, 1, Vector3(0.0, 0.0, 3.5))
	await _save(viewport, "res://artifacts/screenshots/v36_iteration_b_atmosphere.png")
	await _pose(world, -12.0, 12.0, 0, Vector3(1.5, 0.0, -2.0))
	await _save(viewport, "res://artifacts/screenshots/v36_iteration_c_clouds.png")
	await _pose(world, 16.0, 23.0, 0, Vector3(-3.0, 0.0, 1.0))
	await _save(viewport, "res://artifacts/screenshots/v36_environment_rendering_final.png")
	print("V36 environment rendering screenshots saved")
	quit(0)


func _pose(world, yaw: float, pitch: float, island_index: int, offset: Vector3) -> void:
	world.orbit_yaw = yaw
	world.orbit_pitch = pitch
	world.target_orbit_yaw = yaw
	world.target_orbit_pitch = pitch
	world.player.global_position = Vector3(world.route_centers[island_index]) + offset + Vector3(0.0, 0.84, 0.0)
	for _i in range(22):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame


func _save(viewport: SubViewport, output_rel: String) -> void:
	await process_frame
	var texture: ViewportTexture = viewport.get_texture()
	assert(texture != null, "Viewport texture missing for %s" % output_rel)
	var image: Image = texture.get_image()
	assert(image != null and not image.is_empty(), "Viewport image empty for %s" % output_rel)
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	assert(image.save_png(output_path) == OK, "Failed to save %s" % output_path)
