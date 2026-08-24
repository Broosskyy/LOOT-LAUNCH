extends RefCounted
class_name V41CliffBuilder

## V41 — Reusable procedural cliff / plateau-edge modules (deterministic, faceted).

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")

enum CliffKind {
	STRAIGHT_A,
	STRAIGHT_B,
	CORNER_A,
	CORNER_B,
	OUTCROP_A,
	OUTCROP_B,
	PILLAR_A,
	SLOPE_A,
	PLATEAU_EDGE_A,
	PLATEAU_EDGE_B,
}

static func kind_name(kind: int) -> String:
	var names := [
		"Cliff_Straight_A", "Cliff_Straight_B", "Cliff_Corner_A", "Cliff_Corner_B",
		"Cliff_Outcrop_A", "Cliff_Outcrop_B", "Cliff_Pillar_A", "Cliff_Slope_A",
		"PlateauEdge_A", "PlateauEdge_B",
	]
	return names[clampi(kind, 0, names.size() - 1)]


static func all_kinds() -> Array:
	return [
		CliffKind.STRAIGHT_A, CliffKind.STRAIGHT_B, CliffKind.CORNER_A, CliffKind.CORNER_B,
		CliffKind.OUTCROP_A, CliffKind.OUTCROP_B, CliffKind.PILLAR_A, CliffKind.SLOPE_A,
		CliffKind.PLATEAU_EDGE_A, CliffKind.PLATEAU_EDGE_B,
	]


static func build_module(kind: int, width: float, cliff_depth: float, seed: int) -> ArrayMesh:
	var rng := Common.rng(91000 + kind * 113 + seed)
	var profile: Array = _profile_for_kind(kind, width, cliff_depth, rng)
	return _extrude_profile(profile, width, seed + kind * 7)


static func build_island_shell(
	radius: float,
	segments: int,
	cliff_depth: float,
	seed: int,
	kind_cycle: Array = []
) -> Dictionary:
	var rng := Common.rng(92000 + seed)
	var top_verts: PackedVector3Array = []
	var cliff_mesh_parts: Array = []
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var wobble0: float = 1.0 + rng.randf_range(-0.08, 0.1)
		var wobble1: float = 1.0 + rng.randf_range(-0.08, 0.1)
		var r0: float = radius * wobble0
		var r1: float = radius * wobble1
		var p0 := Vector3(cos(a0) * r0, 0.0, sin(a0) * r0)
		var p1 := Vector3(cos(a1) * r1, 0.0, sin(a1) * r1)
		top_verts.append(p0)
		var kind: int = kind_cycle[i % kind_cycle.size()] if not kind_cycle.is_empty() else all_kinds()[i % all_kinds().size()]
		var seg_width: float = (p0 - p1).length()
		cliff_mesh_parts.append({"mesh": build_module(kind, seg_width, cliff_depth, seed + i * 19), "a0": a0, "a1": a1, "p0": p0, "p1": p1, "kind": kind})
	var grass_mesh := _build_grass_cap(top_verts, seed)
	var rock_mesh := _build_rock_body(top_verts, cliff_depth, seed, rng)
	return {"grass": grass_mesh, "rock": rock_mesh, "segments": cliff_mesh_parts, "top_ring": top_verts}


static func _profile_for_kind(kind: int, width: float, depth: float, rng: RandomNumberGenerator) -> Array:
	var taper_a: float = 0.72
	var taper_b: float = 0.48
	var bulge: float = 0.0
	match kind:
		CliffKind.STRAIGHT_A:
			taper_a = 0.78; taper_b = 0.52
		CliffKind.STRAIGHT_B:
			taper_a = 0.74; taper_b = 0.44
		CliffKind.CORNER_A:
			taper_a = 0.82; taper_b = 0.58; bulge = width * 0.12
		CliffKind.CORNER_B:
			taper_a = 0.70; taper_b = 0.40; bulge = width * 0.08
		CliffKind.OUTCROP_A:
			taper_a = 0.86; taper_b = 0.62; bulge = width * 0.22
		CliffKind.OUTCROP_B:
			taper_a = 0.68; taper_b = 0.36; bulge = width * 0.16
		CliffKind.PILLAR_A:
			taper_a = 0.55; taper_b = 0.22
		CliffKind.SLOPE_A:
			taper_a = 0.92; taper_b = 0.68
		CliffKind.PLATEAU_EDGE_A:
			taper_a = 0.80; taper_b = 0.50
		CliffKind.PLATEAU_EDGE_B:
			taper_a = 0.76; taper_b = 0.46
	return [
		{"y": 0.0, "scale": 1.0 + bulge / maxf(width, 0.5)},
		{"y": -depth * 0.28, "scale": taper_a + rng.randf_range(-0.03, 0.03)},
		{"y": -depth * 0.62, "scale": lerpf(taper_a, taper_b, 0.5) + rng.randf_range(-0.04, 0.04)},
		{"y": -depth, "scale": taper_b + rng.randf_range(-0.02, 0.02)},
	]


static func _extrude_profile(profile: Array, width: float, seed: int) -> ArrayMesh:
	var rng := Common.rng(93000 + seed)
	var half_w: float = width * 0.5
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for layer in profile:
		var y: float = layer["y"]
		var scale: float = layer["scale"]
		left.append(Vector3(-half_w * scale + rng.randf_range(-0.04, 0.04), y, rng.randf_range(-0.06, 0.08)))
		right.append(Vector3(half_w * scale + rng.randf_range(-0.04, 0.04), y, rng.randf_range(-0.06, 0.08)))
	for i in range(profile.size() - 1):
		var shade: float = 0.78 + float(i) * 0.04
		var col := Common.shade_color(shade)
		Common.add_flat_quad(vertices, colors, uvs, indices, left[i], right[i], right[i + 1], left[i + 1], col)
	var tip := Vector3(0.0, profile[profile.size() - 1]["y"] - 0.35, 0.12)
	var last := profile.size() - 1
	Common.add_flat_tri(vertices, colors, uvs, indices, left[last], right[last], tip, Common.shade_color(0.68))
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func _build_grass_cap(ring: PackedVector3Array, seed: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	if ring.size() < 3:
		return Common.commit_triangles(vertices, colors, uvs, indices)
	var hub := Vector3.ZERO
	hub.y = 0.02
	for i in range(ring.size()):
		var n: int = (i + 1) % ring.size()
		var a: Vector3 = ring[i] + Vector3(0.0, 0.02, 0.0)
		var b: Vector3 = ring[n] + Vector3(0.0, 0.02, 0.0)
		Common.add_flat_tri(vertices, colors, uvs, indices, a, b, hub, Common.shade_color(0.94, Color(0.72, 1.0, 0.78, 1.0)))
	# Grass lip over cliff edge
	for i in range(ring.size()):
		var n: int = (i + 1) % ring.size()
		var inner: Vector3 = ring[i].lerp(hub, 0.12)
		inner.y = 0.06
		var outer: Vector3 = ring[i]
		outer.y = 0.04
		var outer_n: Vector3 = ring[n]
		outer_n.y = 0.04
		var inner_n: Vector3 = ring[n].lerp(hub, 0.12)
		inner_n.y = 0.06
		Common.add_flat_quad(vertices, colors, uvs, indices, inner, inner_n, outer_n, outer, Common.shade_color(0.88, Color(0.65, 0.98, 0.72, 1.0)))
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func _build_rock_body(ring: PackedVector3Array, depth: float, seed: int, rng: RandomNumberGenerator) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var layers := [0.0, -depth * 0.32, -depth * 0.68, -depth]
	var scales := [1.0, 0.78, 0.52, 0.28]
	for layer_i in range(layers.size() - 1):
		for i in range(ring.size()):
			var n: int = (i + 1) % ring.size()
			var y0: float = layers[layer_i]
			var y1: float = layers[layer_i + 1]
			var s0: float = scales[layer_i] + rng.randf_range(-0.03, 0.03)
			var s1: float = scales[layer_i + 1] + rng.randf_range(-0.03, 0.03)
			var p00 := ring[i] * s0 + Vector3(0.0, y0, 0.0)
			var p10 := ring[n] * s0 + Vector3(0.0, y0, 0.0)
			var p01 := ring[i] * s1 + Vector3(0.0, y1, 0.0)
			var p11 := ring[n] * s1 + Vector3(0.0, y1, 0.0)
			var shade: float = 0.72 - float(layer_i) * 0.08 + sin(float(i + seed) * 0.7) * 0.03
			Common.add_flat_quad(vertices, colors, uvs, indices, p00, p10, p11, p01, Common.shade_color(shade))
	var tip := Vector3(0.0, -depth - 0.45, 0.0)
	var last_y: float = layers[layers.size() - 1]
	var last_s: float = scales[scales.size() - 1]
	for i in range(ring.size()):
		var n: int = (i + 1) % ring.size()
		var a := ring[i] * last_s + Vector3(0.0, last_y, 0.0)
		var b := ring[n] * last_s + Vector3(0.0, last_y, 0.0)
		Common.add_flat_tri(vertices, colors, uvs, indices, a, b, tip, Common.shade_color(0.62))
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)
