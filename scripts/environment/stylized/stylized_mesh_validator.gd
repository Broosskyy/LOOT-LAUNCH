extends RefCounted
class_name StylizedMeshValidator

## Validates procedural island meshes for degenerate triangles and outliers.


static func validate_island_meshes(island_root: Node3D, expected_radius: float) -> Dictionary:
	var report := {
		"mesh_count": 0,
		"vertex_count": 0,
		"triangle_count": 0,
		"max_edge": 0.0,
		"lowest_y": 99999.0,
		"highest_y": -99999.0,
		"errors": PackedStringArray(),
	}
	var max_allowed_edge: float = expected_radius * 2.6
	for child in island_root.get_children():
		if child is MeshInstance3D and child.mesh is ArrayMesh:
			report.mesh_count += 1
			_validate_array_mesh(child.mesh as ArrayMesh, max_allowed_edge, report)
	return report


static func assert_island_valid(island_root: Node3D, expected_radius: float, min_depth_ratio := 0.28) -> void:
	var report: Dictionary = validate_island_meshes(island_root, expected_radius)
	assert(report.errors.is_empty(),
		"Island mesh validation failed: %s (meshes=%d max_edge=%.2f radius=%.2f)" % [
			", ".join(report.errors), report.mesh_count, report.max_edge, expected_radius
		])
	assert(report.mesh_count >= 2, "Island must contain grass and rock ArrayMesh surfaces")
	var depth: float = report.highest_y - report.lowest_y
	assert(report.lowest_y < -expected_radius * min_depth_ratio,
		"Island underside must extend below top (lowest=%.2f radius=%.2f)" % [report.lowest_y, expected_radius])


static func assert_variant_deterministic(
	island_index: int,
	route_variant: int,
	mats: Dictionary,
	quality_level: int,
	mesh_fn: Callable
) -> void:
	var first: Dictionary = _build_bounds_snapshot(island_index, route_variant, mats, quality_level, mesh_fn)
	var second: Dictionary = _build_bounds_snapshot(island_index, route_variant, mats, quality_level, mesh_fn)
	assert(first == second, "Island %d geometry must be seed-deterministic" % island_index)


static func _build_bounds_snapshot(
	island_index: int,
	route_variant: int,
	mats: Dictionary,
	quality_level: int,
	mesh_fn: Callable
) -> Dictionary:
	var root := Node3D.new()
	StylizedIslandGenerator.build(
		root, 8.0, 1.3, island_index < 6, island_index, mats, quality_level, route_variant, mesh_fn
	)
	return StylizedIslandGenerator.bounds_for_island(root)


static func _validate_array_mesh(mesh: ArrayMesh, max_allowed_edge: float, report: Dictionary) -> void:
	for surface_index in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices_variant = arrays[Mesh.ARRAY_INDEX]
		var indices: PackedInt32Array = PackedInt32Array()
		if indices_variant is PackedInt32Array:
			indices = indices_variant
		if vertices.is_empty():
			report.errors.append("empty vertex buffer on surface %d" % surface_index)
			continue
		for vertex in vertices:
			if not vertex.is_finite():
				report.errors.append("non-finite vertex on surface %d" % surface_index)
				continue
			report.vertex_count += 1
			report.lowest_y = minf(report.lowest_y, vertex.y)
			report.highest_y = maxf(report.highest_y, vertex.y)
		if indices.is_empty():
			for i in range(0, vertices.size(), 3):
				_check_triangle(vertices[i], vertices[i + 1], vertices[i + 2], max_allowed_edge, report)
		else:
			for i in range(0, indices.size(), 3):
				_check_triangle(
					vertices[indices[i]],
					vertices[indices[i + 1]],
					vertices[indices[i + 2]],
					max_allowed_edge,
					report
				)


static func _check_triangle(
	a: Vector3,
	b: Vector3,
	c: Vector3,
	max_allowed_edge: float,
	report: Dictionary
) -> void:
	report.triangle_count += 1
	var ab := a.distance_to(b)
	var bc := b.distance_to(c)
	var ca := c.distance_to(a)
	for edge in [ab, bc, ca]:
		report.max_edge = maxf(report.max_edge, edge)
		if edge > max_allowed_edge:
			report.errors.append("edge %.2f exceeds limit %.2f" % [edge, max_allowed_edge])
	var area := (b - a).cross(c - a).length() * 0.5
	if area < 0.0005:
		report.errors.append("degenerate triangle area %.6f" % area)
