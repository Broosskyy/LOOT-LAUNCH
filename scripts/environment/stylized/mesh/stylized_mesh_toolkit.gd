extends RefCounted
class_name StylizedMeshToolkit

## V33 — Central procedural mesh toolkit for stylized world geometry.

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")
const Profiles = preload("res://scripts/environment/stylized/mesh/stylized_profile_builder.gd")
const Curves = preload("res://scripts/environment/stylized/mesh/stylized_curve_builder.gd")
const Stones = preload("res://scripts/environment/stylized/mesh/stylized_stone_builder.gd")

enum PillarKind { FULL_PILLAR, BROKEN_PILLAR, SHORT_COLUMN }
enum RoofKind { PYRAMIDAL_CAP, HIPPED_ROOF, TAPERED_TOWER_CAP }


static func beveled_box(
	size: Vector3,
	bevel: float,
	seed: int,
	shade: float = 0.86,
	top_taper: float = 0.0,
	bottom_taper: float = 0.0,
	asymmetry: float = 0.0,
	bevel_segments: int = 1,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(3000 + seed)
	var hx: float = size.x * 0.5
	var hy: float = size.y
	var hz: float = size.z * 0.5
	var b: float = minf(bevel, minf(hx, hz) * 0.38)
	var top_scale: float = 1.0 - top_taper * 0.12
	var bot_scale: float = 1.0 - bottom_taper * 0.08
	var j := func(v: Vector3) -> Vector3:
		return v + Common.jitter_vec(rng, 0.02 + asymmetry * 0.03)
	var corner_scales := [
		1.0 + rng.randf_range(-asymmetry, asymmetry),
		1.0 + rng.randf_range(-asymmetry, asymmetry),
		1.0 + rng.randf_range(-asymmetry, asymmetry),
		1.0 + rng.randf_range(-asymmetry, asymmetry),
	]
	var bot: Array[Vector3] = [
		j.call(Vector3(-hx * bot_scale * corner_scales[0], 0.0, -hz * bot_scale * corner_scales[0])),
		j.call(Vector3(hx * bot_scale * corner_scales[1], 0.0, -hz * bot_scale * corner_scales[1])),
		j.call(Vector3(hx * bot_scale * corner_scales[2], 0.0, hz * bot_scale * corner_scales[2])),
		j.call(Vector3(-hx * bot_scale * corner_scales[3], 0.0, hz * bot_scale * corner_scales[3])),
	]
	var top_outer: Array[Vector3] = [
		j.call(Vector3(-hx * top_scale * corner_scales[0], hy, -hz * top_scale * corner_scales[0])),
		j.call(Vector3(hx * top_scale * corner_scales[1], hy, -hz * top_scale * corner_scales[1])),
		j.call(Vector3(hx * top_scale * corner_scales[2], hy, hz * top_scale * corner_scales[2])),
		j.call(Vector3(-hx * top_scale * corner_scales[3], hy, hz * top_scale * corner_scales[3])),
	]
	var top_inner: Array[Vector3] = [
		j.call(Vector3(-hx * top_scale + b, hy, -hz * top_scale + b)),
		j.call(Vector3(hx * top_scale - b, hy, -hz * top_scale + b)),
		j.call(Vector3(hx * top_scale - b, hy, hz * top_scale - b)),
		j.call(Vector3(-hx * top_scale + b, hy, hz * top_scale - b)),
	]
	var col := Common.shade_color(shade)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	Common.add_flat_quad(vertices, colors, uvs, indices, bot[0], bot[1], bot[2], bot[3], col * Color(0.78, 0.76, 0.74, 1.0))
	Common.add_flat_quad(vertices, colors, uvs, indices, top_inner[0], top_inner[1], top_inner[2], top_inner[3], col * Color(1.04, 1.04, 1.02, 1.0))
	for i in range(4):
		var n: int = (i + 1) % 4
		Common.add_flat_quad(vertices, colors, uvs, indices, bot[i], bot[n], top_outer[n], top_outer[i], col * Color(0.86, 0.84, 0.82, 1.0))
		if bevel_segments >= 1:
			Common.add_flat_tri(vertices, colors, uvs, indices, top_outer[i], top_outer[n], top_inner[n], col * Color(0.94, 0.92, 0.9, 1.0))
			Common.add_flat_tri(vertices, colors, uvs, indices, top_outer[i], top_inner[n], top_inner[i], col * Color(0.94, 0.92, 0.9, 1.0))
		if bevel_segments >= 2 and detail >= 1:
			var mid := (top_outer[i] + top_inner[i]) * 0.5 + Vector3(0.0, -b * 0.18, 0.0)
			Common.add_flat_tri(vertices, colors, uvs, indices, top_outer[i], mid, top_inner[i], col * Color(0.9, 0.88, 0.86, 1.0))
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func irregular_stone(
	kind: int,
	base_radius: float,
	height: float,
	sides: int = 6,
	irregularity: float = 0.1,
	taper: float = 0.2,
	flatten: float = 0.0,
	seed: int = 0,
	detail: int = 1
) -> ArrayMesh:
	return Stones.build_stone(kind, base_radius, height, sides, irregularity, taper, flatten, seed, detail)


static func tapered_pillar(
	kind: int,
	base_radius: float,
	top_radius: float,
	height: float,
	sides: int,
	seed: int,
	broken: bool = false,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(4100 + seed)
	var seg: int = sides if detail >= 1 else maxi(4, sides - 2)
	var actual_height: float = height
	var shaft_top: float = top_radius
	if kind == PillarKind.BROKEN_PILLAR or broken:
		actual_height = height * 0.62
		shaft_top = top_radius * 1.08
	elif kind == PillarKind.SHORT_COLUMN:
		actual_height = height * 0.72
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var cap_h: float = actual_height * 0.12
	var shaft_h: float = actual_height - cap_h * 2.0
	_build_faceted_ring_mesh(vertices, colors, uvs, indices, base_radius * 1.08, cap_h, 0.0, seg, rng, 0.74, 0)
	_build_faceted_ring_mesh(vertices, colors, uvs, indices, base_radius, shaft_h, cap_h, seg, rng, 0.84, cap_h)
	_build_faceted_ring_mesh(vertices, colors, uvs, indices, shaft_top * 0.95, cap_h, cap_h + shaft_h, seg, rng, 0.9, cap_h + shaft_h)
	if kind == PillarKind.BROKEN_PILLAR or broken:
		var chip := beveled_box(Vector3(base_radius * 0.9, cap_h * 1.4, base_radius * 0.75), 0.04, seed + 9, 0.82, 0.0, 0.0, 0.08, 1, detail)
		return _merge_meshes([Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT), chip])
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func _build_faceted_ring_mesh(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	radius: float,
	height: float,
	y0: float,
	sides: int,
	rng: RandomNumberGenerator,
	shade: float,
	uv_v: float
) -> void:
	var col := Common.shade_color(shade)
	for i in range(sides):
		var a0: float = TAU * float(i) / float(sides)
		var a1: float = TAU * float(i + 1) / float(sides)
		var r0: float = radius * rng.randf_range(0.97, 1.03)
		var r1: float = radius * rng.randf_range(0.97, 1.03)
		var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		var p10 := Vector3(cos(a1) * r1, y0, sin(a1) * r1)
		var p01 := Vector3(cos(a0) * r0, y0 + height, sin(a0) * r0)
		var p11 := Vector3(cos(a1) * r1, y0 + height, sin(a1) * r1)
		Common.add_flat_quad(vertices, colors, uvs, indices, p00, p10, p11, p01, col)


static func arch(
	width: float,
	height: float,
	thickness: float,
	segments: int,
	seed: int,
	broken: bool = false,
	asymmetry: float = 0.05,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(5400 + seed)
	var seg: int = maxi(segments, 6) if detail >= 1 else maxi(4, segments - 2)
	var half_w: float = width * 0.5
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var end_segment: int = seg if not broken else int(seg * 0.72)
	for i in range(end_segment):
		var t0: float = float(i) / float(seg)
		var t1: float = float(i + 1) / float(seg)
		var a0: float = lerpf(PI, 0.0, t0)
		var a1: float = lerpf(PI, 0.0, t1)
		var x0: float = cos(a0) * half_w + rng.randf_range(-asymmetry, asymmetry)
		var x1: float = cos(a1) * half_w + rng.randf_range(-asymmetry, asymmetry)
		var y0: float = sin(a0) * height
		var y1: float = sin(a1) * height
		var inner0 := Vector3(x0 - sign(x0) * thickness * 0.35, y0, -thickness * 0.5)
		var inner1 := Vector3(x1 - sign(x1) * thickness * 0.35, y1, -thickness * 0.5)
		var outer0 := Vector3(x0, y0, thickness * 0.5)
		var outer1 := Vector3(x1, y1, thickness * 0.5)
		var shade: float = 0.8 + sin(float(i) * 0.8) * 0.06
		var col := Common.shade_color(shade)
		Common.add_flat_quad(vertices, colors, uvs, indices, inner0, inner1, outer1, outer0, col)
		Common.add_flat_quad(vertices, colors, uvs, indices, inner0 + Vector3(0, -0.02, 0), outer0 + Vector3(0, -0.02, 0), outer1 + Vector3(0, -0.02, 0), inner1 + Vector3(0, -0.02, 0), col * Color(0.76, 0.74, 0.72, 1.0))
	# Piers
	var pier_h: float = height * 0.42
	var pier := beveled_box(Vector3(thickness * 1.1, pier_h, thickness * 1.1), 0.05, seed + 1, 0.82)
	var pier_r := beveled_box(Vector3(thickness * 1.1, pier_h, thickness * 1.1), 0.05, seed + 2, 0.8)
	return _merge_meshes([
		Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT),
		_transform_mesh(pier, Vector3(-half_w, 0.0, 0.0)),
		_transform_mesh(pier_r, Vector3(half_w, 0.0, 0.0)),
	])


static func curved_beam(
	control_points: Array,
	profile_kind: int,
	width: float,
	height: float,
	seed: int,
	samples_per_segment: int = 5,
	detail: int = 1
) -> ArrayMesh:
	var path: Array[Vector3] = Curves.sample_path(control_points, samples_per_segment if detail >= 1 else 3)
	var profile: PackedVector2Array = Profiles.sample_profile(profile_kind, width, height, 4 if detail >= 1 else 3, seed)
	return Curves.extrude_profile(profile, path, seed, 0.25, false)


static func segmented_ring(
	inner_r: float,
	outer_r: float,
	thickness: float,
	segments: int,
	seed: int,
	asymmetry: float = 0.04,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(9200 + seed)
	var seg: int = segments if detail >= 1 else maxi(6, segments - 4)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(seg):
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var w0: float = 1.0 + rng.randf_range(-asymmetry, asymmetry)
		var w1: float = 1.0 + rng.randf_range(-asymmetry, asymmetry)
		var shade: float = 0.86 if i % 2 == 0 else 0.78
		var col := Common.shade_color(shade, Color(1.02, 0.96, 0.82, 1.0))
		var ci0 := Vector3(cos(a0) * inner_r * w0, 0, sin(a0) * inner_r * w0)
		var ci1 := Vector3(cos(a1) * inner_r * w1, 0, sin(a1) * inner_r * w1)
		var co0 := Vector3(cos(a0) * outer_r * w0, 0, sin(a0) * outer_r * w0)
		var co1 := Vector3(cos(a1) * outer_r * w1, 0, sin(a1) * outer_r * w1)
		Common.add_flat_quad(vertices, colors, uvs, indices, ci0, ci1, co1, co0, col)
		Common.add_flat_quad(vertices, colors, uvs, indices, ci0 + Vector3(0, thickness, 0), co0 + Vector3(0, thickness, 0), co1 + Vector3(0, thickness, 0), ci1 + Vector3(0, thickness, 0), col * Color(0.92, 0.9, 0.86, 1.0))
		Common.add_flat_quad(vertices, colors, uvs, indices, ci0, co0, co0 + Vector3(0, thickness, 0), ci0 + Vector3(0, thickness, 0), col * Color(0.84, 0.82, 0.78, 1.0))
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func low_poly_blob(
	radius: float,
	squash: float,
	irregularity: float,
	resolution: int,
	seed: int,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(10300 + seed)
	var seg: int = resolution if detail >= 1 else maxi(4, resolution - 2)
	var rings: int = 3 if detail >= 1 else 2
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var rings_pts: Array = []
	for r in range(rings + 1):
		var ring: Array[Vector3] = []
		var lat: float = float(r) / float(rings)
		var y: float = cos(lat * PI) * radius * squash
		var ring_r: float = maxf(0.08, sin(lat * PI) * radius * (1.0 + rng.randf_range(-irregularity, irregularity) * 0.5))
		for i in range(seg):
			var angle: float = TAU * float(i) / float(seg)
			ring.append(Vector3(cos(angle) * ring_r, y, sin(angle) * ring_r))
		rings_pts.append(ring)
	for r in range(rings):
		for i in range(seg):
			var n: int = (i + 1) % seg
			var shade: float = 0.86 + float((r + i) % 3) * 0.04
			var col := Common.shade_color(shade, Color(0.95, 0.98, 1.0, 1.0))
			Common.add_flat_quad(vertices, colors, uvs, indices, rings_pts[r][i], rings_pts[r][n], rings_pts[r + 1][n], rings_pts[r + 1][i], col)
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.SMOOTH)


static func roof_cap(
	kind: int,
	width: float,
	depth: float,
	height: float,
	overhang: float,
	seed: int,
	asymmetry: float = 0.04,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(11400 + seed)
	var hw: float = width * 0.5 + overhang
	var hd: float = depth * 0.5 + overhang
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var col := Common.shade_color(0.86, Color(0.96, 0.9, 0.82, 1.0))
	match kind:
		RoofKind.HIPPED_ROOF:
			var peak := Vector3(rng.randf_range(-asymmetry, asymmetry), height, rng.randf_range(-asymmetry, asymmetry))
			var c0 := Vector3(-hw, 0, -hd)
			var c1 := Vector3(hw, 0, -hd)
			var c2 := Vector3(hw, 0, hd)
			var c3 := Vector3(-hw, 0, hd)
			Common.add_flat_tri(vertices, colors, uvs, indices, c0, c1, peak, col)
			Common.add_flat_tri(vertices, colors, uvs, indices, c1, c2, peak, col * Color(0.92, 0.88, 0.8, 1.0))
			Common.add_flat_tri(vertices, colors, uvs, indices, c2, c3, peak, col * Color(0.88, 0.84, 0.78, 1.0))
			Common.add_flat_tri(vertices, colors, uvs, indices, c3, c0, peak, col * Color(0.9, 0.86, 0.8, 1.0))
		RoofKind.TAPERED_TOWER_CAP:
			return tapered_pillar(PillarKind.SHORT_COLUMN, hw * 0.7, hw * 0.35, height, 6, seed, false, detail)
		_:
			var peak := Vector3(0, height, 0) + Common.jitter_vec(rng, asymmetry)
			Common.add_flat_tri(vertices, colors, uvs, indices, Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), peak, col)
			Common.add_flat_tri(vertices, colors, uvs, indices, Vector3(hw, 0, -hd), Vector3(hw, 0, hd), peak, col * Color(0.9, 0.86, 0.8, 1.0))
			Common.add_flat_tri(vertices, colors, uvs, indices, Vector3(hw, 0, hd), Vector3(-hw, 0, hd), peak, col * Color(0.88, 0.84, 0.78, 1.0))
			Common.add_flat_tri(vertices, colors, uvs, indices, Vector3(-hw, 0, hd), Vector3(-hw, 0, -hd), peak, col * Color(0.92, 0.88, 0.82, 1.0))
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func wall_segment(
	length: float,
	height: float,
	depth: float,
	rows: int,
	columns: int,
	stagger: bool,
	damaged: bool,
	seed: int,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(12500 + seed)
	var meshes: Array[ArrayMesh] = []
	var block_w: float = length / float(columns)
	var block_h: float = height / float(rows)
	for row in range(rows):
		for col in range(columns):
			if damaged and rng.randf() < 0.18:
				continue
			var offset_x: float = float(col) * block_w - length * 0.5 + block_w * 0.5
			if stagger and row % 2 == 1:
				offset_x += block_w * 0.5
			var offset_y: float = float(row) * block_h
			var bw: float = block_w * rng.randf_range(0.82, 0.96)
			var bh: float = block_h * rng.randf_range(0.78, 0.95)
			var bd: float = depth * rng.randf_range(0.85, 1.0)
			var mesh := beveled_box(
				Vector3(bw, bh, bd), minf(0.06, bw * 0.08), seed + row * 17 + col * 3,
				0.82 + float((row + col) % 3) * 0.04, 0.0, 0.0, 0.06, 1 if detail >= 1 else 0, detail
			)
			meshes.append(_transform_mesh(mesh, Vector3(offset_x, offset_y, rng.randf_range(-0.02, 0.02))))
	return _merge_meshes(meshes)


static func terrain_contour_ring(
	radius: float,
	segments: int,
	irregularity: float,
	squash: float,
	height: float,
	seed: int,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(13600 + seed)
	var seg: int = segments if detail >= 1 else maxi(8, segments - 4)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var inner: Array[Vector3] = []
	var outer: Array[Vector3] = []
	for i in range(seg):
		var angle: float = TAU * float(i) / float(seg)
		var wobble: float = 1.0 + rng.randf_range(-irregularity, irregularity)
		var rx: float = radius * wobble
		var rz: float = radius * squash * wobble
		inner.append(Vector3(cos(angle) * rx * 0.72, 0.0, sin(angle) * rz * 0.72))
		outer.append(Vector3(cos(angle) * rx, height, sin(angle) * rz))
	var hub := Vector3.ZERO
	for i in range(seg):
		var n: int = (i + 1) % seg
		var shade: float = 0.8 + float(i % 4) * 0.04
		var col := Common.shade_color(shade, Color(0.5, 0.82, 0.45, 1.0))
		Common.add_flat_tri(vertices, colors, uvs, indices, hub, inner[i], inner[n], col * Color(0.72, 0.9, 0.68, 1.0))
		Common.add_flat_quad(vertices, colors, uvs, indices, inner[i], inner[n], outer[n], outer[i], col)
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func path_stone(variant: int, seed: int, detail: int = 1) -> ArrayMesh:
	return irregular_stone(
		Stones.StoneKind.BLOCK_STONE,
		0.36 + float(variant % 4) * 0.05,
		0.15,
		6,
		0.09,
		0.12,
		0.18,
		variant * 19 + seed,
		detail
	)


static func octagonal_plinth(outer_radius: float, inner_radius: float, height: float, seed: int, detail: int = 1) -> ArrayMesh:
	var base := terrain_contour_ring(outer_radius, 8, 0.06, 1.0, height * 0.45, seed, detail)
	var top := beveled_box(Vector3(inner_radius * 1.7, height * 0.55, inner_radius * 1.7), 0.06, seed + 4, 0.88, 0.05, 0.0, 0.04, 1, detail)
	return _merge_meshes([base, _transform_mesh(top, Vector3(0.0, height * 0.45, 0.0))])


static func validate(mesh: ArrayMesh, max_tris: int = Common.MAX_SAFE_TRIS) -> Dictionary:
	return Common.validate_mesh(mesh, max_tris)


static func collision_hint(mesh: ArrayMesh) -> Dictionary:
	return Common.collision_box_hint(Common.mesh_bounds(mesh))


static func _transform_mesh(mesh: ArrayMesh, offset: Vector3) -> ArrayMesh:
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	for i in range(mdt.get_vertex_count()):
		mdt.set_vertex(i, mdt.get_vertex(i) + offset)
	var out := ArrayMesh.new()
	mdt.commit_to_surface(out)
	return out


static func _merge_meshes(meshes: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	var first := true
	for mesh in meshes:
		if mesh == null:
			continue
		if first:
			st.create_from(mesh, 0)
			first = false
		else:
			st.commit(mesh)
	if first:
		return ArrayMesh.new()
	return st.commit()
