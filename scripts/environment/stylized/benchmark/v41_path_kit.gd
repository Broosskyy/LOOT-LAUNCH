extends RefCounted
class_name V41PathKit

## V41 — Stepping-stone path kit with controlled variation.

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")

enum PathStoneKind { A, B, C, D, E }

static func kind_name(kind: int) -> String:
	return ["PathStone_A", "PathStone_B", "PathStone_C", "PathStone_D", "PathStone_E"][clampi(kind, 0, 4)]


static func all_kinds() -> Array:
	return [PathStoneKind.A, PathStoneKind.B, PathStoneKind.C, PathStoneKind.D, PathStoneKind.E]


static func build_stone(kind: int, seed: int) -> ArrayMesh:
	var rng := Common.rng(94000 + kind * 29 + seed)
	var sides: int = 5 + kind % 3
	var radius: float = 0.34 + float(kind) * 0.04 + rng.randf_range(-0.02, 0.03)
	var thickness: float = 0.10 + float(kind % 3) * 0.025
	var top_tilt: float = rng.randf_range(-0.02, 0.03)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var top_ring: Array[Vector3] = []
	var bot_ring: Array[Vector3] = []
	for i in range(sides):
		var angle: float = TAU * float(i) / float(sides) + rng.randf_range(-0.12, 0.12)
		var r: float = radius * (1.0 + rng.randf_range(-0.08, 0.1))
		var top := Vector3(cos(angle) * r, thickness + top_tilt * cos(angle * 2.0), sin(angle) * r)
		var bot := Vector3(cos(angle) * r * 0.92, 0.0, sin(angle) * r * 0.92)
		top_ring.append(top)
		bot_ring.append(bot)
	var hub_top := Vector3(0.0, thickness + 0.02, 0.0)
	var hub_bot := Vector3.ZERO
	for i in range(sides):
		var n: int = (i + 1) % sides
		var shade: float = 0.82 + float(i % 3) * 0.04
		var col := Common.shade_color(shade, Color(0.96, 0.94, 0.9, 1.0))
		Common.add_flat_tri(vertices, colors, uvs, indices, top_ring[i], top_ring[n], hub_top, col * Color(1.04, 1.02, 1.0, 1.0))
		Common.add_flat_tri(vertices, colors, uvs, indices, bot_ring[n], bot_ring[i], hub_bot, col * Color(0.74, 0.72, 0.7, 1.0))
		Common.add_flat_quad(vertices, colors, uvs, indices, bot_ring[i], bot_ring[n], top_ring[n], top_ring[i], col)
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func place_path(
	parent: Node3D,
	waypoints: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int = 4100
) -> void:
	var mat: Material = mats.get("path_stone", mats.get("stone_light"))
	var rng := Common.rng(seed)
	for i in range(waypoints.size()):
		var wp: Dictionary = waypoints[i]
		var pos: Vector3 = wp["pos"]
		pos.y = float(wp.get("y", 0.04))
		var kind: int = int(wp.get("kind", i % 5))
		var mesh: ArrayMesh = build_stone(kind, seed + i * 13)
		var rot_y: float = float(wp.get("rot_y", rng.randf_range(-18.0, 18.0)))
		var scale: float = float(wp.get("scale", 1.0 + rng.randf_range(-0.06, 0.08)))
		mesh_fn.call(parent, mesh, mat, pos, Vector3.ONE * scale, Vector3(0.0, rot_y, 0.0))
