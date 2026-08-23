extends RefCounted
class_name StylizedCloudGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func build_sky(
	world: Node3D,
	quality_level: int,
	mats: Dictionary,
	rng: RandomNumberGenerator,
	mesh_fn: Callable,
	clouds_out: Array
) -> void:
	_add_cloud_bank(world, mats, mesh_fn, quality_level)
	var route_positions: Array[Vector3] = [
		Vector3(-10.0, 1.0, -16.0),
		Vector3(12.0, 5.0, -34.0),
		Vector3(-16.0, 12.0, -62.0),
		Vector3(18.0, 18.0, -92.0),
		Vector3(-20.0, 26.0, -128.0),
		Vector3(14.0, 34.0, -168.0),
	]
	var route_scales: Array[Vector3] = [
		Vector3(5.2, 1.3, 2.2),
		Vector3(6.0, 1.5, 2.5),
		Vector3(6.8, 1.6, 2.8),
		Vector3(7.4, 1.7, 3.0),
		Vector3(8.2, 1.8, 3.2),
		Vector3(9.0, 2.0, 3.4),
	]
	var count: int = 2 if quality_level == 0 else 4 if quality_level == 1 else route_positions.size()
	for i in range(count):
		_add_cloud_cluster(world, route_positions[i], route_scales[i], mats, mesh_fn, clouds_out, rng)


static func _add_cloud_bank(world: Node3D, mats: Dictionary, mesh_fn: Callable, quality_level: int) -> void:
	if quality_level == 0:
		return
	var bank: Node3D = Node3D.new()
	bank.name = "CloudBank"
	bank.position = Vector3(0.0, -18.0, -72.0)
	world.add_child(bank)
	for i in range(20):
		var puff: SphereMesh = SphereMesh.new()
		puff.radius = 2.6 + float(i % 5) * 0.85
		puff.height = 2.2 + float(i % 3) * 0.4
		puff.radial_segments = 10
		puff.rings = 5
		var pos: Vector3 = Vector3(float(i % 6) * 10.0 - 25.0, sin(float(i) * 0.65) * 1.2, float(i / 6) * 11.0 - 22.0)
		mesh_fn.call(bank, puff, StylizedTypedAccess.material(mats, "cloud_soft", "cloud_soft"), pos, Vector3(1.35, 0.95, 1.05))


static func _add_cloud_cluster(
	world: Node3D,
	pos: Vector3,
	cloud_scale: Vector3,
	mats: Dictionary,
	mesh_fn: Callable,
	clouds_out: Array,
	rng: RandomNumberGenerator
) -> void:
	var root: Node3D = Node3D.new()
	root.position = pos
	root.set_meta("origin", pos)
	root.set_meta("phase", rng.randf_range(0.0, 6.28))
	world.add_child(root)
	clouds_out.append(root)
	var offsets: Array[Vector3] = [
		Vector3(-1.4, 0.0, 0.0),
		Vector3(-0.4, 0.25, -0.1),
		Vector3(0.5, 0.1, 0.15),
		Vector3(1.3, -0.05, -0.05),
		Vector3(0.1, 0.35, 0.25),
	]
	var scales: Array[Vector3] = [
		Vector3(1.2, 0.8, 0.9),
		Vector3(0.9, 0.7, 0.8),
		Vector3(1.0, 0.75, 0.85),
		Vector3(1.1, 0.78, 0.88),
		Vector3(0.75, 0.65, 0.72),
	]
	for i in range(offsets.size()):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 1.8
		sphere.radial_segments = 8
		sphere.rings = 4
		var mat_key: String = "cloud_soft" if i % 2 == 0 else "cloud_mid"
		mesh_fn.call(root, sphere, StylizedTypedAccess.material(mats, mat_key, "cloud_soft"), offsets[i], cloud_scale * scales[i])
