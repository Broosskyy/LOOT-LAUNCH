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
	await _save(viewport, "res://artifacts/screenshots/v40_iteration_a_composition.png")
	world.orbit_yaw = 6.0
	world.target_orbit_yaw = 6.0
	await _settle(world, 14)
	await _save(viewport, "res://artifacts/screenshots/v40_iteration_b_art_balance.png")
	world.orbit_yaw = -4.0
	world.target_orbit_yaw = -4.0
	world.orbit_pitch = 20.0
	world.target_orbit_pitch = 20.0
	await _settle(world, 14)
	await _save(viewport, "res://artifacts/screenshots/v40_iteration_c_render_balance.png")
	world.orbit_yaw = 0.0
	world.target_orbit_yaw = 0.0
	world.orbit_pitch = 18.5
	world.target_orbit_pitch = 18.5
	world.bootstrap_gameplay_camera()
	await _settle(world, 18)
	await _save(viewport, "res://artifacts/screenshots/v40_reference_final.png")
	world.debug_advance_to_island(1)
	await _settle(world, 20)
	await _save(viewport, "res://artifacts/screenshots/v40_after_transition.png")
	world.debug_advance_to_island(5)
	world.orbit_yaw = 20.0
	world.target_orbit_yaw = 20.0
	world.orbit_pitch = 22.0
	world.target_orbit_pitch = 22.0
	world.player.global_position = Vector3(world.route_centers[5]) + Vector3(-3.5, 1.0, -2.0) + Vector3(0.0, 0.84, 0.0)
	await _settle(world, 22)
	await _save(viewport, "res://artifacts/screenshots/v40_mega_island.png")
	world.orbit_yaw = 28.0
	world.target_orbit_yaw = 28.0
	world.orbit_pitch = 18.0
	world.target_orbit_pitch = 18.0
	await _settle(world, 16)
	await _save(viewport, "res://artifacts/screenshots/v40_waterfall.png")
	print("V40 visual master screenshots saved")
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
