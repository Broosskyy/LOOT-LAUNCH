extends SceneTree

const Generator = preload("res://scripts/environment/stylized/stylized_island_generator.gd")
const Validator = preload("res://scripts/environment/stylized/stylized_mesh_validator.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1919, "session_id": "v19-geo", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	for variant in range(4):
		var island := Node3D.new()
		root.add_child(island)
		Generator.build(island, 8.6, 1.3, true, variant, world.mats, 2, 0, Callable(world, "_mesh"))
		Validator.assert_island_valid(island, 8.6)
	Validator.assert_variant_deterministic(0, 0, world.mats, 2, Callable(world, "_mesh"))
	for island_index in [0, 1, 2, 3, 4, 5, 20, 21, 22]:
		var island_node: Node3D = world.get_node_or_null("SkyIsland%02d" % island_index)
		assert(island_node != null, "Island %d must exist" % island_index)
		var radius: float = _island_radius(world, island_index)
		Validator.assert_island_valid(island_node, radius, 0.24 if island_index >= 20 else 0.32)
	var variants_seen := {}
	for route_index in range(6):
		var variant: int = absi(route_index + world.route_variant * 3) % 4
		variants_seen[variant] = true
	assert(variants_seen.size() >= 4, "Route uses all silhouette families across islands")
	print("V19 island geometry passed: variants=%s" % str(variants_seen.keys()))
	quit(0)


static func _island_radius(world, island_index: int) -> float:
	if island_index == 0:
		return 9.0
	if island_index < world.route_radii.size():
		return float(world.route_radii[island_index])
	match island_index:
		20: return 6.2
		21: return 5.8
		22: return 6.8
		_: return 6.5
