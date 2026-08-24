extends RefCounted
class_name StylizedCloudGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const StylizedMotionController = preload("res://scripts/environment/stylized/stylized_motion_controller.gd")
const EnvironmentRender = preload("res://scripts/environment/stylized/stylized_environment_render.gd")

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
	var profile: Dictionary = EnvironmentRender.quality_profile(quality_level)
	var mat_soft: Material = StylizedTypedAccess.material(mats, "cloud", "cloud_soft")
	var mat_mid: Material = StylizedTypedAccess.material(mats, "cloud_mid", "cloud_mid")
	var mat_shadow: Material = StylizedTypedAccess.material(mats, "cloud_shadow", "cloud_shadow")
	var puff_count := 0
	var root_count := 0
	var bank_layout: Array = [
		[Vector3(-18.0, -32.0, -15.0), Vector3(5.2, 1.0, 3.6), 8, mat_shadow],
		[Vector3(12.0, -30.0, -35.0), Vector3(6.0, 1.1, 3.8), 9, mat_shadow],
		[Vector3(0.0, -34.0, -55.0), Vector3(7.4, 1.2, 4.4), 10, mat_shadow],
		[Vector3(-25.0, -31.0, -70.0), Vector3(5.6, 1.0, 3.6), 8, mat_shadow],
		[Vector3(22.0, -33.0, -45.0), Vector3(5.0, 1.0, 3.2), 7, mat_shadow],
	]
	var bank_limit: int = int(profile.cloud_bank_clusters)
	for data in bank_layout.slice(0, bank_limit):
		if puff_count >= MAX_PUFFS or root_count >= MAX_CLOUD_ROOTS:
			break
		puff_count += _add_cluster(world, data[0], data[1], int(data[2]), data[3], rng, mesh_fn, clouds_out)
		root_count += 1
	var mid_layout: Array = [
		[Vector3(5.0, 8.0, -28.0), Vector3(3.2, 0.95, 2.6), 6, mat_mid],
		[Vector3(-10.0, 14.0, -48.0), Vector3(3.4, 1.0, 2.8), 7, mat_mid],
		[Vector3(8.0, 20.0, -75.0), Vector3(3.8, 1.05, 3.0), 7, mat_soft],
		[Vector3(-5.0, 28.0, -110.0), Vector3(4.0, 1.05, 3.2), 6, mat_soft],
	]
	var mid_limit: int = int(profile.cloud_mid_clusters)
	for data in mid_layout.slice(0, mid_limit):
		if puff_count >= MAX_PUFFS or root_count >= MAX_CLOUD_ROOTS:
			break
		puff_count += _add_cluster(world, data[0], data[1], int(data[2]), data[3], rng, mesh_fn, clouds_out)
		root_count += 1
	if quality_level == 0 and puff_count < MAX_PUFFS:
		puff_count += _add_cluster(world, Vector3(0.0, 35.0, -140.0), Vector3(4.6, 0.95, 3.4), 4, mat_soft, rng, mesh_fn, clouds_out)
	world.set_meta("v24_cloud_puff_count", puff_count)
	world.set_meta("v24_cloud_root_count", clouds_out.size())
	world.set_meta("v36_cloud_puff_count", puff_count)


static func count_puffs_in_world(world: Node) -> int:
	if world.has_meta("v36_cloud_puff_count"):
		return int(world.get_meta("v36_cloud_puff_count"))
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
	var depth_layer: int = 0 if pos.y < 0.0 else 1 if pos.y < 25.0 else 2
	root.set_meta("drift_depth", depth_layer)
	root.set_meta("drift_speed", StylizedMotionController.cloud_drift_speed(depth_layer))
	parent.add_child(root)
	clouds_out.append(root)
	var mesh := _puff_mesh_instance()
	var added := 0
	for i in puff_total:
		if added >= MAX_PUFFS:
			break
		var offset := Vector3(
			rng.randf_range(-2.4, 2.4),
			rng.randf_range(-0.28, 0.38),
			rng.randf_range(-1.2, 1.2)
		)
		var puff_scale := Vector3(
			rng.randf_range(1.8, 3.6) * base_scale.x,
			rng.randf_range(0.45, 0.85) * base_scale.y,
			rng.randf_range(1.6, 3.2) * base_scale.z
		)
		var instance: MeshInstance3D = mesh_fn.call(root, mesh, cloud_mat, offset, puff_scale) as MeshInstance3D
		if instance != null:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		added += 1
		if i % 2 == 0 and added < puff_total:
			var accent_offset := offset + Vector3(rng.randf_range(-0.5, 0.5), 0.12, rng.randf_range(-0.4, 0.4))
			var accent_scale := puff_scale * Vector3(0.55, 0.42, 0.55)
			var accent: MeshInstance3D = mesh_fn.call(root, mesh, cloud_mat, accent_offset, accent_scale) as MeshInstance3D
			if accent != null:
				accent.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			added += 1
	return added
