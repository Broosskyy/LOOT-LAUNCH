extends SceneTree

const Hero = preload("res://scripts/environment/stylized/stylized_hero_models.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 2121, "session_id": "v21-hero", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var hero_keys: Array[String] = [
		"cannon_dark_metal", "brass_gold", "chest_wood", "chest_metal", "portal_stone", "portal_energy",
		"pad_stone", "pad_energy", "sign_wood", "sign_frame", "crystal_violet", "crystal_blue",
	]
	for key in hero_keys:
		assert(world.mats.has(key), "Missing V21 material key: %s" % key)
	var cannon: Node3D = world.route_cannons[0]
	assert(cannon.get_node_or_null("AimPivot") != null, "Cannon must keep AimPivot")
	var pivot: Node3D = cannon.get_node("AimPivot")
	assert(pivot.get_node_or_null("MuzzleGlow") != null, "Cannon must keep MuzzleGlow")
	assert(cannon.get_node_or_null("CannonCollider") != null, "Stylized cannon needs base collision")
	var chest: Node3D = world.route_chests[0]
	assert(chest.get_node_or_null("Lid") != null, "Gameplay chest must keep Lid for open animation")
	var decor: Node = world.get_node("SourceIslandDecor")
	assert(decor != null, "Start island decor required")
	var hero_mesh_count := 0
	var lowest_y := 0.0
	for child in decor.get_children():
		if child is Node3D:
			for part in child.get_children():
				if part is MeshInstance3D and part.mesh is ArrayMesh:
					hero_mesh_count += 1
					var vertices: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
					for vertex in vertices:
						assert(vertex.is_finite(), "Hero mesh contains non-finite vertex")
						lowest_y = minf(lowest_y, child.position.y + part.position.y + vertex.y)
	assert(hero_mesh_count >= 6, "Start island should contain V21 hero ArrayMeshes")
	assert(lowest_y >= -0.05, "Hero decor must rest on ground (%.3f)" % lowest_y)
	var shard_a: ArrayMesh = Hero._crystal_shard_mesh(1.0, 42, false)
	var shard_b: ArrayMesh = Hero._crystal_shard_mesh(1.0, 42, false)
	assert(shard_a.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == shard_b.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "Crystal shards must be deterministic")
	assert(Hero.validate_mesh(shard_a), "Crystal shard mesh must be valid")
	var portal_nodes: Array = []
	var portal_root := Node3D.new()
	world.add_child(portal_root)
	Hero.build_portal_monument(portal_root, world.mats, Callable(world, "_mesh"), Callable(world, "_transparent_material"), portal_nodes, 1.0)
	assert(portal_nodes.size() >= 2, "Portal needs animated energy rings")
	for node in portal_nodes:
		assert(node.get_meta("animate_portal", false), "Portal ring must be marked for animation")
	print("V21 hero models passed: decor_meshes=", hero_mesh_count, " portal_rings=", portal_nodes.size())
	quit(0)
