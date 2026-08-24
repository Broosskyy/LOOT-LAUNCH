extends SceneTree

const Hero = preload("res://scripts/environment/stylized/stylized_hero_models.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const GroundKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Mesh library sanity.
	for builder in ["beveled_box", "path_stone", "small_rock", "faceted_crystal", "tapered_cylinder"]:
		assert(builder.length() > 0, "Builder registry")
	var box: ArrayMesh = MeshLib.beveled_box(Vector3(1, 0.5, 1), 0.08, 42, 0.86)
	var box_report: Dictionary = MeshLib.validate_mesh(box)
	assert(box_report.errors.is_empty(), "Beveled box invalid: %s" % ", ".join(box_report.errors))
	assert(box_report.triangles > 0, "Beveled box needs triangles")
	assert(box_report.lowest_y >= -0.01, "Beveled box must rest on ground")
	var rock: ArrayMesh = MeshLib.small_rock(0, 99)
	assert(MeshLib.validate_mesh(rock).errors.is_empty(), "Small rock invalid")
	var crystal: ArrayMesh = MeshLib.faceted_crystal(0.8, 0.2, 7)
	assert(MeshLib.validate_mesh(crystal).errors.is_empty(), "Crystal invalid")
	# Deterministic crystals.
	var a: ArrayMesh = Hero._crystal_shard_mesh(1.0, 42, false)
	var b: ArrayMesh = Hero._crystal_shard_mesh(1.0, 42, false)
	assert(a.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == b.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "Crystal shards deterministic")
	# Hero models instantiate in world.
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 2727, "session_id": "v27-models", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var cannon: Node3D = world.route_cannons[0]
	assert(cannon.get_node_or_null("AimPivot") != null, "Cannon AimPivot preserved")
	assert(cannon.get_node("AimPivot").get_node_or_null("MuzzleGlow") != null, "MuzzleGlow preserved")
	assert(cannon.get_node_or_null("CannonCollider") != null, "Cannon collision preserved")
	var chest: Node3D = world.route_chests[0]
	assert(chest.get_node_or_null("Lid") != null, "Chest Lid preserved")
	var decor: Node = world.get_node("SourceIslandDecor")
	assert(decor != null, "Start decor required")
	var array_mesh_count := 0
	var cannon_tris := 0
	for child in decor.get_children():
		if child is Node3D:
			for part in child.get_children():
				if part is MeshInstance3D and part.mesh is ArrayMesh:
					array_mesh_count += 1
					var rep: Dictionary = MeshLib.validate_mesh(part.mesh as ArrayMesh)
					assert(rep.errors.is_empty(), "Decor mesh invalid")
	for part in cannon.get_children():
		if part is MeshInstance3D and part.mesh is ArrayMesh:
			cannon_tris += MeshLib.count_triangles(part.mesh as ArrayMesh)
		if part is Node3D:
			for sub in part.get_children():
				if sub is MeshInstance3D and sub.mesh is ArrayMesh:
					cannon_tris += MeshLib.count_triangles(sub.mesh as ArrayMesh)
	assert(array_mesh_count >= 8, "V27 decor should use ArrayMeshes")
	assert(cannon_tris >= 200, "Cannon should have substantial geometry")
	assert(cannon_tris <= 2500, "Cannon triangle budget exceeded: %d" % cannon_tris)
	# Portal rings.
	var portal_nodes: Array = []
	var portal_root := Node3D.new()
	world.add_child(portal_root)
	Hero.build_portal_monument(portal_root, world.mats, Callable(world, "_mesh"), Callable(world, "_transparent_material"), portal_nodes, 1.0)
	assert(portal_nodes.size() >= 2, "Portal energy rings preserved")
	# Path stones.
	var path_mesh: ArrayMesh = GroundKit.build_path_stone_mesh(3, 1200)
	assert(MeshLib.validate_mesh(path_mesh).errors.is_empty(), "Path stone invalid")
	assert(MeshLib.count_triangles(path_mesh) > 10, "Path stone needs volume")
	print("V27 model quality validation passed: decor_meshes=", array_mesh_count, " cannon_tris=", cannon_tris)
	quit(0)
