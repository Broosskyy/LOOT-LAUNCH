extends SceneTree

const Validator = preload("res://scripts/environment/stylized/stylized_mesh_validator.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1818, "session_id": "v18-3-mesh", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	for island_index in [0, 1, 20, 21, 22]:
		var island: Node3D = world.get_node_or_null("SkyIsland%02d" % island_index)
		assert(island != null, "Island %d must exist" % island_index)
		var radius: float = 9.0 if island_index == 0 else float(world.route_radii[1]) if island_index == 1 else [6.2, 5.8, 6.8][island_index - 20]
		Validator.assert_island_valid(island, radius, 0.24 if island_index >= 20 else 0.32)
	print("V18.3 island mesh validation passed")
	quit(0)
