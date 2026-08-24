extends RefCounted
class_name StylizedCloudGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const StylizedMotionController = preload("res://scripts/environment/stylized/stylized_motion_controller.gd")
const RenderEffects = preload("res://scripts/environment/stylized/stylized_render_effects.gd")

const MAX_PUFFS := 96
const MAX_CLOUD_ROOTS := 28

static var _puff_mesh: SphereMesh = null


static func build_sky(
	world: Node3D,
	quality_level: int,
	mats: Dictionary,
	rng: RandomNumberGenerator,
	mesh_fn: Callable,
	clouds_out: Array
) -> void:
	var profile: Dictionary = RenderEffects.quality_profile(quality_level)
	var mat_low: Material = StylizedTypedAccess.material(mats, "cloud_shadow", "cloud_shadow")
	var mat_mid: Material = StylizedTypedAccess.material(mats, "cloud_mid", "cloud_mid")
	var mat_high: Material = StylizedTypedAccess.material(mats, "cloud_soft", "cloud_soft")
	var mat_far: Material = StylizedTypedAccess.material(mats, "cloud_far", "cloud_far")
	var puff_count := 0
	var root_count := 0
	var bank_layout: Array = [
		[Vector3(-20.0, -34.0, -18.0), Vector3(5.6, 1.05, 3.8), 9, mat_low, 0],
		[Vector3(14.0, -32.0, -38.0), Vector3(6.4, 1.12, 4.0), 10, mat_low, 0],
		[Vector3(-2.0, -36.0, -58.0), Vector3(7.8, 1.18, 4.6), 11, mat_low, 0],
		[Vector3(-28.0, -33.0, -74.0), Vector3(5.8, 1.05, 3.8), 9, mat_low, 0],
		[Vector3(24.0, -35.0, -48.0), Vector3(5.2, 1.0, 3.4), 8, mat_low, 0],
		[Vector3(6.0, -37.0, -92.0), Vector3(6.8, 1.1, 4.2), 10, mat_low, 0],
	]
	var bank_limit: int = int(profile.cloud_bank_clusters)
	for data in bank_layout.slice(0, bank_limit):
		if puff_count >= MAX_PUFFS or root_count >= MAX_CLOUD_ROOTS:
			break
		puff_count += _add_cluster(world, data[0], data[1], int(data[2]), data[3], int(data[4]), rng, mesh_fn, clouds_out)
		root_count += 1
	var mid_layout: Array = [
		[Vector3(6.0, 10.0, -32.0), Vector3(3.4, 0.98, 2.8), 7, mat_mid, 1],
		[Vector3(-12.0, 16.0, -52.0), Vector3(3.6, 1.02, 3.0), 8, mat_mid, 1],
		[Vector3(10.0, 22.0, -78.0), Vector3(4.0, 1.05, 3.2), 8, mat_high, 1],
		[Vector3(-6.0, 30.0, -108.0), Vector3(4.2, 1.05, 3.4), 7, mat_high, 1],
		[Vector3(4.0, 38.0, -138.0), Vector3(4.6, 1.0, 3.6), 6, mat_high, 1],
	]
	var mid_limit: int = int(profile.cloud_mid_clusters)
	for data in mid_layout.slice(0, mid_limit):
		if puff_count >= MAX_PUFFS or root_count >= MAX_CLOUD_ROOTS:
			break
		puff_count += _add_cluster(world, data[0], data[1], int(data[2]), data[3], int(data[4]), rng, mesh_fn, clouds_out)
		root_count += 1
	var far_layout: Array = [
		[Vector3(0.0, 48.0, -165.0), Vector3(5.4, 0.92, 4.0), 5, mat_far, 2],
		[Vector3(-18.0, 52.0, -195.0), Vector3(5.0, 0.88, 3.6), 4, mat_far, 2],
		[Vector3(20.0, 46.0, -220.0), Vector3(5.8, 0.90, 4.2), 5, mat_far, 2],
	]
	var far_limit: int = int(profile.cloud_far_clusters)
	for data in far_layout.slice(0, far_limit):
		if puff_count >= MAX_PUFFS or root_count >= MAX_CLOUD_ROOTS:
			break
		puff_count += _add_cluster(world, data[0], data[1], int(data[2]), data[3], int(data[4]), rng, mesh_fn, clouds_out)
		root_count += 1
	if quality_level == 0 and puff_count < MAX_PUFFS:
		puff_count += _add_cluster(world, Vector3(0.0, 40.0, -150.0), Vector3(4.8, 0.95, 3.6), 4, mat_high, 2, rng, mesh_fn, clouds_out)
	world.set_meta("v24_cloud_puff_count", puff_count)
	world.set_meta("v24_cloud_root_count", clouds_out.size())
	world.set_meta("v36_cloud_puff_count", puff_count)
	world.set_meta("v39_cloud_puff_count", puff_count)
	world.set_meta("v39_cloud_root_count", clouds_out.size())


static func count_puffs_in_world(world: Node) -> int:
	if world.has_meta("v39_cloud_puff_count"):
		return int(world.get_meta("v39_cloud_puff_count"))
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
	depth_layer: int,
	rng: RandomNumberGenerator,
	mesh_fn: Callable,
	clouds_out: Array
) -> int:
	var root := Node3D.new()
	root.name = "CloudCluster%02d" % clouds_out.size()
	root.position = pos
	root.set_meta("origin", pos)
	root.set_meta("phase", rng.randf_range(0.0, TAU))
	root.set_meta("drift_depth", depth_layer)
	root.set_meta("drift_speed", StylizedMotionController.cloud_drift_speed(depth_layer))
	parent.add_child(root)
	clouds_out.append(root)
	var mesh := _puff_mesh_instance()
	var added := 0
	var depth_tint: float = float(depth_layer) / 2.0
	for i in puff_total:
		if added >= MAX_PUFFS:
			break
		var offset := Vector3(
			rng.randf_range(-2.8, 2.8),
			rng.randf_range(-0.32, 0.42),
			rng.randf_range(-1.5, 1.5)
		)
		var scale_jitter := rng.randf_range(0.82, 1.18)
		var puff_scale := Vector3(
			rng.randf_range(1.6, 3.8) * base_scale.x * scale_jitter,
			rng.randf_range(0.42, 0.88) * base_scale.y,
			rng.randf_range(1.4, 3.4) * base_scale.z * scale_jitter
		)
		var instance: MeshInstance3D = mesh_fn.call(root, mesh, cloud_mat, offset, puff_scale) as MeshInstance3D
		if instance != null:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		added += 1
		if i % 2 == 0 and added < puff_total:
			var accent_offset := offset + Vector3(rng.randf_range(-0.6, 0.6), 0.14, rng.randf_range(-0.5, 0.5))
			var accent_scale := puff_scale * Vector3(0.52, 0.38, 0.52)
			var accent: MeshInstance3D = mesh_fn.call(root, mesh, cloud_mat, accent_offset, accent_scale) as MeshInstance3D
			if accent != null:
				accent.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			added += 1
	return added
