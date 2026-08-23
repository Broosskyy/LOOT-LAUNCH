extends RefCounted
class_name StylizedCloudGenerator

const StylizedCloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")


static func build_sky(
	world: Node3D,
	quality_level: int,
	mats: Dictionary,
	rng: RandomNumberGenerator,
	mesh_fn: Callable,
	clouds_out: Array
) -> void:
	_add_cloud_bank(world, mats, mesh_fn, quality_level)
	var route_clouds := [
		[Vector3(-12.0, 2.0, -18.0), Vector3(5.5, 1.4, 2.4)],
		[Vector3(14.0, 6.0, -42.0), Vector3(6.2, 1.5, 2.6)],
		[Vector3(-18.0, 14.0, -78.0), Vector3(7.0, 1.7, 2.8)],
		[Vector3(20.0, 22.0, -118.0), Vector3(7.8, 1.8, 3.0)],
		[Vector3(-22.0, 32.0, -168.0), Vector3(8.4, 2.0, 3.2)],
		[Vector3(16.0, 42.0, -210.0), Vector3(9.0, 2.1, 3.4)],
	]
	var count := 2 if quality_level == 0 else 4 if quality_level == 1 else route_clouds.size()
	for data in route_clouds.slice(0, count):
		_add_cloud_cluster(world, data[0], data[1], mats, mesh_fn, clouds_out, rng)


static func _add_cloud_bank(world: Node3D, mats: Dictionary, mesh_fn: Callable, quality_level: int) -> void:
	if quality_level == 0:
		return
	var bank := Node3D.new()
	bank.name = "CloudBank"
	bank.position = Vector3(0.0, -28.0, -120.0)
	world.add_child(bank)
	for i in range(12):
		var puff := SphereMesh.new()
		puff.radius = 4.5 + float(i % 3) * 1.2
		puff.height = 3.2
		puff.radial_segments = 8
		puff.rings = 4
		var pos := Vector3(float(i % 4) * 14.0 - 21.0, sin(float(i) * 0.8) * 2.0, float(i / 4) * 18.0 - 24.0)
		mesh_fn.call(bank, puff, mats.get("cloud_soft", mats.white), pos, Vector3(1.4, 0.75, 1.1))


static func _add_cloud_cluster(
	world: Node3D,
	pos: Vector3,
	cloud_scale: Vector3,
	mats: Dictionary,
	mesh_fn: Callable,
	clouds_out: Array,
	rng: RandomNumberGenerator
) -> void:
	var root := Node3D.new()
	root.position = pos
	root.set_meta("origin", pos)
	root.set_meta("phase", rng.randf_range(0.0, 6.28))
	world.add_child(root)
	clouds_out.append(root)
	for offset in [Vector3(-1.2, 0.0, 0.0), Vector3(0.0, 0.35, -0.15), Vector3(1.1, -0.08, 0.12), Vector3(0.2, 0.15, 0.2)]:
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 8
		sphere.rings = 4
		mesh_fn.call(root, sphere, mats.get("cloud", mats.cloud), offset, cloud_scale)
