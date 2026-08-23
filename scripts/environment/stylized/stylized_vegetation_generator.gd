extends RefCounted
class_name StylizedVegetationGenerator


static func add_grass_tuft(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, scale_value := 1.0) -> void:
	var tuft := Node3D.new()
	tuft.position = pos
	parent.add_child(tuft)
	for i in range(3):
		var blade := PrismMesh.new()
		blade.size = Vector3(0.12, 0.42 + i * 0.06, 0.08) * scale_value
		mesh_fn.call(tuft, blade, mats.get("grass_light", mats.grass_light),
			Vector3((i - 1) * 0.12, 0.18, 0.0), Vector3.ONE, Vector3(0, 0, -14.0 + i * 14.0))


static func add_flower(parent: Node3D, pos: Vector3, variant: int, mats: Dictionary, mesh_fn: Callable) -> void:
	var flower := Node3D.new()
	flower.position = pos
	parent.add_child(flower)
	mesh_fn.call(flower, _cylinder(0.03, 0.28, 6), mats.get("grass_dark", mats.grass), Vector3(0, 0.14, 0))
	var petal_mat: Material = mats.get("flower_pink", mats.flower_pink) if variant == 0 else mats.get("flower_white", mats.white)
	for angle in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var petal := SphereMesh.new()
		petal.radius = 0.08
		petal.height = 0.12
		var offset := Vector3(cos(deg_to_rad(angle)) * 0.08, 0.32, sin(deg_to_rad(angle)) * 0.08)
		mesh_fn.call(flower, petal, petal_mat, offset, Vector3(1.1, 0.55, 0.9))


static func add_tree(parent: Node3D, pos: Vector3, scale_value: float, mats: Dictionary, mesh_fn: Callable) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.scale = Vector3.ONE * scale_value
	parent.add_child(tree)
	mesh_fn.call(tree, _cylinder(0.18, 1.1, 8), mats.get("wood", mats.wood), Vector3(0, 0.55, 0))
	for offset in [Vector3(-0.35, 1.15, 0.1), Vector3(0.3, 1.35, -0.15), Vector3(0.05, 1.55, 0.2)]:
		var crown := SphereMesh.new()
		crown.radius = 0.55
		crown.height = 0.9
		crown.radial_segments = 8
		crown.rings = 4
		mesh_fn.call(tree, crown, mats.get("leaf_green", mats.grass_light), offset, Vector3(1.1, 0.85, 1.0))


static func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh
