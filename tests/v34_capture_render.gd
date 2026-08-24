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
	world.orbit_yaw = 12.0
	world.orbit_pitch = 26.0
	world.target_orbit_yaw = 12.0
	world.target_orbit_pitch = 26.0
	world.player.global_position = Vector3(world.route_centers[0]) + Vector3(-1.0, 0.0, 2.5) + Vector3(0.0, 0.84, 0.0)
	for _i in range(20):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v34_start_island_surface.png")
	world.debug_advance_to_island(5)
	await process_frame
	for _i in range(24):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	world.orbit_yaw = 35.0
	world.orbit_pitch = 28.0
	world.target_orbit_yaw = 35.0
	world.target_orbit_pitch = 28.0
	world.player.global_position = Vector3(world.route_centers[5]) + Vector3(2.0, 0.0, 0.0) + Vector3(0.0, 0.84, 0.0)
	for _i in range(18):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v34_mega_island_surface.png")
	world.orbit_yaw = 12.0
	world.orbit_pitch = 22.0
	world.target_orbit_yaw = 12.0
	world.target_orbit_pitch = 22.0
	world.player.global_position = Vector3(world.route_centers[5]) + Vector3(-4.5, 1.45, 3.5) + Vector3(0.0, 0.84, 0.0)
	for _i in range(14):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v34_riverbank.png")
	world.orbit_yaw = -48.0
	world.orbit_pitch = 18.0
	world.target_orbit_yaw = -48.0
	world.target_orbit_pitch = 18.0
	world.player.global_position = Vector3(world.route_centers[5]) + Vector3(-7.5, 1.35, -5.8) + Vector3(0.0, 0.84, 0.0)
	for _i in range(14):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v34_waterfall_source.png")
	world.orbit_yaw = 8.0
	world.orbit_pitch = 32.0
	world.target_orbit_yaw = 8.0
	world.target_orbit_pitch = 32.0
	world.player.global_position = Vector3(world.route_centers[5]) + Vector3(0.5, 0.0, -0.5) + Vector3(0.0, 0.84, 0.0)
	for _i in range(14):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v34_terrain_surface_final.png")
	print("V34 terrain surface screenshots saved")
	quit(0)


func _save(viewport: SubViewport, output_rel: String) -> void:
	await process_frame
	var texture: ViewportTexture = viewport.get_texture()
	assert(texture != null, "Viewport texture missing for %s" % output_rel)
	var image: Image = texture.get_image()
	assert(image != null and not image.is_empty(), "Viewport image empty for %s" % output_rel)
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	assert(image.save_png(output_path) == OK, "Failed to save %s" % output_path)
