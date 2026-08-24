extends RefCounted
class_name StylizedWorldDecorator

const StylizedVegetationGenerator = preload("res://scripts/environment/stylized/stylized_vegetation_generator.gd")
const StylizedGroundRuinsKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")
const StylizedRuinGenerator = preload("res://scripts/environment/stylized/stylized_ruin_generator.gd")
const StylizedCrystalGenerator = preload("res://scripts/environment/stylized/stylized_crystal_generator.gd")
const StylizedPortalGenerator = preload("res://scripts/environment/stylized/stylized_portal_generator.gd")
const StylizedStartComposition = preload("res://scripts/environment/stylized/stylized_start_composition.gd")
const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


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
	for i in range(StylizedStartComposition.FLOWER_CLUSTERS.size()):
		StylizedVegetationGenerator.add_flower(parent, StylizedStartComposition.FLOWER_CLUSTERS[i], i % 2, mats, mesh_fn)
	for pos in StylizedStartComposition.GRASS_CLUSTERS:
		StylizedVegetationGenerator.add_grass_tuft(parent, pos, mats, mesh_fn, 1.0)
	StylizedVegetationGenerator.add_tree(parent, StylizedStartComposition.TREE_POS, 1.05, mats, mesh_fn)
	_add_teleport_pad(parent, mats, mesh_fn, transparent_fn)
	_add_decor_chest(parent, mats, mesh_fn, StylizedStartComposition.CHEST_POS)


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
	StylizedVegetationGenerator.add_tree(parent, Vector3(5.8, 0.0, 2.4), 0.92, mats, mesh_fn)
	for pos in [Vector3(2.2, 0.0, 3.4), Vector3(-3.8, 0.0, 3.0)]:
		StylizedVegetationGenerator.add_grass_tuft(parent, pos, mats, mesh_fn, 0.95)


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
	StylizedVegetationGenerator.add_tree(parent, Vector3(-spread, 0.0, 0.8), 0.82, mats, mesh_fn)


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


static func _add_teleport_pad(parent: Node3D, mats: Dictionary, mesh_fn: Callable, transparent_fn: Callable) -> void:
	var pad: BoxMesh = BoxMesh.new()
	pad.size = Vector3(1.55, 0.12, 1.55)
	mesh_fn.call(parent, pad, StylizedTypedAccess.material(mats, "portal", "portal"), StylizedStartComposition.PAD_POS + Vector3(0.0, 0.08, 0.0))
	var glow: CylinderMesh = CylinderMesh.new()
	glow.top_radius = 0.5
	glow.bottom_radius = 0.5
	glow.height = 0.04
	glow.radial_segments = 16
	var glow_mat: Material = StylizedTypedAccess.transparent_material(transparent_fn, Color(0.62, 0.35, 0.98, 0.38))
	mesh_fn.call(parent, glow, glow_mat, StylizedStartComposition.PAD_POS + Vector3(0.0, 0.15, 0.0), Vector3.ONE, Vector3(90, 0, 0))


static func _add_decor_chest(parent: Node3D, mats: Dictionary, mesh_fn: Callable, pos: Vector3) -> void:
	var chest: Node3D = Node3D.new()
	chest.position = pos
	parent.add_child(chest)
	var body: BoxMesh = BoxMesh.new()
	body.size = Vector3(1.15, 0.62, 0.82)
	mesh_fn.call(chest, body, StylizedTypedAccess.material(mats, "wood", "wood"), Vector3(0.0, 0.31, 0.0))
	var lid: BoxMesh = BoxMesh.new()
	lid.size = Vector3(1.2, 0.22, 0.86)
	mesh_fn.call(chest, lid, StylizedTypedAccess.material(mats, "wood_light", "wood_light"), Vector3(0.0, 0.66, -0.02), Vector3.ONE, Vector3(-12, 0, 0))
	var band: BoxMesh = BoxMesh.new()
	band.size = Vector3(1.22, 0.12, 0.88)
	mesh_fn.call(chest, band, StylizedTypedAccess.material(mats, "brass", "brass"), Vector3(0.0, 0.48, 0.0))
	var lock: BoxMesh = BoxMesh.new()
	lock.size = Vector3(0.18, 0.22, 0.1)
	mesh_fn.call(chest, lock, StylizedTypedAccess.material(mats, "brass", "brass"), Vector3(0.0, 0.48, 0.46))
