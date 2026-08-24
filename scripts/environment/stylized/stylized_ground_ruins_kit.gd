extends RefCounted
class_name StylizedGroundRuinsKit

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")

## V20 — Modular stylized ground & ruins meshes (Godot-native, faceted low-poly).


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


static func _stone_material(mats: Dictionary, tone: String = "main") -> Material:
	match tone:
		"light":
			return StylizedTypedAccess.material(mats, "stone_light", "stone_light")
		"dark":
			return StylizedTypedAccess.material(mats, "stone_dark", "rock_dark")
		"warm":
			return StylizedTypedAccess.material(mats, "stone_warm", "cliff_warm")
		"path":
			return StylizedTypedAccess.material(mats, "path_stone", "stone_light")
		_:
			return StylizedTypedAccess.material(mats, "stone_main", "rock")


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


static func _build_block_mesh(size: Vector3, variant: int, seed: int, shade: float = 0.86) -> ArrayMesh:
	var rng := _rng(4100 + variant * 53 + seed)
	var hx: float = size.x * 0.5
	var hy: float = size.y
	var hz: float = size.z * 0.5
	var jitter := [
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(0.0, 0.03), rng.randf_range(-0.04, 0.04)),
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(0.0, 0.03), rng.randf_range(-0.04, 0.04)),
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(0.0, 0.03), rng.randf_range(-0.04, 0.04)),
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(0.0, 0.03), rng.randf_range(-0.04, 0.04)),
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(-0.0, 0.02), rng.randf_range(-0.04, 0.04)),
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(-0.0, 0.02), rng.randf_range(-0.04, 0.04)),
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(-0.0, 0.02), rng.randf_range(-0.04, 0.04)),
		Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(-0.0, 0.02), rng.randf_range(-0.04, 0.04)),
	]
	var top := [
		Vector3(-hx, hy, -hz) + jitter[0], Vector3(hx, hy, -hz) + jitter[1],
		Vector3(hx, hy, hz) + jitter[2], Vector3(-hx, hy, hz) + jitter[3],
	]
	var bot := [
		Vector3(-hx, 0.0, -hz) + jitter[4], Vector3(hx, 0.0, -hz) + jitter[5],
		Vector3(hx, 0.0, hz) + jitter[6], Vector3(-hx, 0.0, hz) + jitter[7],
	]
	var col := Color(shade, shade * 0.97, shade * 0.93, 1.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_quad(st, top[0], top[1], top[2], top[3], col * Color(1.04, 1.04, 1.02, 1.0))
	_add_quad(st, bot[2], bot[1], bot[0], bot[3], col * Color(0.78, 0.76, 0.74, 1.0))
	_add_quad(st, top[0], top[1], bot[1], bot[0], col * Color(0.9, 0.88, 0.86, 1.0))
	_add_quad(st, top[1], top[2], bot[2], bot[1], col * Color(0.84, 0.82, 0.8, 1.0))
	_add_quad(st, top[2], top[3], bot[3], bot[2], col * Color(0.88, 0.86, 0.84, 1.0))
	_add_quad(st, top[3], top[0], bot[0], bot[3], col * Color(0.82, 0.8, 0.78, 1.0))
	return st.commit()


static func build_path_stone_mesh(variant: int, seed: int) -> ArrayMesh:
	var rng := _rng(8800 + variant * 19 + seed)
	var width: float = rng.randf_range(0.68, 0.96)
	var depth: float = rng.randf_range(0.58, 0.86)
	var height: float = rng.randf_range(0.10, 0.15)
	var stretch: float = [1.0, 1.08, 0.92, 1.12, 0.95, 1.05, 0.98, 1.1][variant % 8]
	return _build_block_mesh(Vector3(width * stretch, height, depth / stretch), variant, seed, 0.9)


static func place_path_stones(
	parent: Node3D,
	waypoints: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int = 1200
) -> void:
	for i in range(waypoints.size()):
		var data: Dictionary = waypoints[i]
		var mesh: ArrayMesh = build_path_stone_mesh(i % 8, seed + i * 7)
		var pos: Vector3 = data["pos"]
		pos.y = float(data.get("y", 0.04))
		mesh_fn.call(
			parent,
			mesh,
			_stone_material(mats, "path"),
			pos,
			Vector3.ONE,
			Vector3(0.0, float(data.get("rot_y", 0.0)), 0.0)
		)


static func place_ruin_block(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	mats: Dictionary,
	mesh_fn: Callable,
	variant: int,
	seed: int,
	tone: String = "main",
	rot: Vector3 = Vector3.ZERO
) -> void:
	var mesh: ArrayMesh = _build_block_mesh(size, variant, seed, 0.84 if tone == "dark" else 0.88)
	mesh_fn.call(parent, mesh, _stone_material(mats, tone), pos, Vector3.ONE, rot)


static func add_wall_segment(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	mats: Dictionary,
	mesh_fn: Callable,
	broken: bool,
	seed: int
) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	var blocks: Array = [
		{"p": Vector3(-1.05, 0.0, 0.0), "s": Vector3(0.72, 0.56, 0.5), "v": 0, "t": "main"},
		{"p": Vector3(-0.28, 0.0, 0.04), "s": Vector3(0.78, 0.68, 0.48), "v": 1, "t": "warm"},
		{"p": Vector3(0.52, 0.0, -0.02), "s": Vector3(0.68, 0.48, 0.46), "v": 2, "t": "main"},
		{"p": Vector3(1.18, 0.0, 0.03), "s": Vector3(0.74, 0.62, 0.5), "v": 3, "t": "dark"},
		{"p": Vector3(-0.62, 0.56, 0.0), "s": Vector3(0.82, 0.42, 0.52), "v": 4, "t": "light"},
		{"p": Vector3(0.42, 0.68, 0.02), "s": Vector3(0.7, 0.38, 0.48), "v": 5, "t": "warm"},
	]
	if broken:
		blocks.remove_at(3)
		blocks.remove_at(1)
	for i in range(blocks.size()):
		var block: Dictionary = blocks[i]
		place_ruin_block(
			root, block["p"], block["s"], mats, mesh_fn,
			int(block["v"]), seed + i * 11, str(block["t"])
		)


static func add_pillar(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	mats: Dictionary,
	mesh_fn: Callable,
	broken: bool,
	seed: int
) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	place_ruin_block(root, Vector3(0.0, 0.0, 0.0), Vector3(0.82, 0.36, 0.82), mats, mesh_fn, 0, seed, "dark")
	if broken:
		place_ruin_block(root, Vector3(0.04, 0.44, 0.0), Vector3(0.52, 0.72, 0.52), mats, mesh_fn, 1, seed + 3, "main", Vector3(8, 0, -14))
		place_ruin_block(root, Vector3(0.22, 0.2, 0.18), Vector3(0.34, 0.28, 0.3), mats, mesh_fn, 2, seed + 5, "warm", Vector3(-18, 32, 10))
	else:
		place_ruin_block(root, Vector3(0.0, 0.36, 0.0), Vector3(0.48, 0.88, 0.48), mats, mesh_fn, 1, seed + 3, "main")
		place_ruin_block(root, Vector3(0.0, 0.92, 0.0), Vector3(0.62, 0.22, 0.62), mats, mesh_fn, 2, seed + 5, "light")


static func add_stair_segment(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	mats: Dictionary,
	mesh_fn: Callable,
	step_count: int,
	seed: int
) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	for i in range(step_count):
		var tread: float = 0.58 - i * 0.03
		place_ruin_block(
			root,
			Vector3(0.0, 0.0 + i * 0.14, -i * 0.52),
			Vector3(1.35 - i * 0.06, 0.14, tread),
			mats, mesh_fn, i % 4, seed + i * 13, "light" if i % 2 == 0 else "main"
		)
	place_ruin_block(root, Vector3(-0.72, 0.0, -step_count * 0.26), Vector3(0.28, 0.44, step_count * 0.52 + 0.2), mats, mesh_fn, 3, seed + 90, "dark")
	place_ruin_block(root, Vector3(0.72, 0.0, -step_count * 0.26), Vector3(0.28, 0.44, step_count * 0.52 + 0.2), mats, mesh_fn, 4, seed + 91, "dark")


static func add_plinth(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int
) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	place_ruin_block(root, Vector3(0.0, 0.0, 0.0), Vector3(1.05, 0.24, 1.05), mats, mesh_fn, 0, seed, "dark")
	place_ruin_block(root, Vector3(0.0, 0.24, 0.0), Vector3(0.82, 0.32, 0.82), mats, mesh_fn, 1, seed + 2, "main")
	place_ruin_block(root, Vector3(0.0, 0.56, 0.0), Vector3(0.92, 0.16, 0.92), mats, mesh_fn, 2, seed + 4, "light")


static func add_arch_fragment(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int
) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	add_pillar(root, Vector3(-0.95, 0.0, 0.0), 0.0, mats, mesh_fn, true, seed)
	add_pillar(root, Vector3(0.95, 0.0, 0.0), 0.0, mats, mesh_fn, true, seed + 40)
	place_ruin_block(root, Vector3(-0.45, 1.02, 0.0), Vector3(0.52, 0.28, 0.48), mats, mesh_fn, 3, seed + 50, "warm", Vector3(0, 0, 18))
	place_ruin_block(root, Vector3(0.35, 1.06, 0.02), Vector3(0.48, 0.24, 0.44), mats, mesh_fn, 4, seed + 51, "main", Vector3(0, 0, -12))


static func add_corner_ruin(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int
) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	add_wall_segment(root, Vector3.ZERO, 0.0, mats, mesh_fn, true, seed)
	add_pillar(root, Vector3(1.35, 0.0, 0.55), -24.0, mats, mesh_fn, true, seed + 70)
	add_rubble_cluster(root, Vector3(-0.35, 0.0, 0.85), mats, mesh_fn, seed + 80)


static func add_rubble_cluster(
	parent: Node3D,
	pos: Vector3,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int,
	count: int = 4
) -> void:
	var rng := _rng(seed)
	for i in range(count):
		var size := Vector3(
			rng.randf_range(0.18, 0.34),
			rng.randf_range(0.12, 0.22),
			rng.randf_range(0.16, 0.3)
		)
		var offset := Vector3(
			rng.randf_range(-0.45, 0.45),
			0.0,
			rng.randf_range(-0.35, 0.35)
		)
		place_ruin_block(parent, pos + offset, size, mats, mesh_fn, i, seed + i * 3, "warm" if i % 2 == 0 else "main", Vector3(rng.randf_range(-12, 12), rng.randf_range(-20, 20), rng.randf_range(-10, 10)))


static func add_edge_stones(
	parent: Node3D,
	positions: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int
) -> void:
	for i in range(positions.size()):
		var pos: Vector3 = positions[i]
		place_ruin_block(
			parent,
			pos + Vector3(0.0, 0.0, 0.0),
			Vector3(0.42, 0.16, 0.36),
			mats, mesh_fn, i % 3, seed + i * 5, "dark",
			Vector3(0.0, float(i * 17), 0.0)
		)


static func validate_mesh(mesh: ArrayMesh) -> Dictionary:
	var report := {"errors": PackedStringArray(), "lowest_y": 99999.0, "highest_y": -99999.0}
	for surface_index in range(mesh.get_surface_count()):
		var vertices: PackedVector3Array = mesh.surface_get_arrays(surface_index)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			if not vertex.is_finite():
				report.errors.append("non-finite vertex")
			report.lowest_y = minf(report.lowest_y, vertex.y)
			report.highest_y = maxf(report.highest_y, vertex.y)
	return report
