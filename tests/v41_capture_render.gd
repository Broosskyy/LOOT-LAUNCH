extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)
const OUTPUT_PATH := "res://artifacts/screenshots/v41_benchmark_final.png"
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
	var session := {
		"ok": true,
		"session_id": "v41-capture",
		"seed": 4100,
		"world_key": "v41_benchmark",
		"lootling": "bouncer",
		"cannon": "standard",
	}
	main._begin_launch(session, false, 0)
	for _i in range(18):
		await process_frame
	var world = main.world
	world.bootstrap_gameplay_camera()
	for _i in range(26):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	var tex: ViewportTexture = viewport.get_texture()
	var path: String = ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var image: Image = tex.get_image() if tex != null else null
	if image == null:
		print("V41 screenshot skipped (headless / no render texture)")
		quit(0)
		return
	assert(image.save_png(path) == OK)
	print("V41 screenshot saved: %s" % OUTPUT_PATH)
	quit(0)
