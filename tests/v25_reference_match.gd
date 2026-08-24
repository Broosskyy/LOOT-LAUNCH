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
	world.begin({"seed": 2525, "session_id": "v25-reference", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	world.bootstrap_gameplay_camera()
	world._apply_gameplay_camera_pose_immediate()
	await process_frame
	world.assert_camera_composition_valid("v25_spawn")
	world.assert_world_composition_valid("v25_spawn")
	var visible_islands := 0
	for child in world.get_children():
		if child.name.begins_with("SkyIsland"):
			var suffix: String = child.name.substr(9)
			if suffix.is_valid_int():
				var screen: Vector2 = world.camera.unproject_position(child.global_position)
				if screen.x >= 0 and screen.x <= VIEWPORT_SIZE.x and screen.y >= 0 and screen.y <= VIEWPORT_SIZE.y:
					visible_islands += 1
	assert(visible_islands >= 3, "At least 3 island silhouettes must be visible")
	assert(world.flight_pickups.size() >= 5, "Start route rings must exist")
	var ring_visible := false
	for item in world.flight_pickups:
		if int(item.get("route", -1)) == 0:
			var screen: Vector2 = world.camera.unproject_position(item["origin"])
			if screen.y >= 0 and screen.y <= VIEWPORT_SIZE.y:
				ring_visible = true
				break
	assert(ring_visible, "At least one start-route ring must be visible")
	print("V25 reference match validation passed: visible_islands=", visible_islands)
	quit(0)
