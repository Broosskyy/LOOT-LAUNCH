extends RefCounted
class_name StylizedWorldDecorator

const StylizedVegetationGenerator = preload("res://scripts/environment/stylized/stylized_vegetation_generator.gd")
const StylizedRuinGenerator = preload("res://scripts/environment/stylized/stylized_ruin_generator.gd")
const StylizedCrystalGenerator = preload("res://scripts/environment/stylized/stylized_crystal_generator.gd")


static func decorate_start_island(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	rng: RandomNumberGenerator,
	radius: float
) -> void:
	_build_stone_path(parent, mats, mesh_fn)
	StylizedRuinGenerator.add_broken_wall(parent, Vector3(-5.8, 0.0, 3.6), mats, mesh_fn)
	StylizedRuinGenerator.add_signpost(parent, Vector3(3.8, 0.0, 4.2), mats, mesh_fn)
	StylizedCrystalGenerator.add_cluster(parent, Vector3(-4.2, 0.0, -2.8), 0.88, mats, mesh_fn)
	StylizedCrystalGenerator.add_cluster(parent, Vector3(5.4, 0.0, 1.8), 0.72, mats, mesh_fn, true)
	for pos in [Vector3(-2.8, 0.0, 4.5), Vector3(1.2, 0.0, 5.0), Vector3(4.6, 0.0, 3.1), Vector3(-5.2, 0.0, 1.2)]:
		StylizedVegetationGenerator.add_flower(parent, pos, rng.randi_range(0, 1), mats, mesh_fn)
	for pos in [Vector3(-3.2, 0.0, 2.8), Vector3(0.8, 0.0, 3.6), Vector3(3.5, 0.0, 2.2), Vector3(-1.5, 0.0, 5.2), Vector3(5.8, 0.0, -0.8)]:
		StylizedVegetationGenerator.add_grass_tuft(parent, pos, mats, mesh_fn, rng.randf_range(0.85, 1.15))
	for pos in [Vector3(2.2, 0.0, 0.5), Vector3(-1.8, 0.0, -1.2), Vector3(4.8, 0.0, 2.8), Vector3(-4.5, 0.0, -0.4)]:
		var pebble := PrismMesh.new()
		pebble.size = Vector3(rng.randf_range(0.35, 0.65), rng.randf_range(0.2, 0.35), rng.randf_range(0.3, 0.55))
		mesh_fn.call(parent, pebble, mats.get("stone_main", mats.rock), pos + Vector3(0, 0.12, 0), Vector3.ONE,
			Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(0.0, 360.0), rng.randf_range(-10.0, 10.0)))
	StylizedVegetationGenerator.add_tree(parent, Vector3(-radius * 0.42, 0.0, 0.4), 0.95, mats, mesh_fn)
	StylizedVegetationGenerator.add_tree(parent, Vector3(radius * 0.44, 0.0, 1.6), 0.82, mats, mesh_fn)
	_add_teleport_pad(parent, mats, mesh_fn, transparent_fn)
	_add_decor_chest(parent, mats, mesh_fn)


static func decorate_playable_island(
	parent: Node3D,
	island_index: int,
	mats: Dictionary,
	mesh_fn: Callable,
	rng: RandomNumberGenerator,
	radius: float
) -> void:
	var spread := radius * 0.44
	StylizedVegetationGenerator.add_tree(parent, Vector3(-spread, 0.0, 0.6), 0.88, mats, mesh_fn)
	StylizedVegetationGenerator.add_tree(parent, Vector3(spread, 0.0, 1.4), 0.78, mats, mesh_fn)
	for i in range(4):
		var z := 2.2 - i * 0.7
		var stone := PrismMesh.new()
		stone.size = Vector3(0.9, 0.1, 0.72)
		mesh_fn.call(parent, stone, mats.get("stone_light", mats.white), Vector3(sin(i * 1.1) * 0.25, 0.12, z), Vector3.ONE, Vector3(0, i * 22.0, 0))
	StylizedCrystalGenerator.add_cluster(parent, Vector3(sin(island_index) * 3.0, 0.0, 4.2), 0.62, mats, mesh_fn, island_index % 2 == 0)


static func decorate_target_island(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	radius: float
) -> void:
	StylizedRuinGenerator.add_stone_steps(parent, Vector3(0.0, 0.0, 3.8), mats, mesh_fn, 3)
	StylizedVegetationGenerator.add_grass_tuft(parent, Vector3(-radius * 0.3, 0.0, 2.0), mats, mesh_fn)


static func _build_stone_path(parent: Node3D, mats: Dictionary, mesh_fn: Callable) -> void:
	for i in range(8):
		var z := 2.6 - i * 0.72
		var stone := PrismMesh.new()
		stone.size = Vector3(0.95 + (i % 2) * 0.12, 0.1, 0.78)
		var mat: Material = mats.get("stone_light", mats.white) if i % 2 == 0 else mats.get("stone_main", mats.rock)
		mesh_fn.call(parent, stone, mat, Vector3(sin(i * 0.95) * 0.22, 0.12, z), Vector3(1.0, 1.0, 0.82), Vector3(0, i * 19.0, 0))


static func _add_teleport_pad(parent: Node3D, mats: Dictionary, mesh_fn: Callable, transparent_fn: Callable) -> void:
	var pad := BoxMesh.new()
	pad.size = Vector3(1.65, 0.12, 1.65)
	mesh_fn.call(parent, pad, mats.get("portal", mats.portal), Vector3(-2.1, 0.08, 1.6))
	var glow := CylinderMesh.new()
	glow.top_radius = 0.55
	glow.bottom_radius = 0.55
	glow.height = 0.04
	glow.radial_segments = 16
	mesh_fn.call(parent, glow, transparent_fn.call(Color(0.62, 0.35, 0.98, 0.42)), Vector3(-2.1, 0.16, 1.6), Vector3.ONE, Vector3(90, 0, 0))


static func _add_decor_chest(parent: Node3D, mats: Dictionary, mesh_fn: Callable) -> void:
	var chest := Node3D.new()
	chest.position = Vector3(5.2, 0.66, 3.4)
	parent.add_child(chest)
	var box := BoxMesh.new()
	box.size = Vector3(1.4, 0.72, 1.0)
	mesh_fn.call(chest, box, mats.get("wood_light", mats.wood_light), Vector3(0, 0.36, 0))
	mesh_fn.call(chest, box, mats.get("brass", mats.brass), Vector3(0, 0.08, 0), Vector3(1.2, 0.2, 1.05))
