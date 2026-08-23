extends RefCounted
class_name StylizedCrystalGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func add_cluster(parent: Node3D, pos: Vector3, scale_value: float, mats: Dictionary, mesh_fn: Callable, blue: bool = false) -> void:
	var mat: Material = StylizedTypedAccess.material(mats, "crystal_blue" if blue else "crystal_violet", "crystal")
	var offsets: Array[Vector3] = [
		Vector3(-0.22, 0.0, 0.0),
		Vector3(0.18, 0.08, 0.04),
		Vector3(0.0, -0.04, 0.2),
		Vector3(-0.08, 0.05, -0.12),
	]
	var tilts: Array[float] = [-16.0, 14.0, 0.0, 28.0]
	for i in range(offsets.size()):
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(0.42, 1.15, 0.36)
		mesh_fn.call(parent, prism, mat, pos + offsets[i], Vector3.ONE * scale_value, Vector3(0.0, 0.0, tilts[i]))
