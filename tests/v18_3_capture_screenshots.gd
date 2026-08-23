extends SceneTree

const OUTPUT_INITIAL := "res://artifacts/screenshots/v18_3_initial_spawn.png"
const OUTPUT_TRANSITION := "res://artifacts/screenshots/v18_3_after_island_transition.png"
const OUTPUT_FINAL := "res://artifacts/screenshots/v18_3_final.png"
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
	main.start_launch()
	for _i in range(8):
		await process_frame
	var world = main.world
	assert(world != null, "Gameplay world must exist after start_launch")
	assert(world.camera_bootstrapped, "Camera must bootstrap before screenshots")
	for _i in range(20):
		world._update_camera(0.033)
		await process_frame
	_save_viewport(viewport, OUTPUT_INITIAL)
	world.debug_advance_to_island(1)
	for _i in range(20):
		world._update_camera(0.033)
		await process_frame
	_save_viewport(viewport, OUTPUT_TRANSITION)
	for _i in range(8):
		world._update_camera(0.033)
		await process_frame
	_save_viewport(viewport, OUTPUT_FINAL)
	print("V18.3 screenshots saved")
	quit(0)


func _save_viewport(viewport: SubViewport, output_rel: String) -> void:
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var image: Image = viewport.get_texture().get_image()
	var err: Error = image.save_png(output_path)
	assert(err == OK, "Screenshot save failed: %s" % output_path)
	print("Saved ", output_path, " size=", image.get_size())
