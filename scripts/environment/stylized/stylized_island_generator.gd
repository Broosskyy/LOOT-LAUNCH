extends RefCounted
class_name StylizedIslandGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const TerrainSurface = preload("res://scripts/environment/stylized/stylized_terrain_surface.gd")

## V19 — Ring-based stylized floating island geometry.
## Four silhouette families (ROUND, LONG, OFFSET, TERRACED) with HERO / PLAYABLE / DISTANT LOD.

enum Silhouette { ROUND, LONG, OFFSET, TERRACED }
enum IslandLOD { HERO, PLAYABLE, DISTANT }


static func silhouette_name(variant: int) -> String:
	return ["ROUND", "LONG", "OFFSET", "TERRACED"][clampi(variant, 0, 3)]


static func build(
	root: Node3D,
	radius: float,
	thickness: float,
	playable: bool,
	island_index: int,
	mats: Dictionary,
	quality_level: int,
	route_variant: int,
	mesh_fn: Callable
) -> void:
	var variant: int = absi(island_index + route_variant * 3) % 4
	var lod: IslandLOD = _resolve_lod(playable, island_index)
	var segments: int = _segment_count(lod, quality_level)
	var rng: RandomNumberGenerator = _rng(island_index, route_variant, variant)
	var profile: Array = _build_profile(lod, variant, radius, thickness, island_index, rng)
	var rings: Array = _build_ring_vertices(profile, segments, variant, island_index, radius, rng)
	var grass_key: String = "grass_main" if playable else "distant_grass"
	var cliff_key: String = "stone_dark" if playable else "distant_rock"
	var bottom_key: String = "stone_main" if playable else "distant_rock"
	_build_grass_cap(root, rings, segments, variant, island_index, lod, mats, mesh_fn, grass_key)
	_build_rock_body(
		root, rings, profile, segments, variant, island_index, lod, radius,
		mats, mesh_fn, cliff_key, bottom_key
	)
	if playable and island_index != 0:
		pass
	if lod == IslandLOD.HERO:
		TerrainSurface.dress_hero_island(root, radius, island_index, mats, mesh_fn, quality_level, island_index * 131 + route_variant)


static func _resolve_lod(playable: bool, island_index: int) -> IslandLOD:
	if playable and island_index == 0:
		return IslandLOD.HERO
	if playable:
		return IslandLOD.PLAYABLE
	return IslandLOD.DISTANT


static func _segment_count(lod: IslandLOD, quality_level: int) -> int:
	match lod:
		IslandLOD.HERO:
			return 24
		IslandLOD.PLAYABLE:
			return 18
		_:
			return 10 if quality_level == 0 else 12


static func _rng(island_index: int, route_variant: int, variant: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12007 + island_index * 811 + route_variant * 313 + variant * 97
	return rng


static func _squash_axes(variant: int) -> Vector2:
	match variant:
		Silhouette.LONG:
			return Vector2(0.76, 1.28)
		Silhouette.OFFSET:
			return Vector2(0.92, 1.02)
		Silhouette.TERRACED:
			return Vector2(0.88, 0.94)
		_:
			return Vector2(1.0, 1.0)


static func _build_profile(
	lod: IslandLOD,
	variant: int,
	radius: float,
	thickness: float,
	island_index: int,
	rng: RandomNumberGenerator
) -> Array:
	var depth_scale: float
	match lod:
		IslandLOD.HERO:
			depth_scale = 0.62
		IslandLOD.PLAYABLE:
			depth_scale = 0.56
		_:
			depth_scale = 0.54
	var depth: float = radius * depth_scale + thickness * 0.55 + rng.randf_range(0.0, 0.35)
	var layers: Array
	match lod:
		IslandLOD.HERO:
			layers = [
				{"y": 0.02, "s": 1.00},
				{"y": -0.10, "s": 0.98},
				{"y": -0.42, "s": 0.94},
				{"y": -0.95, "s": 0.86},
				{"y": -1.55, "s": 0.74},
				{"y": -2.20, "s": 0.58},
				{"y": -2.85, "s": 0.42},
				{"y": -3.45, "s": 0.28},
				{"y": -depth, "s": 0.16},
			]
		IslandLOD.PLAYABLE:
			layers = [
				{"y": 0.01, "s": 1.00},
				{"y": -0.08, "s": 0.97},
				{"y": -0.55, "s": 0.88},
				{"y": -1.20, "s": 0.72},
				{"y": -1.95, "s": 0.52},
				{"y": -2.65, "s": 0.34},
				{"y": -depth, "s": 0.17},
			]
		_:
			layers = [
				{"y": 0.00, "s": 1.00},
				{"y": -0.12, "s": 0.95},
				{"y": -0.70, "s": 0.82},
				{"y": -1.45, "s": 0.58},
				{"y": -depth, "s": 0.22},
			]
	if variant == Silhouette.TERRACED:
		for i in range(layers.size()):
			var step: int = i / 2
			layers[i]["s"] = lerpf(1.0, layers[-1]["s"], float(step) / float(maxi(1, layers.size() / 2)))
	elif variant == Silhouette.OFFSET:
		var drift_angle: float = rng.randf_range(0.4, 2.4) + island_index * 0.35
		for i in range(layers.size()):
			var t: float = float(i) / float(maxi(1, layers.size() - 1))
			layers[i]["ox"] = cos(drift_angle) * radius * 0.14 * t * t
			layers[i]["oz"] = sin(drift_angle) * radius * 0.12 * t * t
	return layers


static func _ring_radius(
	base_scale: float,
	angle: float,
	segment_index: int,
	ring_index: int,
	variant: int,
	island_index: int,
	rng: RandomNumberGenerator
) -> float:
	var wave_a: float = [1.71, 1.42, 1.95, 1.58][variant]
	var wave_b: float = [0.77, 1.12, 0.64, 0.91][variant]
	var wave: float = sin(angle * wave_a + island_index * 0.17) * 0.055
	wave += cos(angle * wave_b + variant) * 0.038
	wave += rng.randf_range(-0.028, 0.028)
	if ring_index <= 1:
		wave *= 0.55
	var bulge: float = 0.0
	if ring_index in [3, 4, 5] and segment_index % 5 == island_index % 5:
		bulge = 0.05 + sin(angle * 3.0) * 0.02
	return base_scale * (1.0 + wave + bulge)


static func _build_ring_vertices(
	profile: Array,
	segments: int,
	variant: int,
	island_index: int,
	radius: float,
	rng: RandomNumberGenerator
) -> Array:
	var squash: Vector2 = _squash_axes(variant)
	var rings: Array = []
	for ring_index in range(profile.size()):
		var layer: Dictionary = profile[ring_index]
		var verts: PackedVector3Array = PackedVector3Array()
		verts.resize(segments)
		for i in range(segments):
			var angle: float = TAU * float(i) / float(segments)
			var r: float = _ring_radius(
				float(layer["s"]), angle, i, ring_index, variant, island_index, rng
			) * radius
			var ox: float = float(layer.get("ox", 0.0))
			var oz: float = float(layer.get("oz", 0.0))
			verts[i] = Vector3(
				cos(angle) * r * squash.x + ox,
				float(layer["y"]),
				sin(angle) * r * squash.y + oz
			)
		rings.append(verts)
	return rings


static func _build_grass_cap(
	root: Node3D,
	rings: Array,
	segments: int,
	variant: int,
	island_index: int,
	lod: IslandLOD,
	mats: Dictionary,
	mesh_fn: Callable,
	grass_key: String
) -> void:
	var outer: PackedVector3Array = rings[0]
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner: PackedVector3Array = PackedVector3Array()
	var mid: PackedVector3Array = PackedVector3Array()
	inner.resize(segments)
	mid.resize(segments)
	for i in range(segments):
		inner[i] = Vector3(outer[i].x * 0.28, 0.012, outer[i].z * 0.28)
		mid[i] = Vector3(outer[i].x * 0.62, 0.008, outer[i].z * 0.62)
	for i in range(segments):
		var next: int = (i + 1) % segments
		var shade: float = 0.90 + sin(float(i) * 1.4 + variant) * 0.05 + float(island_index % 3) * 0.012
		var col := Color(shade * 0.95, shade, shade * 0.93, 1.0)
		_add_flat_tri(top, Vector3.ZERO, mid[i], mid[next], Vector3.UP, col)
		_add_flat_tri(top, mid[i], outer[i], outer[next], Vector3.UP, col)
		_add_flat_tri(top, mid[i], outer[next], mid[next], Vector3.UP, col)
	if lod != IslandLOD.DISTANT and rings.size() > 1:
		var lip: PackedVector3Array = rings[1]
		for i in range(segments):
			var next: int = (i + 1) % segments
			var lip_col := Color(0.58, 0.50, 0.44, 1.0)
			_add_flat_tri(top, outer[i], outer[next], lip[next], Vector3.UP, lip_col)
			_add_flat_tri(top, outer[i], lip[next], lip[i], Vector3.UP, lip_col)
	top.generate_normals()
	mesh_fn.call(root, top.commit(), StylizedTypedAccess.material(mats, grass_key, "grass"))


static func _build_rock_body(
	root: Node3D,
	rings: Array,
	profile: Array,
	segments: int,
	variant: int,
	island_index: int,
	lod: IslandLOD,
	radius: float,
	mats: Dictionary,
	mesh_fn: Callable,
	cliff_key: String,
	bottom_key: String
) -> void:
	var cliff_split: int = maxi(2, int(ceil(float(profile.size()) * 0.58)))
	var cliff := SurfaceTool.new()
	var bottom := SurfaceTool.new()
	cliff.begin(Mesh.PRIMITIVE_TRIANGLES)
	bottom.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index in range(profile.size() - 1):
		var upper: PackedVector3Array = rings[ring_index]
		var lower: PackedVector3Array = rings[ring_index + 1]
		var target: SurfaceTool = cliff if ring_index < cliff_split else bottom
		var t0: float = float(ring_index) / float(profile.size())
		for i in range(segments):
			var next: int = (i + 1) % segments
			var shade: float = 0.88 - t0 * 0.24 + sin(float(i) * 1.15 + variant) * 0.05
			var col := Color(shade, shade * 0.96, shade * 0.90, 1.0)
			_add_quad_faceted(target, upper[i], upper[next], lower[next], lower[i], col)
	var last_ring: PackedVector3Array = rings[-1]
	var last_layer: Dictionary = profile[-1]
	var mid_ring: PackedVector3Array = PackedVector3Array()
	mid_ring.resize(segments)
	var mid_y: float = float(last_layer["y"]) - radius * 0.10
	var mid_scale: float = float(last_layer["s"]) * 0.55
	var squash: Vector2 = _squash_axes(variant)
	var ox: float = float(last_layer.get("ox", 0.0))
	var oz: float = float(last_layer.get("oz", 0.0))
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		mid_ring[i] = Vector3(
			cos(angle) * mid_scale * radius * squash.x + ox,
			mid_y,
			sin(angle) * mid_scale * radius * squash.y + oz
		)
	for i in range(segments):
		var next: int = (i + 1) % segments
		var shade: float = 0.56 + sin(float(i) * 0.8) * 0.03
		var col := Color(shade, shade * 0.96, shade * 0.92, 1.0)
		_add_quad_faceted(bottom, last_ring[i], last_ring[next], mid_ring[next], mid_ring[i], col)
	var tip_cluster: Array = _bottom_tip_cluster(last_ring, last_layer, variant, island_index, radius)
	for i in range(segments):
		var next: int = (i + 1) % segments
		var tip: Vector3 = tip_cluster[i % tip_cluster.size()]
		var shade: float = 0.52 + float(i % 3) * 0.03
		var col := Color(shade, shade * 0.96, shade * 0.90, 1.0)
		_add_flat_tri(bottom, mid_ring[i], mid_ring[next], tip, _face_normal(mid_ring[i], mid_ring[next], tip), col)
	var underside := SurfaceTool.new()
	underside.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, tip_cluster.size() - 1):
		var n := Vector3.DOWN
		_add_flat_tri(underside, tip_cluster[0], tip_cluster[i + 1], tip_cluster[i], n, Color(0.58, 0.56, 0.54, 1.0))
	mesh_fn.call(root, cliff.commit(), StylizedTypedAccess.material(mats, cliff_key, "rock_dark"))
	mesh_fn.call(root, bottom.commit(), StylizedTypedAccess.material(mats, bottom_key, "rock"))
	mesh_fn.call(root, underside.commit(), StylizedTypedAccess.material(mats, bottom_key, "rock"))


static func _bottom_tip_cluster(
	last_ring: PackedVector3Array,
	last_layer: Dictionary,
	variant: int,
	island_index: int,
	radius: float
) -> Array:
	var base_y: float = float(last_layer["y"])
	var ox: float = float(last_layer.get("ox", 0.0))
	var oz: float = float(last_layer.get("oz", 0.0))
	var spread: float = radius * ([0.14, 0.18, 0.12, 0.16][variant])
	var drop: float = radius * 0.22
	var angle_base: float = float(island_index) * 0.9 + float(variant) * 1.3
	return [
		Vector3(ox + cos(angle_base) * spread, base_y - drop * 0.55, oz + sin(angle_base) * spread),
		Vector3(ox + cos(angle_base + 2.2) * spread * 0.82, base_y - drop * 0.85, oz + sin(angle_base + 2.2) * spread * 0.78),
		Vector3(ox + cos(angle_base - 1.6) * spread * 0.68, base_y - drop, oz + sin(angle_base - 1.6) * spread * 0.72),
	]


static func _face_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 0.000001:
		return Vector3.UP
	return n.normalized()


static func _add_flat_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, color: Color) -> void:
	for v in [a, b, c]:
		st.set_normal(normal)
		st.set_color(color)
		st.add_vertex(v)


static func _add_quad_faceted(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	color: Color
) -> void:
	_add_flat_tri(st, a, b, c, _face_normal(a, b, c), color)
	_add_flat_tri(st, a, c, d, _face_normal(a, c, d), color)


static func _scatter_top_details(
	root: Node3D,
	radius: float,
	island_index: int,
	mats: Dictionary,
	mesh_fn: Callable
) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9901 + island_index
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0 + rng.randf_range(-0.2, 0.2)
		var edge_pos: Vector3 = Vector3(cos(angle) * radius * 0.86, 0.14, sin(angle) * radius * 0.72)
		var stone: PrismMesh = PrismMesh.new()
		stone.size = Vector3(rng.randf_range(0.45, 0.9), rng.randf_range(0.28, 0.55), rng.randf_range(0.4, 0.75))
		mesh_fn.call(root, stone, StylizedTypedAccess.material(mats, "stone_main", "rock"), edge_pos, Vector3.ONE,
			Vector3(rng.randf_range(-10.0, 10.0), rad_to_deg(-angle), rng.randf_range(-8.0, 8.0)))


static func bounds_for_island(island_root: Node3D) -> Dictionary:
	var min_v := Vector3(INF, INF, INF)
	var max_v := Vector3(-INF, -INF, -INF)
	for child in island_root.get_children():
		if child is MeshInstance3D and child.mesh is ArrayMesh:
			var vertices: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				min_v = min_v.min(vertex)
				max_v = max_v.max(vertex)
	return {"min": min_v, "max": max_v}
