extends SceneTree

const Veg = preload("res://scripts/environment/stylized/stylized_vegetation_generator.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 2222, "session_id": "v22-veg", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var decor: Node = world.get_node("SourceIslandDecor")
	assert(decor != null, "Start island decor required")
	var counts: Dictionary = Veg.count_vegetation_nodes(decor)
	assert(counts["grass"] >= 10, "Start island needs grass clumps: %s" % counts)
	assert(counts["flower"] >= 8, "Start island needs flower clusters: %s" % counts)
	assert(counts["tree"] >= 2, "Start island needs stylized trees: %s" % counts)
	assert(counts["shrub"] >= 2, "Start island needs shrubs: %s" % counts)
	assert(counts["vine"] >= 1, "Start island needs vine accents: %s" % counts)
	assert(counts["total"] < 120, "Vegetation count too high for mobile: %s" % counts["total"])
	for key in ["grass_main", "leaf_dark", "leaf_light", "trunk", "flower_violet", "flower_center"]:
		assert(world.mats.has(key), "Missing V22 material: %s" % key)
	var probe := Node3D.new()
	world.add_child(probe)
	Veg.create_tree(probe, Vector3.ZERO, Veg.TreeVariant.TREE_B, 1.0, 42, world.mats, Callable(world, "_mesh"))
	Veg.create_grass_clump(probe, Vector3(1, 0, 0), Veg.GrassVariant.SHORT, 1.0, 42, world.mats, Callable(world, "_mesh"))
	Veg.create_flower_cluster(probe, Vector3(2, 0, 0), Veg.FlowerPreset.MIXED_SOFT_CLUSTER, 42, world.mats, Callable(world, "_mesh"))
	Veg.create_shrub(probe, Vector3(3, 0, 0), 1.0, 42, world.mats, Callable(world, "_mesh"))
	for child in probe.get_children():
		assert(Veg.validate_placement(child.position, child.scale.x), "Invalid vegetation placement")
	var midground: Node = world.get_node_or_null("TargetIslandDecor")
	if midground != null:
		var mid_counts: Dictionary = Veg.count_vegetation_nodes(midground)
		assert(mid_counts["tree"] >= 1, "Midground island needs tree silhouette")
	var first: ArrayMesh = Veg._get_blade_mesh(Veg.GrassVariant.MEDIUM)
	var second: ArrayMesh = Veg._get_blade_mesh(Veg.GrassVariant.MEDIUM)
	assert(first.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == second.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "Grass blade mesh must be shared")
	print("V22 vegetation passed: start=", counts, " materials=ok")
	quit(0)
