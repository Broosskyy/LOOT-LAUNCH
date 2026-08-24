extends RefCounted
class_name StylizedStoneBuilder

## V33 — Irregular low-poly stone and rock chunk generation.

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")

enum StoneKind { FLAT_STONE, BLOCK_STONE, TALL_ROCK, RUBBLE, CLIFF_CHUNK }


static func build_stone(
	kind: int,
	base_radius: float,
	height: float,
	sides: int,
	irregularity: float,
	taper: float,
	flatten: float,
	seed: int,
	detail: int = 1
) -> ArrayMesh:
	var rng := Common.rng(7100 + seed + kind * 17)
	var count: int = maxi(sides, 4)
	if detail == 0:
		count = maxi(4, count - 2)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var top_y: float = height
	var bot_y: float = 0.0
	match kind:
		StoneKind.FLAT_STONE:
			top_y = height * 0.35
			flatten = maxf(flatten, 0.55)
		StoneKind.TALL_ROCK:
			top_y = height * 1.15
			taper = maxf(taper, 0.35)
		StoneKind.RUBBLE:
			top_y = height * 0.55
			base_radius *= 0.82
		StoneKind.CLIFF_CHUNK:
			top_y = height * 0.75
			flatten = 0.25
	var top_ring: Array[Vector3] = []
	var bot_ring: Array[Vector3] = []
	for i in range(count):
		var angle: float = TAU * float(i) / float(count) + rng.randf_range(-0.08, 0.08) * irregularity
		var r_top: float = base_radius * lerpf(1.0, 0.55, taper) * (1.0 + rng.randf_range(-irregularity, irregularity))
		var r_bot: float = base_radius * (1.0 + rng.randf_range(-irregularity * 0.7, irregularity * 0.7))
		r_top *= lerpf(1.0, 0.75, flatten)
		top_ring.append(Vector3(cos(angle) * r_top, top_y + rng.randf_range(0.0, height * 0.06), sin(angle) * r_top))
		bot_ring.append(Vector3(cos(angle) * r_bot, bot_y, sin(angle) * r_bot))
	var hub_top := Vector3(0.0, top_y + height * 0.04, 0.0)
	var hub_bot := Vector3.ZERO
	for i in range(count):
		var n: int = (i + 1) % count
		var shade: float = 0.78 + float(i % 3) * 0.05
		var col := Common.shade_color(shade)
		if top_y > 0.08:
			Common.add_flat_tri(vertices, colors, uvs, indices, top_ring[i], top_ring[n], hub_top, col)
		Common.add_flat_tri(vertices, colors, uvs, indices, bot_ring[n], bot_ring[i], hub_bot, col * Color(0.72, 0.7, 0.68, 1.0))
		Common.add_flat_quad(vertices, colors, uvs, indices, bot_ring[i], bot_ring[n], top_ring[n], top_ring[i], col * Color(0.86, 0.84, 0.82, 1.0))
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)
