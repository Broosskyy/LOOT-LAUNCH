extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_rel: String = "res://artifacts/screenshots/v19_islands_iteration_a.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--v19-shot="):
			output_rel = "res://artifacts/screenshots/%s.png" % arg.substr(11)
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
	_orient_camera_for_island_review(world)
	for _i in range(24):
		world._process(0.033)
		world._update_camera(0.033)
		await process_frame
	_save(viewport, output_rel)
	print("V19 island screenshot saved: ", output_rel)
	quit(0)


func _orient_camera_for_island_review(world) -> void:
	var player_pos: Vector3 = world.player.global_position
	var focus: Vector3 = player_pos + Vector3(-4.0, 0.5, -38.0)
	world.camera.global_position = player_pos + Vector3(7.0, 13.5, 15.0)
	world.camera.look_at(focus, Vector3.UP)
	world.camera.fov = 56.0
	world.camera.current = true


func _save(viewport: SubViewport, output_rel: String) -> void:
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var err: Error = viewport.get_texture().get_image().save_png(output_path)
	assert(err == OK, "Failed to save %s" % output_path)
