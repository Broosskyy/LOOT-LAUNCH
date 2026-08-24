extends RefCounted
class_name StylizedCloudGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")

const MAX_PUFFS := 96
const MAX_CLOUD_ROOTS := 24

static var _puff_mesh: SphereMesh = null


static func build_sky(
	world: Node3D,
	quality_level: int,
	mats: Dictionary,
	rng: RandomNumberGenerator,
	mesh_fn: Callable,
	clouds_out: Array
) -> void:
	var cloud_mat: Material = StylizedTypedAccess.material(mats, "cloud", "cloud_soft")
	var puff_count := 0
	var root_count := 0
	if quality_level >= 1:
		var bank_layout: Array = [
			[Vector3(-18.0, -32.0, -15.0), Vector3(4.2, 1.2, 3.0), 6],
			[Vector3(12.0, -30.0, -35.0), Vector3(5.0, 1.3, 3.4), 7],
			[Vector3(0.0, -34.0, -55.0), Vector3(6.2, 1.4, 4.0), 8],
			[Vector3(-25.0, -31.0, -70.0), Vector3(4.6, 1.2, 3.2), 6],
			[Vector3(22.0, -33.0, -45.0), Vector3(4.0, 1.1, 2.8), 5],
		]
		var bank_limit := 2 if quality_level == 1 else bank_layout.size()
		for data in bank_layout.slice(0, bank_limit):
			puff_count += _add_cluster(world, data[0], data[1], int(data[2]), cloud_mat, rng, mesh_fn, clouds_out)
			root_count += 1
	var mid_layout: Array = [
		[Vector3(5.0, 8.0, -28.0), Vector3(2.5, 1.0, 2.0), 5],
		[Vector3(-10.0, 14.0, -48.0), Vector3(2.8, 1.1, 2.2), 5],
		[Vector3(8.0, 20.0, -75.0), Vector3(3.0, 1.2, 2.5), 6],
		[Vector3(-5.0, 28.0, -110.0), Vector3(3.2, 1.2, 2.8), 5],
	]
	var mid_limit := 0
	if quality_level == 0:
		mid_limit = 1
	elif quality_level == 1:
		mid_limit = 2
	else:
		mid_limit = mid_layout.size()
	for data in mid_layout.slice(0, mid_limit):
		if puff_count >= MAX_PUFFS or root_count >= MAX_CLOUD_ROOTS:
			break
		puff_count += _add_cluster(world, data[0], data[1], int(data[2]), cloud_mat, rng, mesh_fn, clouds_out)
		root_count += 1
	if quality_level == 0:
		puff_count += _add_cluster(world, Vector3(0.0, 35.0, -140.0), Vector3(4.0, 1.0, 3.0), 3, cloud_mat, rng, mesh_fn, clouds_out)
	world.set_meta("v24_cloud_puff_count", puff_count)
	world.set_meta("v24_cloud_root_count", clouds_out.size())


static func count_puffs_in_world(world: Node) -> int:
	if world.has_meta("v24_cloud_puff_count"):
		return int(world.get_meta("v24_cloud_puff_count"))
	return 0


static func _puff_mesh_instance() -> SphereMesh:
	if _puff_mesh == null:
		_puff_mesh = SphereMesh.new()
		_puff_mesh.radial_segments = 8
		_puff_mesh.rings = 6
		_puff_mesh.radius = 1.0
		_puff_mesh.height = 2.0
	return _puff_mesh


static func _add_cluster(
	parent: Node3D,
	pos: Vector3,
	base_scale: Vector3,
	puff_total: int,
	cloud_mat: Material,
	rng: RandomNumberGenerator,
	mesh_fn: Callable,
	clouds_out: Array
) -> int:
	var root := Node3D.new()
	root.name = "CloudCluster%02d" % clouds_out.size()
	root.position = pos
	root.set_meta("origin", pos)
	root.set_meta("phase", rng.randf_range(0.0, TAU))
	parent.add_child(root)
	clouds_out.append(root)
	var mesh := _puff_mesh_instance()
	var added := 0
	for i in puff_total:
		if added >= MAX_PUFFS:
			break
		var offset := Vector3(
			rng.randf_range(-1.8, 1.8),
			rng.randf_range(-0.35, 0.45),
			rng.randf_range(-0.9, 0.9)
		)
		var puff_scale := Vector3(
			rng.randf_range(1.6, 3.2) * base_scale.x,
			rng.randf_range(0.55, 1.0) * base_scale.y,
			rng.randf_range(1.4, 2.8) * base_scale.z
		)
		var instance: MeshInstance3D = mesh_fn.call(root, mesh, cloud_mat, offset, puff_scale) as MeshInstance3D
		if instance != null:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		added += 1
	return added
