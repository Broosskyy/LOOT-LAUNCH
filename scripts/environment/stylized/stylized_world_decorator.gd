extends RefCounted
class_name StylizedWorldDecorator

const StylizedVegetationGenerator = preload("res://scripts/environment/stylized/stylized_vegetation_generator.gd")
const StylizedGroundRuinsKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")
const StylizedRuinGenerator = preload("res://scripts/environment/stylized/stylized_ruin_generator.gd")
const StylizedCrystalGenerator = preload("res://scripts/environment/stylized/stylized_crystal_generator.gd")
const StylizedPortalGenerator = preload("res://scripts/environment/stylized/stylized_portal_generator.gd")
const StylizedStartComposition = preload("res://scripts/environment/stylized/stylized_start_composition.gd")
const StylizedHeroModels = preload("res://scripts/environment/stylized/stylized_hero_models.gd")


static func decorate_start_island(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	_rng: RandomNumberGenerator,
	_radius: float
) -> void:
	StylizedGroundRuinsKit.place_path_stones(parent, StylizedStartComposition.PATH_STONES, mats, mesh_fn, 1200)
	StylizedGroundRuinsKit.add_corner_ruin(parent, StylizedStartComposition.CORNER_RUIN_POS, -18.0, mats, mesh_fn, 2201)
	StylizedGroundRuinsKit.add_pillar(parent, StylizedStartComposition.PILLAR_POS, 14.0, mats, mesh_fn, true, 2402)
	StylizedGroundRuinsKit.add_plinth(parent, StylizedStartComposition.PLINTH_POS, 8.0, mats, mesh_fn, 2503)
	StylizedGroundRuinsKit.add_rubble_cluster(parent, Vector3(-4.6, 0.0, 1.2), mats, mesh_fn, 2604, 4)
	StylizedGroundRuinsKit.add_edge_stones(parent, StylizedStartComposition.EDGE_STONES, mats, mesh_fn, 2705)
	StylizedRuinGenerator.add_signpost(parent, StylizedStartComposition.SIGN_POS, mats, mesh_fn)
	StylizedCrystalGenerator.add_cluster(parent, StylizedStartComposition.CRYSTAL_POS, 0.82, mats, mesh_fn)
	_add_teleport_pad(parent, mats, mesh_fn, transparent_fn)
	_add_decor_chest(parent, mats, mesh_fn, StylizedStartComposition.CHEST_POS)
	StylizedVegetationGenerator.dress_start_island(parent, mats, mesh_fn)


static func decorate_hero_midground(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array
) -> void:
	StylizedGroundRuinsKit.add_stair_segment(parent, Vector3(0.0, 0.0, 4.2), 8.0, mats, mesh_fn, 4, 3301)
	StylizedGroundRuinsKit.add_arch_fragment(parent, Vector3(3.4, 0.0, 4.6), -12.0, mats, mesh_fn, 4101)
	var portal_root: Node3D = Node3D.new()
	portal_root.position = Vector3(-0.5, 0.0, 5.8)
	portal_root.rotation_degrees.y = 8.0
	parent.add_child(portal_root)
	StylizedPortalGenerator.build_monument(portal_root, mats, mesh_fn, transparent_fn, animated_nodes, 1.35)
	StylizedCrystalGenerator.add_cluster(parent, Vector3(4.2, 0.0, 4.8), 0.95, mats, mesh_fn)
	StylizedVegetationGenerator.dress_hero_midground(parent, mats, mesh_fn)


static func decorate_playable_island(
	parent: Node3D,
	island_index: int,
	mats: Dictionary,
	mesh_fn: Callable,
	_rng: RandomNumberGenerator,
	radius: float
) -> void:
	if island_index == 1:
		return
	var spread: float = radius * 0.42
	match island_index:
		2:
			StylizedGroundRuinsKit.add_wall_segment(parent, Vector3(-spread * 0.7, 0.0, 1.2), 22.0, mats, mesh_fn, true, 5100 + island_index)
		3:
			StylizedGroundRuinsKit.add_pillar(parent, Vector3(spread * 0.55, 0.0, 0.4), -16.0, mats, mesh_fn, true, 5200 + island_index)
		4:
			StylizedGroundRuinsKit.add_stair_segment(parent, Vector3(-0.4, 0.0, 2.0), 0.0, mats, mesh_fn, 3, 5300 + island_index)
			StylizedGroundRuinsKit.add_plinth(parent, Vector3(spread * 0.35, 0.0, -0.8), 12.0, mats, mesh_fn, 5310 + island_index)
		5:
			StylizedGroundRuinsKit.add_arch_fragment(parent, Vector3(-spread * 0.45, 0.0, 1.6), 18.0, mats, mesh_fn, 5400 + island_index)
	StylizedVegetationGenerator.dress_playable_island(parent, island_index, radius, mats, mesh_fn)


static func decorate_target_island(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	radius: float,
	island_index: int = -1
) -> void:
	match island_index:
		2:
			StylizedGroundRuinsKit.add_wall_segment(parent, Vector3(-radius * 0.32, 0.0, 1.2), 22.0, mats, mesh_fn, true, 5100 + island_index)
		3:
			StylizedGroundRuinsKit.add_pillar(parent, Vector3(radius * 0.28, 0.0, 0.4), -16.0, mats, mesh_fn, true, 5200 + island_index)
		4:
			StylizedGroundRuinsKit.add_stair_segment(parent, Vector3(-0.4, 0.0, 2.0), 0.0, mats, mesh_fn, 3, 5300 + island_index)
			StylizedGroundRuinsKit.add_plinth(parent, Vector3(radius * 0.22, 0.0, -0.8), 12.0, mats, mesh_fn, 5310 + island_index)
		5:
			StylizedGroundRuinsKit.add_arch_fragment(parent, Vector3(-radius * 0.3, 0.0, 1.6), 18.0, mats, mesh_fn, 5400 + island_index)
	StylizedGroundRuinsKit.add_rubble_cluster(parent, Vector3(-radius * 0.18, 0.0, 1.4), mats, mesh_fn, 6000 + int(radius * 10.0), 3)
	StylizedVegetationGenerator.dress_target_island(parent, radius, island_index, mats, mesh_fn)


static func _add_teleport_pad(parent: Node3D, mats: Dictionary, mesh_fn: Callable, transparent_fn: Callable) -> void:
	StylizedHeroModels.build_pad(parent, StylizedStartComposition.PAD_POS, mats, mesh_fn, transparent_fn)


static func _add_decor_chest(parent: Node3D, mats: Dictionary, mesh_fn: Callable, pos: Vector3) -> void:
	StylizedHeroModels.build_chest(parent, pos, mats, mesh_fn)
