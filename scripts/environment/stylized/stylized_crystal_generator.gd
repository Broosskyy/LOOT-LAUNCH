extends RefCounted
class_name StylizedCrystalGenerator


static func add_cluster(parent: Node3D, pos: Vector3, scale_value: float, mats: Dictionary, mesh_fn: Callable, blue := false) -> void:
	var mat: Material = mats.get("crystal_blue", mats.crystal) if blue else mats.get("crystal_violet", mats.crystal)
	for data in [[Vector3(-0.22, 0, 0), -16.0], [Vector3(0.18, 0.08, 0.04), 14.0], [Vector3(0.0, -0.04, 0.2), 0.0], [Vector3(-0.08, 0.05, -0.12), 28.0]]:
		var prism := PrismMesh.new()
		prism.size = Vector3(0.42, 1.15, 0.36)
		mesh_fn.call(parent, prism, mat, pos + data[0], Vector3.ONE * scale_value, Vector3(0, 0, data[1]))
