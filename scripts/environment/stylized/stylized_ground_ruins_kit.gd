extends RefCounted
class_name StylizedGroundRuinsKit

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const TerrainSurface = preload("res://scripts/environment/stylized/stylized_terrain_surface.gd")

## V27 — Modular stylized ground & ruins meshes (beveled blocks, faceted stones).


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
		"ruin":
			return StylizedTypedAccess.material(mats, "ruin_stone", "stone_main")
		_:
			return StylizedTypedAccess.material(mats, "ruin_stone", "stone_main")


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
	var bevel: float = minf(size.x, size.z) * 0.07
	return MeshLib.beveled_box(size, bevel, variant * 53 + seed, shade)


static func build_path_stone_mesh(variant: int, seed: int) -> ArrayMesh:
	return MeshLib.path_stone(variant, seed)


static func place_path_stones(
	parent: Node3D,
	waypoints: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int = 1200
) -> void:
	TerrainSurface.dress_path_embedded(parent, waypoints, mats, mesh_fn, seed, 2)
	for i in range(waypoints.size()):
		var data: Dictionary = waypoints[i]
		var mesh: ArrayMesh = build_path_stone_mesh(i % 8, seed + i * 7)
		var pos: Vector3 = data["pos"]
		pos.y = float(data.get("y", 0.04)) - 0.025
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
	var mesh: ArrayMesh = Toolkit.wall_segment(2.6, 1.05, 0.48, 3, 4, true, broken, seed, 1)
	mesh_fn.call(root, mesh, _stone_material(mats, "ruin"), Vector3.ZERO)


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
	place_ruin_block(root, Vector3(0.0, 0.0, 0.0), Vector3(0.88, 0.38, 0.88), mats, mesh_fn, 0, seed, "dark")
	if broken:
		mesh_fn.call(root, MeshLib.tapered_cylinder(0.22, 0.28, 0.78, 6, seed + 1), _stone_material(mats, "main"), Vector3(0.06, 0.38, 0.02), Vector3.ONE, Vector3(8, 0, -14))
		place_ruin_block(root, Vector3(0.22, 0.2, 0.18), Vector3(0.34, 0.28, 0.3), mats, mesh_fn, 2, seed + 5, "warm", Vector3(-18, 32, 10))
	else:
		mesh_fn.call(root, MeshLib.tapered_cylinder(0.2, 0.26, 0.92, 6, seed + 3), _stone_material(mats, "main"), Vector3(0, 0.38, 0))
		place_ruin_block(root, Vector3(0.0, 0.92, 0.0), Vector3(0.68, 0.24, 0.68), mats, mesh_fn, 2, seed + 5, "light")


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
	var mesh: ArrayMesh = Toolkit.octagonal_plinth(0.72, 0.48, 0.58, seed, 1)
	mesh_fn.call(root, mesh, _stone_material(mats, "main"), Vector3.ZERO)
	var cap: ArrayMesh = Toolkit.roof_cap(Toolkit.RoofKind.PYRAMIDAL_CAP, 0.72, 0.72, 0.22, 0.06, seed + 3, 0.04, 1)
	mesh_fn.call(root, cap, _stone_material(mats, "light"), Vector3(0.0, 0.58, 0.0))


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
	var mesh: ArrayMesh = Toolkit.arch(2.1, 1.25, 0.42, 8, seed, true, 0.05, 1)
	mesh_fn.call(root, mesh, _stone_material(mats, "ruin"), Vector3.ZERO)


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
		var offset := Vector3(
			rng.randf_range(-0.45, 0.45),
			0.0,
			rng.randf_range(-0.35, 0.35)
		)
		var rock: ArrayMesh = MeshLib.small_rock(i, seed + i * 3)
		mesh_fn.call(
			parent, rock, _stone_material(mats, "warm" if i % 2 == 0 else "main"),
			pos + offset, Vector3.ONE,
			Vector3(rng.randf_range(-12, 12), rng.randf_range(-20, 20), rng.randf_range(-10, 10))
		)


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
	return MeshLib.validate_mesh(mesh)
