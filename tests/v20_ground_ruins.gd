extends SceneTree

const Kit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 2020, "session_id": "v20-ground", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	for variant in range(8):
		var mesh: ArrayMesh = Kit.build_path_stone_mesh(variant, 1200 + variant)
		var report: Dictionary = Kit.validate_mesh(mesh)
		assert(report.errors.is_empty(), "Path stone %d invalid: %s" % [variant, report.errors])
		assert(report.lowest_y >= -0.02, "Path stone must sit on ground")
	for module in ["wall", "pillar", "stair", "plinth", "arch", "corner"]:
		var root := Node3D.new()
		world.add_child(root)
		match module:
			"wall":
				Kit.add_wall_segment(root, Vector3.ZERO, 0.0, world.mats, Callable(world, "_mesh"), true, 9001)
			"pillar":
				Kit.add_pillar(root, Vector3.ZERO, 0.0, world.mats, Callable(world, "_mesh"), true, 9002)
			"stair":
				Kit.add_stair_segment(root, Vector3.ZERO, 0.0, world.mats, Callable(world, "_mesh"), 4, 9003)
			"plinth":
				Kit.add_plinth(root, Vector3.ZERO, 0.0, world.mats, Callable(world, "_mesh"), 9004)
			"arch":
				Kit.add_arch_fragment(root, Vector3.ZERO, 0.0, world.mats, Callable(world, "_mesh"), 9005)
			"corner":
				Kit.add_corner_ruin(root, Vector3.ZERO, 0.0, world.mats, Callable(world, "_mesh"), 9006)
		var lowest_y := 0.0
		for child in root.get_children():
			if child is MeshInstance3D and child.mesh is ArrayMesh:
				var vertices: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					lowest_y = minf(lowest_y, child.position.y + vertex.y)
		assert(lowest_y >= -0.05, "%s module must rest on ground (%.3f)" % [module, lowest_y])
	var decor: Node = world.get_node("SourceIslandDecor")
	assert(decor != null, "Start island decor must exist")
	var array_mesh_count := 0
	for child in decor.get_children():
		if child is MeshInstance3D and child.mesh is ArrayMesh:
			array_mesh_count += 1
	assert(array_mesh_count >= 12, "Start island must contain V20 ground/ruin meshes")
	var first: ArrayMesh = Kit.build_path_stone_mesh(0, 5555)
	var second: ArrayMesh = Kit.build_path_stone_mesh(0, 5555)
	assert(first.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == second.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "Path stones must be deterministic")
	print("V20 ground ruins passed: path_variants=8 start_meshes=", array_mesh_count)
	quit(0)
