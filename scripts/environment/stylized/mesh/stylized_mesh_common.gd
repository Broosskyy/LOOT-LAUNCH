extends RefCounted
class_name StylizedMeshCommon

## V33 — Shared mesh-building utilities, validation, and shading modes.

enum NormalMode { FLAT, SMOOTH, HYBRID }
enum DetailTier { DISTANT, PLAYABLE, HERO }

const MAX_SAFE_EDGE := 12.0
const MAX_SAFE_TRIS := 8000


static func rng(seed: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	return r


static func face_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var n := (b - a).cross(c - a)
	return Vector3.UP if n.length_squared() < 0.000001 else n.normalized()


static func shade_color(shade: float, tint: Color = Color.WHITE) -> Color:
	return Color(shade, shade * 0.97, shade * 0.93, 1.0) * tint


static func jitter_vec(rng: RandomNumberGenerator, amount: float) -> Vector3:
	return Vector3(
		rng.randf_range(-amount, amount),
		rng.randf_range(0.0, amount * 0.6),
		rng.randf_range(-amount, amount)
	)


static func commit_triangles(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	normal_mode: int = NormalMode.FLAT
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if normal_mode == NormalMode.SMOOTH:
		for i in range(0, indices.size(), 3):
			var a: Vector3 = vertices[indices[i]]
			var b: Vector3 = vertices[indices[i + 1]]
			var c: Vector3 = vertices[indices[i + 2]]
			var n := face_normal(a, b, c)
			for j in range(3):
				var idx: int = indices[i + j]
				st.set_normal(n)
				st.set_color(colors[idx])
				if uvs.size() > idx:
					st.set_uv(uvs[idx])
				st.add_vertex(vertices[idx])
	else:
		for i in range(0, indices.size(), 3):
			var a: Vector3 = vertices[indices[i]]
			var b: Vector3 = vertices[indices[i + 1]]
			var c: Vector3 = vertices[indices[i + 2]]
			var n := face_normal(a, b, c)
			for j in range(3):
				var idx: int = indices[i + j]
				st.set_normal(n)
				st.set_color(colors[idx])
				if uvs.size() > idx:
					st.set_uv(uvs[idx])
				st.add_vertex(vertices[idx])
	return st.commit()


static func add_flat_tri(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	color: Color,
	uv_a: Vector2 = Vector2.ZERO,
	uv_b: Vector2 = Vector2.ZERO,
	uv_c: Vector2 = Vector2.ZERO
) -> void:
	var base: int = vertices.size()
	vertices.append_array([a, b, c])
	colors.append_array([color, color, color])
	uvs.append_array([uv_a, uv_b, uv_c])
	indices.append_array([base, base + 1, base + 2])


static func add_flat_quad(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	color: Color
) -> void:
	add_flat_tri(vertices, colors, uvs, indices, a, b, c, color, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z))
	add_flat_tri(vertices, colors, uvs, indices, a, c, d, color, Vector2(a.x, a.z), Vector2(c.x, c.z), Vector2(d.x, d.z))


static func count_triangles(mesh: ArrayMesh) -> int:
	var total := 0
	for i in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(i)
		var idx: Variant = arrays[Mesh.ARRAY_INDEX]
		if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
			total += (idx as PackedInt32Array).size() / 3
		else:
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += verts.size() / 3
	return total


static func mesh_bounds(mesh: ArrayMesh) -> AABB:
	var bounds := AABB()
	var started := false
	for i in range(mesh.get_surface_count()):
		var verts: PackedVector3Array = mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
		for v in verts:
			if not started:
				bounds = AABB(v, Vector3.ZERO)
				started = true
			else:
				bounds = bounds.expand(v)
	return bounds


static func validate_mesh(mesh: ArrayMesh, max_tris: int = MAX_SAFE_TRIS) -> Dictionary:
	var report := {
		"errors": PackedStringArray(),
		"triangles": 0,
		"bounds": AABB(),
		"max_edge": 0.0,
		"lowest_y": 99999.0,
		"highest_y": -99999.0,
	}
	if mesh == null:
		report.errors.append("null_mesh")
		return report
	report.triangles = count_triangles(mesh)
	if report.triangles <= 0:
		report.errors.append("no_triangles")
	if report.triangles > max_tris:
		report.errors.append("triangle_budget_exceeded")
	report.bounds = mesh_bounds(mesh)
	if not report.bounds.size.is_finite():
		report.errors.append("invalid_bounds")
	for surface_index in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		for v in verts:
			if not v.is_finite():
				report.errors.append("non_finite_vertex")
			report.lowest_y = minf(report.lowest_y, v.y)
			report.highest_y = maxf(report.highest_y, v.y)
		if indices is PackedInt32Array and (indices as PackedInt32Array).size() > 0:
			var idx: PackedInt32Array = indices
			for i in range(0, idx.size(), 3):
				var a: Vector3 = verts[idx[i]]
				var b: Vector3 = verts[idx[i + 1]]
				var c: Vector3 = verts[idx[i + 2]]
				var ab: float = a.distance_to(b)
				var bc: float = b.distance_to(c)
				var ca: float = c.distance_to(a)
				report.max_edge = maxf(report.max_edge, maxf(ab, maxf(bc, ca)))
				if ab < 0.0005 or bc < 0.0005 or ca < 0.0005:
					report.errors.append("degenerate_triangle")
				var area: float = (b - a).cross(c - a).length() * 0.5
				if area < 0.00001:
					report.errors.append("zero_area_triangle")
		elif verts.size() >= 3:
			for i in range(0, verts.size(), 3):
				var a: Vector3 = verts[i]
				var b: Vector3 = verts[i + 1]
				var c: Vector3 = verts[i + 2]
				var ab: float = a.distance_to(b)
				var bc: float = b.distance_to(c)
				var ca: float = c.distance_to(a)
				report.max_edge = maxf(report.max_edge, maxf(ab, maxf(bc, ca)))
				if ab < 0.0005 or bc < 0.0005 or ca < 0.0005:
					report.errors.append("degenerate_triangle")
				var area: float = (b - a).cross(c - a).length() * 0.5
				if area < 0.00001:
					report.errors.append("zero_area_triangle")
	if report.max_edge > MAX_SAFE_EDGE:
		report.errors.append("edge_too_long")
	return report


static func collision_box_hint(bounds: AABB, margin: float = 0.05) -> Dictionary:
	return {
		"type": "box",
		"size": bounds.size + Vector3(margin, margin, margin),
		"center": bounds.get_center(),
	}
