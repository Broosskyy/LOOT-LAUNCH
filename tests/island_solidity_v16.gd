extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1616, "session_id": "v16-solidity", "world_key": "crystal_forge"}, "bouncer", "standard", false, 0)
	await process_frame
	for key in ["rock", "cliff_warm", "grass_light", "edge_moss"]:
		var material := world.mats[key] as StandardMaterial3D
		assert(material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,
			"Solid world material must never enter the alpha pipeline: " + key)
		assert(material.depth_draw_mode == BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY,
			"Solid world material writes an opaque depth surface: " + key)
	var island: Node = world.get_node("SkyIsland00")
	var meshes: Array[MeshInstance3D] = []
	for child in island.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
	assert(meshes.size() >= 3, "Island contains top, moss lip and cliff shell")
	var cliff: Mesh = meshes[2].mesh
	var vertices: PackedVector3Array = cliff.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert(vertices.size() >= 378,
		"The 18-segment cliff shell includes 54 closing-tip vertices")
	var lowest_y := 0.0
	for vertex in vertices:
		lowest_y = minf(lowest_y, vertex.y)
	assert(lowest_y < -8.0, "A real closed rocky tip extends below the old open ring")
	print("LOOT LAUNCH v16 island solidity passed: meshes=", meshes.size(),
		" cliff_vertices=", vertices.size(), " lowest_y=", lowest_y)
	quit(0)
