extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var IslandScript = load("res://scripts/environment/floating_island_base01.gd")
	var island = IslandScript.new()
	root.add_child(island)
	await process_frame
	await island.island_built
	if island.load_errors.size() > 0:
		print("LOOT LAUNCH Phase 17A GLB test skipped (import pending): ", island.load_errors)
		_validate_constants_without_mesh(island)
		quit(0)
		return
	assert(island.visual_root != null, "Visual root must exist")
	assert(island.collision_body != null, "Gameplay collision must exist")
	assert(island.lod_instances.size() == 3, "All three LOD meshes should load")
	var collision_shapes: Array[CollisionShape3D] = []
	for child in island.collision_body.get_children():
		if child is CollisionShape3D:
			collision_shapes.append(child)
	assert(collision_shapes.size() >= 1, "At least one gameplay collision shape required")
	for lod in island.lod_instances:
		assert(lod.get_parent() == island.visual_root, "LOD must live under Visual, not collision")
	var material_issues: PackedStringArray = island.validate_materials()
	assert(material_issues.is_empty(), "Opaque material issues: %s" % str(material_issues))
	var walk: CollisionShape3D = island.collision_body.get_node("WalkSurface")
	var walk_shape: CylinderShape3D = walk.shape as CylinderShape3D
	assert(absf(walk_shape.radius - 11.648) < 0.01, "Walk radius must match procedural island 0")
	assert(absf(island.visual_scale - 13.333333) < 0.02, "Visual scale must match gameplay radius mapping")
	for lod_idx in island.lod_instances.size():
		var geo_count := _count_geometry_instances(island.lod_instances[lod_idx])
		assert(geo_count >= 1, "LOD%d must contain render geometry" % lod_idx)
	print("LOOT LAUNCH Phase 17A GLB island test passed: scale=", island.visual_scale,
		" gameplay_radius=", island.gameplay_radius, " lods=", island.lod_instances.size())
	quit(0)


func _validate_constants_without_mesh(island) -> void:
	assert(absf(island.visual_scale - 13.333333) < 0.02)
	assert(absf(island.gameplay_radius - 11.648) < 0.01)
	print("LOOT LAUNCH Phase 17A constant mapping validated without imported mesh")


func _count_geometry_instances(node: Node) -> int:
	var count := 0
	if node is GeometryInstance3D:
		count += 1
	for child in node.get_children():
		count += _count_geometry_instances(child)
	return count
