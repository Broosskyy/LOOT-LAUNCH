extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1818, "session_id": "v18-smoke", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	assert(world.expedition_key == "wolkengarten", "Wolkengarten expedition loads")
	assert(world.get_node_or_null("SkyIsland00") != null, "Start floating island present")
	assert(world.get_node_or_null("BouncerPlayer") != null, "Player present")
	assert(world.route_cannons.size() >= 1, "Route cannon present")
	assert(world.sun != null and world.sun is DirectionalLight3D, "Main sun present")
	var has_environment := false
	for child in world.get_children():
		if child is WorldEnvironment:
			has_environment = true
	assert(has_environment, "WorldEnvironment present")
	assert(world.portal_pair.size() >= 2, "Portal pair present")
	var island: Node = world.get_node("SkyIsland00")
	var array_mesh_count := 0
	var lowest_y := 0.0
	for child in island.get_children():
		if child is MeshInstance3D and child.mesh is ArrayMesh:
			array_mesh_count += 1
			var vertices: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				lowest_y = minf(lowest_y, vertex.y)
	assert(array_mesh_count >= 2, "Closed island geometry uses ArrayMesh surfaces")
	assert(lowest_y < -2.0, "Island underside closes below the grass top")
	var distant_islands := 0
	for i in range(11, 23):
		if world.get_node_or_null("SkyIsland%02d" % i) != null:
			distant_islands += 1
	assert(distant_islands >= 8, "Decorative depth islands present")
	assert(world.mats.has("grass_main") and world.mats.has("stone_main"), "Stylized palette active")
	print("LOOT LAUNCH v18 stylized world smoke passed: array_meshes=", array_mesh_count,
		" distant_islands=", distant_islands, " portals=", world.portal_pair.size())
	quit(0)
