extends SceneTree

const Composition = preload("res://scripts/environment/stylized/stylized_world_composition.gd")
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
	world.begin({"seed": 2323, "session_id": "v23-composition", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	assert(world.route_centers.size() == Composition.ROUTE_ISLANDS.size(), "Route islands must come from composition SSOT")
	assert(Composition.vista_entries().size() >= 5, "Vista layer must contain multiple islands")
	var arc: Array[Vector3] = Composition.ring_arc_for_hop(0, Vector3(world.route_centers[0]), Vector3(world.route_centers[1]))
	assert(arc.size() == 5, "Start route ring arc must contain five points")
	for point in arc:
		assert(point.is_finite(), "Ring arc points must be finite")
	world.bootstrap_gameplay_camera()
	await process_frame
	world._update_camera(0.016)
	world.assert_world_composition_valid("composition_spawn")
	var screen: Dictionary = world.evaluate_world_composition_screen()
	if screen.has("primary_destination") and screen["primary_destination"]["in_view"] and screen.has("player_spawn"):
		assert(screen["primary_destination"]["y_pct"] < screen["player_spawn"]["y_pct"],
			"Primary destination should appear above player in portrait frame")
	var vista_count := 0
	for child in world.get_children():
		if child.name.begins_with("SkyIsland"):
			var suffix: String = child.name.substr(9)
			if suffix.is_valid_int() and int(suffix) >= 20:
				vista_count += 1
	assert(vista_count >= 5, "Vista islands must be spawned")
	print("V23 composition validation passed: vista=", vista_count)
	quit(0)
