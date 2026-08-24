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
	for _i in range(18):
		await process_frame
	var world = main.world
	assert(world != null, "Gameplay world required")
	world.bootstrap_gameplay_camera()
	for _i in range(24):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame
	_print_metrics(world, "baseline")
	await _save(viewport, "res://artifacts/screenshots/v37_baseline.png")
	print("V37 baseline captured")
	quit(0)


func _print_metrics(world, label: String) -> void:
	var comp: Dictionary = world.evaluate_camera_composition()
	var screen: Dictionary = world.evaluate_world_composition_screen()
	var rings := 0
	for item in world.flight_pickups:
		if int(item.get("route", -1)) == 0:
			var pos: Vector3 = item.get("origin", Vector3.ZERO)
			var s: Vector2 = world.camera.unproject_position(pos)
			if s.y >= 0.0 and s.y <= VIEWPORT_SIZE.y:
				rings += 1
	print(
		"V37_METRICS_%s player=(%.1f,%.1f) cannon=(%.1f,%.1f) dest=(%.1f,%.1f) portal=(%.1f,%.1f) landmark=(%.1f,%.1f) rings=%d" % [
			label,
			comp.player_screen_x_pct * 100.0, comp.player_screen_y_pct * 100.0,
			screen.cannon.x_pct * 100.0 if screen.has("cannon") else -1.0,
			screen.cannon.y_pct * 100.0 if screen.has("cannon") else -1.0,
			screen.primary_destination.x_pct * 100.0 if screen.has("primary_destination") else -1.0,
			screen.primary_destination.y_pct * 100.0 if screen.has("primary_destination") else -1.0,
			screen.portal.x_pct * 100.0 if screen.has("portal") else -1.0,
			screen.portal.y_pct * 100.0 if screen.has("portal") else -1.0,
			screen.hero_landmark.x_pct * 100.0 if screen.has("hero_landmark") else -1.0,
			screen.hero_landmark.y_pct * 100.0 if screen.has("hero_landmark") else -1.0,
			rings,
		]
	)


func _save(viewport: SubViewport, output_rel: String) -> void:
	await process_frame
	var texture: ViewportTexture = viewport.get_texture()
	var image: Image = texture.get_image()
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	assert(image.save_png(output_path) == OK, "Failed to save %s" % output_path)
