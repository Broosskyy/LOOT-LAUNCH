extends RefCounted
class_name StylizedCrystalGenerator

const StylizedHeroModels = preload("res://scripts/environment/stylized/stylized_hero_models.gd")


static func add_cluster(parent: Node3D, pos: Vector3, scale_value: float, mats: Dictionary, mesh_fn: Callable, blue: bool = false, hero_motion: bool = false) -> Node3D:
	return StylizedHeroModels.build_crystal_cluster(parent, pos, scale_value, mats, mesh_fn, blue, "cluster", hero_motion)
