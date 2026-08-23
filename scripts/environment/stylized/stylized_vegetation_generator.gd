extends RefCounted
class_name StylizedVegetationGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func add_grass_tuft(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, scale_value: float = 1.0) -> void:
	var tuft: Node3D = Node3D.new()
	tuft.position = pos
	parent.add_child(tuft)
	for i in range(3):
		var blade: PrismMesh = PrismMesh.new()
		blade.size = Vector3(0.1, 0.38 + i * 0.05, 0.07) * scale_value
		mesh_fn.call(tuft, blade, StylizedTypedAccess.material(mats, "grass_dark", "grass_dark"),
			Vector3((i - 1) * 0.1, 0.16, 0.0), Vector3.ONE, Vector3(0, 0, -14.0 + i * 14.0))


static func add_flower(parent: Node3D, pos: Vector3, variant: int, mats: Dictionary, mesh_fn: Callable) -> void:
	var flower: Node3D = Node3D.new()
	flower.position = pos
	parent.add_child(flower)
	mesh_fn.call(flower, _cylinder(0.03, 0.26, 6), StylizedTypedAccess.material(mats, "grass_dark", "grass"), Vector3(0, 0.13, 0))
	var petal_mat: Material = StylizedTypedAccess.material(mats, "flower_pink" if variant == 0 else "flower_white", "flower_white")
	for angle in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var petal: PrismMesh = PrismMesh.new()
		petal.size = Vector3(0.14, 0.08, 0.1)
		var offset: Vector3 = Vector3(cos(deg_to_rad(angle)) * 0.08, 0.3, sin(deg_to_rad(angle)) * 0.08)
		mesh_fn.call(flower, petal, petal_mat, offset, Vector3.ONE, Vector3(0, angle, 0))


static func add_tree(parent: Node3D, pos: Vector3, scale_value: float, mats: Dictionary, mesh_fn: Callable) -> void:
	var tree: Node3D = Node3D.new()
	tree.position = pos
	tree.scale = Vector3.ONE * scale_value
	parent.add_child(tree)
	mesh_fn.call(tree, _cylinder(0.16, 1.05, 8), StylizedTypedAccess.material(mats, "wood", "wood"), Vector3(0, 0.52, 0))
	for offset in [Vector3(-0.42, 1.05, 0.08), Vector3(0.34, 1.28, -0.12), Vector3(0.02, 1.48, 0.18)]:
		var crown: PrismMesh = PrismMesh.new()
		crown.size = Vector3(0.95, 0.72, 0.82)
		mesh_fn.call(tree, crown, StylizedTypedAccess.material(mats, "leaf_green", "grass_light"), offset, Vector3.ONE, Vector3(-8, offset.x * 18.0, 6))
	var top: PrismMesh = PrismMesh.new()
	top.size = Vector3(0.72, 0.55, 0.68)
	mesh_fn.call(tree, top, StylizedTypedAccess.material(mats, "grass_light", "grass_light"), Vector3(0.0, 1.62, 0.0))


static func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh
