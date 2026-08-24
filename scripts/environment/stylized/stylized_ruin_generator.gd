extends RefCounted
class_name StylizedRuinGenerator

const StylizedGroundRuinsKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")
const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func add_stone_block(parent: Node3D, pos: Vector3, size: Vector3, mats: Dictionary, mesh_fn: Callable, rot: Vector3 = Vector3.ZERO) -> void:
	StylizedGroundRuinsKit.place_ruin_block(parent, pos, size, mats, mesh_fn, 0, int(pos.x * 17.0 + pos.z * 31.0), "main", rot)


static func add_broken_wall(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> void:
	StylizedGroundRuinsKit.add_wall_segment(parent, pos, -18.0, mats, mesh_fn, true, 2201)


static func add_signpost(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> void:
	var sign: Node3D = Node3D.new()
	sign.position = pos
	parent.add_child(sign)
	mesh_fn.call(sign, _cylinder(0.08, 1.35, 6), StylizedTypedAccess.material(mats, "wood", "wood"), Vector3(0, 0.68, 0))
	var board: BoxMesh = BoxMesh.new()
	board.size = Vector3(0.9, 0.45, 0.08)
	mesh_fn.call(sign, board, StylizedTypedAccess.material(mats, "leaf_green", "grass_light"), Vector3(0.15, 1.15, 0), Vector3.ONE, Vector3(0, -22, 8))
	var arrow: PrismMesh = PrismMesh.new()
	arrow.size = Vector3(0.22, 0.18, 0.12)
	mesh_fn.call(sign, arrow, StylizedTypedAccess.material(mats, "grass_light", "grass_light"), Vector3(0.42, 1.15, 0.06), Vector3.ONE, Vector3(0, 0, 90))


static func add_stone_steps(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, count: int = 4) -> void:
	StylizedGroundRuinsKit.add_stair_segment(parent, pos, 0.0, mats, mesh_fn, count, 3301)


static func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh
