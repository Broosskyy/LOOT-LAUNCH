extends RefCounted
class_name StylizedIslandGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")

## Irregular floating island meshes — 4 silhouette variants, closed underside.


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
	var segments: int = 18 if playable else 10
	if quality_level == 0 and not playable:
		segments = 8
	var ring: PackedFloat32Array = _build_ring(radius, segments, island_index, variant, playable)
	var grass_key: String = "grass_main" if playable else "distant_grass"
	var cliff_key: String = "stone_dark" if playable else "distant_rock"
	var bottom_key: String = "stone_main" if playable else "distant_rock"
	_build_grass_top(root, ring, segments, variant, mats, mesh_fn, grass_key)
	_build_cliffs(root, ring, segments, radius, thickness, playable, island_index, variant, mats, mesh_fn, cliff_key, bottom_key)
	if playable and island_index != 0:
		_scatter_top_details(root, radius, island_index, mats, mesh_fn)


static func _build_ring(
	radius: float,
	segments: int,
	island_index: int,
	variant: int,
	playable: bool
) -> PackedFloat32Array:
	var ring: PackedFloat32Array = PackedFloat32Array()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12007 + island_index * 811 + variant * 97
	var wave_a: float = [1.71, 1.42, 1.95, 1.58][variant]
	var wave_b: float = [0.77, 1.12, 0.64, 0.91][variant]
	for i in range(segments):
		var wave: float = sin(float(i) * wave_a + island_index) * 0.06 + cos(float(i) * wave_b) * 0.04
		var irregular: float = wave + rng.randf_range(-0.05, 0.05)
		if island_index == 0 and playable:
			irregular += sin(float(i) * 2.3 + variant) * 0.09
		if not playable:
			irregular *= 0.65
		ring.append(radius * (1.0 + irregular))
	return ring


static func _squash_for_variant(variant: int) -> float:
	return [0.86, 0.82, 0.88, 0.84][variant]


static func _build_grass_top(
	root: Node3D,
	ring: PackedFloat32Array,
	segments: int,
	variant: int,
	mats: Dictionary,
	mesh_fn: Callable,
	grass_key: String
) -> void:
	var top: SurfaceTool = SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var squash: float = _squash_for_variant(variant)
	for i in range(segments):
		var next: int = (i + 1) % segments
		var a: float = TAU * float(i) / float(segments)
		var b: float = TAU * float(next) / float(segments)
		var shade: float = 0.92 + sin(float(i) * 1.4 + variant) * 0.05
		top.set_color(Color(shade * 0.96, shade, shade * 0.94, 1.0))
		top.set_uv(Vector2(0.5, 0.5))
		top.add_vertex(Vector3.ZERO)
		top.set_uv(Vector2(0.5 + cos(b) * 0.5, 0.5 + sin(b) * 0.5))
		top.add_vertex(Vector3(cos(b) * ring[next], 0.0, sin(b) * ring[next] * squash))
		top.set_uv(Vector2(0.5 + cos(a) * 0.5, 0.5 + sin(a) * 0.5))
		top.add_vertex(Vector3(cos(a) * ring[i], 0.0, sin(a) * ring[i] * squash))
	top.generate_normals()
	mesh_fn.call(root, top.commit(), StylizedTypedAccess.material(mats, grass_key, "grass"))


static func _build_cliffs(
	root: Node3D,
	ring: PackedFloat32Array,
	segments: int,
	radius: float,
	thickness: float,
	playable: bool,
	island_index: int,
	variant: int,
	mats: Dictionary,
	mesh_fn: Callable,
	cliff_key: String,
	bottom_key: String
) -> void:
	var squash: float = _squash_for_variant(variant)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4403 + island_index * 131 + variant
	var depth: float = radius * (0.58 if playable else 0.32) + rng.randf_range(-0.3, 0.5)
	var cliff: SurfaceTool = SurfaceTool.new()
	cliff.begin(Mesh.PRIMITIVE_TRIANGLES)
	var layer_count: int = 4 if playable else 3
	var y1: float = 0.0
	for layer in range(layer_count):
		var t0: float = float(layer) / float(layer_count)
		var t1: float = float(layer + 1) / float(layer_count)
		var y0: float = -0.08 - t0 * (depth + thickness * 0.5)
		y1 = -0.08 - t1 * (depth + thickness * 0.5)
		var scale0: float = lerpf(1.0, 0.14, t0) + sin(layer + variant) * 0.03
		var scale1: float = lerpf(1.0, 0.10, t1) + sin(layer + variant + 1) * 0.03
		for i in range(segments):
			var next: int = (i + 1) % segments
			var a: float = TAU * float(i) / float(segments)
			var b: float = TAU * float(next) / float(segments)
			var skew_a: float = 1.0 + sin(float(i) * 2.1 + variant) * 0.08
			var skew_b: float = 1.0 + sin(float(next) * 2.1 + variant) * 0.08
			var t_top: Vector3 = Vector3(cos(a) * ring[i] * scale0 * skew_a, y0, sin(a) * ring[i] * squash * scale0)
			var t1p: Vector3 = Vector3(cos(b) * ring[next] * scale0 * skew_b, y0, sin(b) * ring[next] * squash * scale0)
			var b0: Vector3 = Vector3(cos(a) * ring[i] * scale1, y1, sin(a) * ring[i] * squash * scale1)
			var b1: Vector3 = Vector3(cos(b) * ring[next] * scale1, y1, sin(b) * ring[next] * squash * scale1)
			var cliff_shade: float = 0.88 - t0 * 0.18 + sin(float(i) * 1.2) * 0.04
			cliff.set_color(Color(cliff_shade, cliff_shade * 0.97, cliff_shade * 0.93, 1.0))
			cliff.add_vertex(t_top)
			cliff.add_vertex(t1p)
			cliff.add_vertex(b0)
			cliff.add_vertex(t1p)
			cliff.add_vertex(b1)
			cliff.add_vertex(b0)
	cliff.generate_normals()
	mesh_fn.call(root, cliff.commit(), StylizedTypedAccess.material(mats, cliff_key, "rock_dark"))
	var tip: Vector3 = Vector3(0.0, y1 - maxf(0.45, thickness * 0.28), 0.0)
	var last_scale: float = 0.12
	var bottom: SurfaceTool = SurfaceTool.new()
	bottom.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var next: int = (i + 1) % segments
		var a: float = TAU * float(i) / float(segments)
		var b: float = TAU * float(next) / float(segments)
		var a_bottom: Vector3 = Vector3(cos(a) * ring[i] * last_scale, y1, sin(a) * ring[i] * squash * last_scale)
		var b_bottom: Vector3 = Vector3(cos(b) * ring[next] * last_scale, y1, sin(b) * ring[next] * squash * last_scale)
		bottom.set_color(Color(0.42, 0.40, 0.38, 1.0))
		bottom.add_vertex(a_bottom)
		bottom.add_vertex(b_bottom)
		bottom.add_vertex(tip)
	bottom.generate_normals()
	mesh_fn.call(root, bottom.commit(), StylizedTypedAccess.material(mats, bottom_key, "rock"))
	if playable:
		for i in range(5):
			var facet_angle: float = TAU * float(i) / 5.0 + rng.randf_range(-0.25, 0.25)
			var facet: PrismMesh = PrismMesh.new()
			facet.size = Vector3(radius * 0.18, depth * rng.randf_range(0.22, 0.38), radius * 0.14)
			var facet_mat: Material = StylizedTypedAccess.material(mats, "stone_light" if i % 2 == 0 else "stone_dark", "rock")
			mesh_fn.call(
				root, facet, facet_mat,
				Vector3(cos(facet_angle) * radius * 0.62, -depth * rng.randf_range(0.28, 0.62), sin(facet_angle) * radius * 0.52),
				Vector3.ONE,
				Vector3(rng.randf_range(-14.0, 14.0), rad_to_deg(-facet_angle), rng.randf_range(-12.0, 12.0))
			)


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
