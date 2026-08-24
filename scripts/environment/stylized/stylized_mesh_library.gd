extends RefCounted
class_name StylizedMeshLibrary

## V27 — Reusable Godot-native procedural mesh builders (GLES-safe, no textures).

const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")
const Stones = preload("res://scripts/environment/stylized/mesh/stylized_stone_builder.gd")


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


static func _face_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var n := (b - a).cross(c - a)
	return Vector3.UP if n.length_squared() < 0.000001 else n.normalized()


static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n := _face_normal(a, b, c)
	for v in [a, b, c]:
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(v)


static func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	_add_tri(st, a, b, c, color)
	_add_tri(st, a, c, d, color)


static func _shade_color(shade: float, mul: Color = Color.WHITE) -> Color:
	return Color(shade, shade * 0.97, shade * 0.93, 1.0) * mul


static func beveled_box(size: Vector3, bevel: float, seed: int, shade: float = 0.86) -> ArrayMesh:
	return Toolkit.beveled_box(size, bevel, seed, shade, 0.0, 0.0, 0.06, 1, 1)


static func tapered_cylinder(
	radius_top: float,
	radius_bottom: float,
	height: float,
	segments: int,
	seed: int,
	axis: Vector3 = Vector3.UP
) -> ArrayMesh:
	var rng := _rng(4100 + seed)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := axis.normalized()
	var right := up.cross(Vector3.FORWARD)
	if right.length_squared() < 0.001:
		right = up.cross(Vector3.RIGHT)
	right = right.normalized()
	var forward := right.cross(up).normalized()
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var dir0 := right * cos(a0) + forward * sin(a0)
		var dir1 := right * cos(a1) + forward * sin(a1)
		var j0: float = rng.randf_range(0.97, 1.03)
		var j1: float = rng.randf_range(0.97, 1.03)
		var p0b := dir0 * radius_bottom * j0
		var p1b := dir1 * radius_bottom * j1
		var p0t := dir0 * radius_top * j0
		var p1t := dir1 * radius_top * j1
		var shade: float = 0.82 + sin(float(i) * 1.4) * 0.06
		var col := _shade_color(shade)
		_add_quad(st, p0b, p1b, p1t + up * height, p0t + up * height, col)
		_add_tri(st, Vector3.ZERO, p1b, p0b, col * Color(0.72, 0.7, 0.68, 1.0))
		_add_tri(st, up * height, p0t + up * height, p1t + up * height, col * Color(1.02, 1.0, 0.98, 1.0))
	return st.commit()


static func octagonal_plinth(outer_radius: float, inner_radius: float, height: float, seed: int) -> ArrayMesh:
	return Toolkit.octagonal_plinth(outer_radius, inner_radius, height, seed, 1)


static func faceted_crystal(height: float, base_radius: float, seed: int, sides: int = 0) -> ArrayMesh:
	var rng := _rng(9100 + seed)
	var count: int = sides if sides > 0 else 5 + (seed % 3)
	var tip := Vector3(rng.randf_range(-0.06, 0.06), height, rng.randf_range(-0.05, 0.05))
	var base: Array[Vector3] = []
	for i in range(count):
		var angle: float = TAU * float(i) / float(count) + rng.randf_range(-0.12, 0.12)
		var r: float = base_radius * rng.randf_range(0.82, 1.12)
		base.append(Vector3(cos(angle) * r, rng.randf_range(-0.02, 0.04), sin(angle) * r))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(count):
		var n: int = (i + 1) % count
		var shade: float = 0.78 + float(i % 3) * 0.06
		var col := _shade_color(shade, Color(0.92, 0.88, 1.0, 1.0))
		_add_tri(st, base[i], base[n], tip, col)
		_add_tri(st, base[n], base[i], Vector3.ZERO, col * Color(0.55, 0.52, 0.62, 1.0))
	return st.commit()


static func path_stone(variant: int, seed: int) -> ArrayMesh:
	return Toolkit.path_stone(variant, seed, 1)


static func small_rock(variant: int, seed: int) -> ArrayMesh:
	match variant % 4:
		0:
			return Toolkit.irregular_stone(Stones.StoneKind.BLOCK_STONE, 0.22, 0.18, 5, 0.1, 0.1, 0.2, seed, 1)
		1:
			return Toolkit.irregular_stone(Stones.StoneKind.TALL_ROCK, 0.16, 0.32, 5, 0.12, 0.25, 0.0, seed + 1, 1)
		2:
			return faceted_crystal(0.28, 0.14, seed + 2, 4)
		_:
			return Toolkit.irregular_stone(Stones.StoneKind.RUBBLE, 0.2, 0.14, 4, 0.14, 0.0, 0.35, seed + 3, 1)


static func tapered_trunk(height: float, radius_bottom: float, radius_top: float, seed: int, segments: int = 6) -> ArrayMesh:
	return tapered_cylinder(radius_top, radius_bottom, height, segments, seed, Vector3.UP)


static func curved_lid(width: float, depth: float, height: float, seed: int) -> ArrayMesh:
	var rng := _rng(6200 + seed)
	var segments: int = 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw: float = width * 0.5
	var hd: float = depth * 0.5
	for i in range(segments):
		var t0: float = float(i) / float(segments)
		var t1: float = float(i + 1) / float(segments)
		var z0: float = lerpf(-hd, hd, t0)
		var z1: float = lerpf(-hd, hd, t1)
		var lift0: float = sin(t0 * PI) * height
		var lift1: float = sin(t1 * PI) * height
		var a := Vector3(-hw, lift0, z0) + Vector3(rng.randf_range(-0.02, 0.02), 0, 0)
		var b := Vector3(hw, lift0, z0)
		var c := Vector3(hw, lift1, z1)
		var d := Vector3(-hw, lift1, z1)
		var shade: float = 0.8 + sin(float(i) * 0.8) * 0.05
		_add_quad(st, a, b, c, d, _shade_color(shade))
		_add_quad(st, Vector3(-hw, 0, z0), Vector3(hw, 0, z0), Vector3(hw, 0, z1), Vector3(-hw, 0, z1), _shade_color(0.72))
	return st.commit()


static func ring_band(inner_r: float, outer_r: float, thickness: float, segments: int, seed: int) -> ArrayMesh:
	return Toolkit.segmented_ring(inner_r, outer_r, thickness, segments, seed, 0.04, 1)


static func count_triangles(mesh: ArrayMesh) -> int:
	var total := 0
	for i in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(i)
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		if indices is PackedInt32Array and (indices as PackedInt32Array).size() > 0:
			total += (indices as PackedInt32Array).size() / 3
		else:
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += vertices.size() / 3
	return total


static func validate_mesh(mesh: ArrayMesh) -> Dictionary:
	var report := {"errors": PackedStringArray(), "lowest_y": 99999.0, "highest_y": -99999.0, "triangles": 0}
	if mesh == null:
		report.errors.append("null mesh")
		return report
	report.triangles = count_triangles(mesh)
	for surface_index in range(mesh.get_surface_count()):
		var vertices: PackedVector3Array = mesh.surface_get_arrays(surface_index)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			if not vertex.is_finite():
				report.errors.append("non-finite vertex")
			report.lowest_y = minf(report.lowest_y, vertex.y)
			report.highest_y = maxf(report.highest_y, vertex.y)
	return report
