extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)
const STEP := 0.033


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.show_launch_loadout()
	await process_frame
	await main.start_launch()
	for _i in range(18):
		await process_frame
	var world = main.world
	world.bootstrap_gameplay_camera()
	await _settle(world, 26)
	await _save(viewport, "res://artifacts/screenshots/v38_iteration_a_terrain.png")
	world.orbit_yaw = 8.0
	world.target_orbit_yaw = 8.0
	await _settle(world, 16)
	await _save(viewport, "res://artifacts/screenshots/v38_iteration_b_props.png")
	world.orbit_yaw = -6.0
	world.target_orbit_yaw = -6.0
	world.orbit_pitch = 18.0
	world.target_orbit_pitch = 18.0
	await _settle(world, 16)
	await _save(viewport, "res://artifacts/screenshots/v38_iteration_c_environment.png")
	world.orbit_yaw = 16.0
	world.target_orbit_yaw = 16.0
	world.orbit_pitch = 23.0
	world.target_orbit_pitch = 23.0
	await _settle(world, 18)
	await _save(viewport, "res://artifacts/screenshots/v38_surface_detail_final.png")
	print("V38 surface detail screenshots saved")
	quit(0)


func _settle(world, frames: int) -> void:
	for _i in range(frames):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame


func _save(viewport: SubViewport, output_rel: String) -> void:
	await process_frame
	var image: Image = viewport.get_texture().get_image()
	var path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	assert(image.save_png(path) == OK)
