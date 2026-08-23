extends RefCounted
class_name StylizedMeshValidator

## Validates procedural island meshes for degenerate triangles and outliers.


static func validate_island_meshes(island_root: Node3D, expected_radius: float) -> Dictionary:
	var report := {
		"mesh_count": 0,
		"vertex_count": 0,
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


static func assert_island_valid(island_root: Node3D, expected_radius: float) -> void:
	var report: Dictionary = validate_island_meshes(island_root, expected_radius)
	assert(report.errors.is_empty(),
		"Island mesh validation failed: %s (meshes=%d max_edge=%.2f radius=%.2f)" % [
			", ".join(report.errors), report.mesh_count, report.max_edge, expected_radius
		])
	assert(report.mesh_count >= 2, "Island must contain grass and cliff ArrayMesh surfaces")
	assert(report.lowest_y < -1.5, "Island underside must close below the grass top")


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
	for edge in [a.distance_to(b), b.distance_to(c), c.distance_to(a)]:
		report.max_edge = maxf(report.max_edge, edge)
		if edge > max_allowed_edge:
			report.errors.append("edge %.2f exceeds limit %.2f" % [edge, max_allowed_edge])
