extends RefCounted
class_name StylizedRuinGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func add_stone_block(parent: Node3D, pos: Vector3, size: Vector3, mats: Dictionary, mesh_fn: Callable, rot: Vector3 = Vector3.ZERO) -> void:
	var block: BoxMesh = BoxMesh.new()
	block.size = size
	mesh_fn.call(parent, block, StylizedTypedAccess.material(mats, "stone_main", "rock"), pos, Vector3.ONE, rot)


static func add_broken_wall(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> void:
	var wall: Node3D = Node3D.new()
	wall.position = pos
	wall.rotation_degrees.y = -18.0
	parent.add_child(wall)
	for i in range(4):
		var height: float = 0.55 + float(i % 2) * 0.35
		add_stone_block(wall, Vector3(i * 0.72 - 1.08, height * 0.5, 0.0), Vector3(0.68, height, 0.52), mats, mesh_fn)
	add_stone_block(wall, Vector3(-1.5, 0.25, 0.35), Vector3(0.5, 0.5, 0.5), mats, mesh_fn, Vector3(0, 24, -12))


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
	for i in range(count):
		var step: BoxMesh = BoxMesh.new()
		step.size = Vector3(1.4 - i * 0.08, 0.14, 0.62)
		mesh_fn.call(parent, step, StylizedTypedAccess.material(mats, "stone_light", "white"), pos + Vector3(0, i * 0.14, -i * 0.55))


static func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh
