extends RefCounted
class_name StylizedPortalGenerator

const StylizedHeroModels = preload("res://scripts/environment/stylized/stylized_hero_models.gd")
const LandmarkGen = preload("res://scripts/environment/stylized/stylized_landmark_generator.gd")


static func build_portal(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array
) -> Node3D:
	return build_monument(parent, mats, mesh_fn, transparent_fn, animated_nodes, 1.0)


static func build_monument(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array,
	scale_value: float
) -> Node3D:
	return LandmarkGen.build_portal_monument_site(parent, mats, mesh_fn, transparent_fn, animated_nodes, scale_value, 4100, 2)
