extends SceneTree

## V18.2 iterative screenshot capture — pass output via --screenshot=res://path.png

const DEFAULT_OUTPUT := "res://artifacts/screenshots/v18_2_iteration_a.png"
const WORLD_SCRIPT := "res://scripts/gameplay/island_hopping_world.gd"
const VIEWPORT_SIZE := Vector2i(1080, 1920)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_rel: String = DEFAULT_OUTPUT
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			output_rel = arg.substr("--screenshot=".length())
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--screenshot="):
			output_rel = arg.substr("--screenshot=".length())
	var viewport: SubViewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	viewport.transparent_bg = false
	root.add_child(viewport)
	var World = load(WORLD_SCRIPT)
	var world = World.new()
	viewport.add_child(world)
	world.begin(
		{"seed": 1818, "session_id": "v18-2-screenshot", "world_key": "wolkengarten"},
		"bouncer",
		"standard",
		false,
		0
	)
	for _i in range(6):
		await process_frame
	world.bootstrap_gameplay_camera()
	world.camera.current = true
	for _i in range(24):
		world._update_camera(0.033)
		await process_frame
	await process_frame
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var image: Image = viewport.get_texture().get_image()
	var err: Error = image.save_png(output_path)
	assert(err == OK, "Screenshot save failed with code %d at %s" % [err, output_path])
	print("V18.2 screenshot saved: ", output_path, " size=", image.get_size())
	quit(0)
