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
	for _i in range(20):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v31_spawn.png")

	world.set_move_vector(Vector2(0.0, -1.0))
	for _i in range(18):
		world._physics_process(STEP)
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	world.set_move_vector(Vector2.ZERO)
	await _save(viewport, "res://artifacts/screenshots/v31_after_forward_move.png")

	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.8).timeout
	for _i in range(10):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	world.debug_prepare_nominal_shot()
	world.debug_begin_aim(Vector2(540.0, 760.0))
	world.debug_drag_aim(Vector2(540.0, 1020.0))
	for _i in range(10):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v31_cannon_aim_down.png")

	world.debug_prepare_nominal_shot()
	world.debug_begin_aim(Vector2(540.0, 900.0))
	world.debug_drag_aim(Vector2(540.0, 620.0))
	for _i in range(10):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v31_cannon_aim_up.png")
	await _save(viewport, "res://artifacts/screenshots/v31_trajectory_preview.png")

	world.debug_prepare_nominal_shot()
	world.debug_fire_prepared_shot()
	world._physics_process(STEP)
	world._process(STEP)
	world._update_camera(STEP)
	await process_frame
	await _save(viewport, "res://artifacts/screenshots/v31_flying.png")
	var elapsed := STEP
	while world.hop_state == world.HopState.FLYING and elapsed < 9.0:
		world._physics_process(STEP)
		world._process(STEP)
		world._update_camera(STEP)
		elapsed += STEP
		await process_frame
	for _i in range(16):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v31_landed_island_1.png")

	for hop in [1, 2]:
		world.debug_unlock_cannon_for_traversal()
		world.debug_place_near_cannon()
		world.primary_action()
		await create_timer(0.8).timeout
		world.debug_prepare_nominal_shot()
		world.debug_fire_prepared_shot()
		elapsed = 0.0
		while world.hop_state == world.HopState.FLYING and elapsed < 9.0:
			world._physics_process(STEP)
			world._process(STEP)
			world._update_camera(STEP)
			elapsed += STEP
			await process_frame
		for _i in range(16):
			world._process(STEP)
			world._update_camera(STEP)
			await process_frame
		await _save(viewport, "res://artifacts/screenshots/v31_landed_island_%d.png" % (hop + 1))

	print("V31 gameplay screenshots saved")
	quit(0)


func _save(viewport: SubViewport, output_rel: String) -> void:
	await RenderingServer.frame_post_draw
	await process_frame
	var texture: ViewportTexture = viewport.get_texture()
	assert(texture != null, "Viewport texture missing for %s" % output_rel)
	var image: Image = texture.get_image()
	assert(image != null and not image.is_empty(), "Viewport image empty for %s" % output_rel)
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var err: Error = image.save_png(output_path)
	assert(err == OK, "Failed to save %s" % output_path)
