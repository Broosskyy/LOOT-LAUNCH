extends RefCounted
class_name StylizedArchitectureGenerator

## V35 — Modular stylized fantasy architecture (walls, arches, gates, bridges, stairs).

const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const Profiles = preload("res://scripts/environment/stylized/mesh/stylized_profile_builder.gd")
const RuinsKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")
const TypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")

enum StructureType {
	WALL_SECTION, BROKEN_WALL_SECTION, ARCHWAY, GATE, PILLAR_CLUSTER,
	STAIR_TOWER, BRIDGE, LOOKOUT_RUIN, PORTAL_MONUMENT, WATCHTOWER, HERO_TOWER, RUIN_COURTYARD
}
enum DamageLevel { INTACT, LIGHT_RUIN, BROKEN, HEAVY_RUIN }
enum WallKind { LOW_WALL, FULL_WALL, BROKEN_WALL }

const VEG_HOOK_META := "architecture_veg_hook"


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 35007 + seed * 811
	return rng


static func _stone(mats: Dictionary, tone: String = "ruin") -> Material:
	return RuinsKit._stone_material(mats, tone)


static func _detail(quality: int) -> int:
	return 2 if quality >= 2 else 1


static func build_wall(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	length: float,
	height: float,
	kind: int,
	damage: int,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "ArchWall"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	var detail: int = _detail(quality)
	var broken: bool = kind == WallKind.BROKEN_WALL or damage >= DamageLevel.BROKEN
	var h: float = height
	if kind == WallKind.LOW_WALL:
		h = height * 0.55
	if damage == DamageLevel.HEAVY_RUIN:
		h *= 0.72
	var mesh: ArrayMesh = Toolkit.wall_segment(length, h, 0.46, 3, 4, true, broken, seed, detail)
	var node: MeshInstance3D = mesh_fn.call(root, mesh, _stone(mats, "ruin"))
	node.name = "WallMesh"
	if broken and damage >= DamageLevel.LIGHT_RUIN:
		RuinsKit.add_rubble_cluster(root, Vector3(length * 0.22, 0.0, 0.35), mats, mesh_fn, seed + 11, 3)
	_set_veg_hook(root, Vector3(length * 0.5, h, 0.2))
	return root


static func build_archway(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	width: float,
	height: float,
	broken: bool,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "Archway"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	var detail: int = _detail(quality)
	var mesh: ArrayMesh = Toolkit.arch(width, height, 0.44, 8, seed, broken, 0.06, detail)
	mesh_fn.call(root, mesh, _stone(mats, "ruin"))
	if broken:
		RuinsKit.place_ruin_block(root, Vector3(width * 0.28, 0.0, 0.18), Vector3(0.42, 0.32, 0.38), mats, mesh_fn, 1, seed + 3, "warm", Vector3(0, 18, 0))
	_set_veg_hook(root, Vector3(0.0, height * 0.85, 0.0))
	return root


static func build_gate(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "Gate"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	var detail: int = _detail(quality)
	var rng := _rng(seed)
	# Side towers.
	for side in [-1.0, 1.0]:
		var tower_x: float = side * 1.65
		var tower_h: float = 2.35 + rng.randf_range(-0.1, 0.15)
		var shaft := Toolkit.tapered_pillar(Toolkit.PillarKind.FULL_PILLAR, 0.38, 0.28, tower_h, 6, seed + int(side * 10), side < 0, detail)
		mesh_fn.call(root, shaft, _stone(mats, "dark"), Vector3(tower_x, 0.0, 0.0))
		var cap := Toolkit.roof_cap(Toolkit.RoofKind.PYRAMIDAL_CAP, 0.72, 0.62, 0.28, 0.05, seed + int(side * 20), 0.05, detail)
		mesh_fn.call(root, cap, _stone(mats, "warm"), Vector3(tower_x, tower_h, 0.0))
	# Central arch.
	var arch_mesh: ArrayMesh = Toolkit.arch(2.4, 1.55, 0.48, 8, seed + 30, true, 0.07, detail)
	mesh_fn.call(root, arch_mesh, _stone(mats, "ruin"), Vector3(0.0, 0.0, 0.0))
	# Broken upper wall band.
	var band := Toolkit.wall_segment(3.2, 0.55, 0.38, 2, 5, true, true, seed + 40, detail)
	mesh_fn.call(root, band, _stone(mats, "main"), Vector3(0.0, 1.85, -0.12))
	RuinsKit.add_rubble_cluster(root, Vector3(-0.8, 0.0, 0.55), mats, mesh_fn, seed + 50, 4)
	_add_simple_collision(root, Vector3(3.6, 2.2, 1.2), Vector3(0.0, 1.1, 0.0))
	_set_veg_hook(root, Vector3(-1.2, 0.0, 0.8))
	_set_veg_hook(root, Vector3(1.2, 0.0, 0.8))
	return root


static func build_pillar_cluster(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	count: int,
	broken: bool,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "PillarCluster"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	var rng := _rng(seed)
	for i in range(maxi(1, count)):
		var angle: float = TAU * float(i) / float(maxi(1, count)) + rng.randf_range(-0.2, 0.2)
		var dist: float = 0.55 if count > 1 else 0.0
		var pillar_pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		RuinsKit.add_pillar(root, pillar_pos, rng.randf_range(-18, 18), mats, mesh_fn, broken or i % 2 == 0, seed + i * 17)
	return root


static func build_stair_run(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	step_count: int,
	with_walls: bool,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "StairRun"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	RuinsKit.add_stair_segment(root, Vector3.ZERO, 0.0, mats, mesh_fn, step_count, seed)
	if with_walls:
		build_wall(root, Vector3(-0.95, 0.0, -step_count * 0.26), 0.0, 1.2, 0.85, WallKind.LOW_WALL, DamageLevel.LIGHT_RUIN, seed + 60, mats, mesh_fn, quality)
		build_wall(root, Vector3(0.95, 0.0, -step_count * 0.26), 0.0, 1.2, 0.85, WallKind.BROKEN_WALL, DamageLevel.BROKEN, seed + 61, mats, mesh_fn, quality)
	var landing := Toolkit.beveled_box(Vector3(1.5, 0.14, 0.9), 0.05, seed + 62, 0.86, 0.0, 0.0, 0.04, 1, _detail(quality))
	mesh_fn.call(root, landing, _stone(mats, "light"), Vector3(0.0, step_count * 0.14, -step_count * 0.52))
	_add_simple_collision(root, Vector3(1.4, step_count * 0.14 + 0.2, step_count * 0.52 + 0.4), Vector3(0.0, step_count * 0.07, -step_count * 0.26))
	return root


static func build_stone_bridge(
	parent: Node3D,
	start: Vector3,
	end: Vector3,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "StoneBridge"
	parent.add_child(root)
	var delta := end - start
	var length: float = Vector2(delta.x, delta.z).length()
	if length < 0.2:
		root.queue_free()
		return root
	var mid := (start + end) * 0.5
	mid.y = maxf(start.y, end.y) + 0.12
	root.position = mid
	var yaw: float = atan2(delta.x, delta.z)
	root.rotation.y = yaw
	var detail: int = _detail(quality)
	# Support piers.
	for t in [0.22, 0.78]:
		var pier := Toolkit.tapered_pillar(Toolkit.PillarKind.SHORT_COLUMN, 0.32, 0.38, 0.65 + t * 0.2, 6, seed + int(t * 100), false, detail)
		mesh_fn.call(root, pier, _stone(mats, "dark"), Vector3(0.0, -0.12, (t - 0.5) * length))
	# Arched deck via curved beam profile.
	var path: Array = [
		Vector3(0.0, 0.0, -length * 0.5),
		Vector3(0.0, 0.22, 0.0),
		Vector3(0.0, 0.0, length * 0.5),
	]
	var deck: ArrayMesh = Toolkit.curved_beam(path, Profiles.ProfileKind.STONE_EDGE, 1.35, 0.2, seed + 7, 4, detail)
	mesh_fn.call(root, deck, _stone(mats, "path"))
	for side in [-0.62, 0.62]:
		var rail_path: Array = [
			Vector3(side, 0.38, -length * 0.48),
			Vector3(side, 0.52, 0.0),
			Vector3(side, 0.38, length * 0.48),
		]
		var rail: ArrayMesh = Toolkit.curved_beam(rail_path, Profiles.ProfileKind.TRAPEZOID, 0.14, 0.12, seed + int(side * 50), 3, detail)
		mesh_fn.call(root, rail, _stone(mats, "dark"))
	_add_simple_collision(root, Vector3(1.4, 0.25, length), Vector3(0.0, 0.12, 0.0))
	return root


static func build_side_arch(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	return build_archway(parent, pos, rot_y, 2.8, 1.45, true, seed, mats, mesh_fn, quality)


static func _add_simple_collision(parent: Node3D, size: Vector3, offset: Vector3) -> void:
	if parent.get_node_or_null("ArchCollider") != null:
		return
	var body := StaticBody3D.new()
	body.name = "ArchCollider"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = offset
	body.add_child(col)
	parent.add_child(body)


static func _set_veg_hook(node: Node3D, local_pos: Vector3) -> void:
	var hook := Node3D.new()
	hook.name = "VegHook"
	hook.position = local_pos
	hook.set_meta(VEG_HOOK_META, true)
	node.add_child(hook)


static func count_mesh_instances(root: Node) -> int:
	var count := 0
	for child in root.get_children():
		if child is MeshInstance3D:
			count += 1
		count += count_mesh_instances(child)
	return count


static func estimate_triangles(root: Node) -> int:
	var total := 0
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh != null:
			for s in range(child.mesh.get_surface_count()):
				var arrays: Array = child.mesh.surface_get_arrays(s)
				if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
					total += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
				elif arrays.size() > Mesh.ARRAY_VERTEX:
					total += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		total += estimate_triangles(child)
	return total
