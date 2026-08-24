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
	await _settle(world, 24)
	await _save(viewport, "res://artifacts/screenshots/v40_baseline.png")
	print("V40 baseline screenshot saved")
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
