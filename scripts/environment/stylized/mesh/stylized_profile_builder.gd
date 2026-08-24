extends RefCounted
class_name StylizedProfileBuilder

## V33 — 2D profiles for extrusion along curves.

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")

enum ProfileKind {
	RECT,
	TRAPEZOID,
	ROUNDED_RECT_LOW_POLY,
	STONE_EDGE,
}


static func sample_profile(
	kind: int,
	width: float,
	height: float,
	segments: int = 4,
	seed: int = 0
) -> PackedVector2Array:
	var rng := Common.rng(8800 + seed)
	var half_w: float = width * 0.5
	var pts := PackedVector2Array()
	match kind:
		ProfileKind.TRAPEZOID:
			pts.append(Vector2(-half_w * 0.82, 0.0))
			pts.append(Vector2(half_w * 0.82, 0.0))
			pts.append(Vector2(half_w, height))
			pts.append(Vector2(-half_w, height))
		ProfileKind.ROUNDED_RECT_LOW_POLY:
			var seg: int = maxi(segments, 3)
			for i in range(seg):
				var t: float = float(i) / float(seg)
				var angle: float = lerpf(PI, 0.0, t)
				pts.append(Vector2(cos(angle) * half_w, sin(angle) * height * 0.35 + height * 0.15))
			pts.append(Vector2(-half_w, 0.0))
		ProfileKind.STONE_EDGE:
			pts.append(Vector2(-half_w, 0.0) + Vector2(rng.randf_range(-0.02, 0.02), 0.0))
			pts.append(Vector2(half_w, 0.0) + Vector2(rng.randf_range(-0.02, 0.02), 0.0))
			pts.append(Vector2(half_w * 0.92, height * 0.55))
			pts.append(Vector2(half_w * 0.55, height))
			pts.append(Vector2(-half_w * 0.5, height * 0.92))
			pts.append(Vector2(-half_w * 0.88, height * 0.35))
		_:
			pts.append(Vector2(-half_w, 0.0))
			pts.append(Vector2(half_w, 0.0))
			pts.append(Vector2(half_w, height))
			pts.append(Vector2(-half_w, height))
	return pts
