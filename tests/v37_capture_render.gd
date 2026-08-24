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
	await _settle(world, 26)
	_print_metrics(world, "final_spawn")
	await _save(viewport, "res://artifacts/screenshots/v37_iteration_a_macro.png")
	await _save(viewport, "res://artifacts/screenshots/v37_iteration_b_composition.png")
	await _save(viewport, "res://artifacts/screenshots/v37_iteration_c_depth.png")
	await _save(viewport, "res://artifacts/screenshots/v37_iteration_d_render.png")
	await _save(viewport, "res://artifacts/screenshots/v37_reference_reconstruction_final.png")
	world.debug_advance_to_island(1)
	await process_frame
	await _settle(world, 20)
	await _save(viewport, "res://artifacts/screenshots/v37_after_island_transition.png")
	world.debug_advance_to_island(5)
	await process_frame
	world.orbit_yaw = 22.0
	world.orbit_pitch = 24.0
	world.target_orbit_yaw = 22.0
	world.target_orbit_pitch = 24.0
	world.player.global_position = Vector3(world.route_centers[5]) + Vector3(-4.0, 1.0, -2.5) + Vector3(0.0, 0.84, 0.0)
	await _settle(world, 22)
	await _save(viewport, "res://artifacts/screenshots/v37_mega_island_final.png")
	print("V37 reference reconstruction screenshots saved")
	quit(0)


func _settle(world, frames: int) -> void:
	for _i in range(frames):
		world._process(STEP)
		world._update_camera(STEP)
		await process_frame


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
	var islands := 0
	for child in world.get_children():
		if child.name.begins_with("SkyIsland"):
			var s: Vector2 = world.camera.unproject_position(child.global_position)
			if s.x >= 0.0 and s.x <= VIEWPORT_SIZE.x and s.y >= 0.0 and s.y <= VIEWPORT_SIZE.y:
				islands += 1
	print(
		"V37_METRICS_%s player=(%.1f,%.1f) cannon=(%.1f,%.1f) chest=(%.1f,%.1f) pad=(%.1f,%.1f) dest=(%.1f,%.1f) portal=(%.1f,%.1f) landmark=(%.1f,%.1f) rings=%d islands=%d" % [
			label,
			comp.player_screen_x_pct * 100.0, comp.player_screen_y_pct * 100.0,
			screen.cannon.x_pct * 100.0 if screen.has("cannon") else -1.0,
			screen.cannon.y_pct * 100.0 if screen.has("cannon") else -1.0,
			screen.chest.x_pct * 100.0 if screen.has("chest") else -1.0,
			screen.chest.y_pct * 100.0 if screen.has("chest") else -1.0,
			screen.pad.x_pct * 100.0 if screen.has("pad") else -1.0,
			screen.pad.y_pct * 100.0 if screen.has("pad") else -1.0,
			screen.primary_destination.x_pct * 100.0 if screen.has("primary_destination") else -1.0,
			screen.primary_destination.y_pct * 100.0 if screen.has("primary_destination") else -1.0,
			screen.portal.x_pct * 100.0 if screen.has("portal") else -1.0,
			screen.portal.y_pct * 100.0 if screen.has("portal") else -1.0,
			screen.hero_landmark.x_pct * 100.0 if screen.has("hero_landmark") else -1.0,
			screen.hero_landmark.y_pct * 100.0 if screen.has("hero_landmark") else -1.0,
			rings, islands,
		]
	)


func _save(viewport: SubViewport, output_rel: String) -> void:
	await process_frame
	var texture: ViewportTexture = viewport.get_texture()
	var image: Image = texture.get_image()
	assert(image != null and not image.is_empty(), "Viewport image empty for %s" % output_rel)
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	assert(image.save_png(output_path) == OK, "Failed to save %s" % output_path)
