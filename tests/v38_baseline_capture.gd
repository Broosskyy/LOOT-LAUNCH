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
	for _i in range(26):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	var tex: ViewportTexture = viewport.get_texture()
	var path: String = ProjectSettings.globalize_path("res://artifacts/screenshots/v38_baseline.png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	assert(tex.get_image().save_png(path) == OK)
	print("V38 baseline captured")
	quit(0)
