extends RefCounted
class_name StylizedVegetationDensity

## V28 — Deterministic vegetation density, exclusion zones, quality-tier scaling.

const StartComp = preload("res://scripts/environment/stylized/stylized_start_composition.gd")
const WorldComp = preload("res://scripts/environment/stylized/stylized_world_composition.gd")


static func density_scale(quality_level: int) -> float:
	match quality_level:
		0:
			return 0.42
		1:
			return 0.76
		_:
			return 1.0


static func start_island_exclusions() -> Array[Dictionary]:
	return [
		{"center": WorldComp.PLAYER_SPAWN_OFFSET, "radius": 1.85},
		{"center": Vector3(0.15, 0.0, 0.55), "radius": 1.45},
		{"center": WorldComp.CANNON_OFFSET, "radius": 2.55},
		{"center": StartComp.CHEST_POS, "radius": 1.35},
		{"center": StartComp.PAD_POS, "radius": 1.25},
		{"center": Vector3(0.35, 0.0, -2.82), "radius": 0.95},
	]


static func is_excluded(pos: Vector3, exclusions: Array) -> bool:
	for entry in exclusions:
		var center: Vector3 = entry["center"]
		var radius: float = float(entry["radius"])
		if Vector2(pos.x, pos.z).distance_to(Vector2(center.x, center.z)) < radius:
			return true
	return false


static func is_path_corridor(pos: Vector3, half_width: float = 0.62) -> bool:
	for wp in StartComp.PATH_STONES:
		var p: Vector3 = wp["pos"]
		if Vector2(pos.x, pos.z).distance_to(Vector2(p.x, p.z)) < half_width:
			return true
	return false


static func can_place_start(pos: Vector3, exclusions: Array, allow_path_edge: bool = false) -> bool:
	if not pos.is_finite():
		return false
	if is_excluded(pos, exclusions):
		return false
	if not allow_path_edge and is_path_corridor(pos, 0.48):
		return false
	return true


static func should_place(seed: int, weight: float, quality_level: int) -> bool:
	if quality_level >= 2:
		return true
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng.randf() <= clampf(weight * density_scale(quality_level), 0.0, 1.0)


static func tier_skip_every_nth(n: int, quality_level: int) -> int:
	if quality_level <= 0:
		return maxi(3, n)
	if quality_level == 1:
		return maxi(2, n)
	return n


static func edge_ring_positions(island_radius: float, segment_count: int, coverage: float, seed: int) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8200 + seed
	var out: Array[Vector3] = []
	var usable: int = maxi(2, int(float(segment_count) * coverage))
	var start: int = rng.randi_range(0, segment_count - 1)
	for i in range(usable):
		var seg: int = (start + i * 2) % segment_count
		var angle: float = TAU * float(seg) / float(segment_count) + rng.randf_range(-0.08, 0.08)
		var r: float = island_radius * rng.randf_range(0.82, 0.94)
		out.append(Vector3(cos(angle) * r, 0.0, sin(angle) * r))
	return out
