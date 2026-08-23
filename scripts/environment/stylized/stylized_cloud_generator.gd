extends RefCounted
class_name StylizedCloudGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func build_sky(
	_world: Node3D,
	_quality_level: int,
	_mats: Dictionary,
	_rng: RandomNumberGenerator,
	_mesh_fn: Callable,
	_clouds_out: Array
) -> void:
	# V18.3: prefer a clean procedural sky over flat disc clouds.
	pass
