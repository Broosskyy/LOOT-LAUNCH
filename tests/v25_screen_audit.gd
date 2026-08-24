extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	viewport.add_child(world)
	world.begin({"seed": 2525, "session_id": "v25-audit", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	world.bootstrap_gameplay_camera()
	world._apply_gameplay_camera_pose_immediate()
	await process_frame
	var screen: Dictionary = world.evaluate_world_composition_screen()
	for key in screen.keys():
		var m: Dictionary = screen[key]
		print("%s: x=%.1f%% y=%.1f%% in_view=%s" % [key, m["x_pct"] * 100.0, m["y_pct"] * 100.0, m["in_view"]])
	var cam: Dictionary = world.evaluate_camera_composition()
	print("player: x=%.1f%% y=%.1f%%" % [cam.player_screen_x_pct * 100.0, cam.player_screen_y_pct * 100.0])
	if world.player:
		var p: Vector2 = world.camera.unproject_position(world.player.global_position)
		print("player_actual: x=%.1f%% y=%.1f%%" % [p.x / 1080.0 * 100.0, p.y / 1920.0 * 100.0])
	if world.cannon_root:
		var c: Vector2 = world.camera.unproject_position(world.cannon_root.global_position)
		print("cannon_actual: x=%.1f%% y=%.1f%%" % [c.x / 1080.0 * 100.0, c.y / 1920.0 * 100.0])
	var chest_pos: Vector3 = Vector3(world.route_centers[0]) + Vector3(-3.4, 0.84, 0.6)
	var pad_pos: Vector3 = Vector3(world.route_centers[0]) + Vector3(-2.35, 0.84, 0.35)
	var chest_s: Vector2 = world.camera.unproject_position(chest_pos)
	var pad_s: Vector2 = world.camera.unproject_position(pad_pos)
	print("chest: x=%.1f%% y=%.1f%%" % [chest_s.x / 1080.0 * 100.0, chest_s.y / 1920.0 * 100.0])
	print("pad: x=%.1f%% y=%.1f%%" % [pad_s.x / 1080.0 * 100.0, pad_s.y / 1920.0 * 100.0])
	var portal_pos: Vector3 = Vector3(world.route_centers[1]) + Vector3(-0.5, 1.4, 5.2)
	var portal_s: Vector2 = world.camera.unproject_position(portal_pos)
	print("portal: x=%.1f%% y=%.1f%%" % [portal_s.x / 1080.0 * 100.0, portal_s.y / 1920.0 * 100.0])
	for i in range(world.flight_pickups.size()):
		var item: Dictionary = world.flight_pickups[i]
		if int(item.get("route", -1)) == 0:
			var rs: Vector2 = world.camera.unproject_position(item["origin"])
			print("ring%d: x=%.1f%% y=%.1f%%" % [i, rs.x / 1080.0 * 100.0, rs.y / 1920.0 * 100.0])
	for vista in [20, 21, 22, 33, 34, 35]:
		var node = world.get_node_or_null("SkyIsland%02d" % vista)
		if node:
			var vs: Vector2 = world.camera.unproject_position(node.global_position)
			print("vista%d: x=%.1f%% y=%.1f%%" % [vista, vs.x / 1080.0 * 100.0, vs.y / 1920.0 * 100.0])
	quit(0)
