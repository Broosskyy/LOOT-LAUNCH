extends RefCounted
class_name V41VegetationKit

## V41 — Benchmark vegetation set (grass, flowers, bush, trees, hero tree).

const VegGen = preload("res://scripts/environment/stylized/stylized_vegetation_generator.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")

enum VegKind {
	GRASS_SMALL,
	GRASS_MEDIUM,
	BROAD_LEAF,
	FLOWER,
	BUSH,
	TREE_SMALL,
	TREE_MEDIUM,
	HERO_TREE,
}


static func place(
	parent: Node3D,
	kind: int,
	pos: Vector3,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	scale_value: float = 1.0
) -> void:
	match kind:
		VegKind.GRASS_SMALL:
			VegGen.create_grass_multimesh_patch(parent, pos, 0.55 * scale_value, 6, seed, mats, VegGen.GrassVariant.SHORT)
		VegKind.GRASS_MEDIUM:
			VegGen.create_grass_multimesh_patch(parent, pos, 0.75 * scale_value, 9, seed, mats, VegGen.GrassVariant.MEDIUM)
		VegKind.BROAD_LEAF:
			_place_broad_leaf(parent, pos, seed, mats, mesh_fn, scale_value)
		VegKind.FLOWER:
			VegGen.create_flower_cluster(parent, pos, VegGen.FlowerPreset.PINK_CLUSTER, seed, mats, mesh_fn)
		VegKind.BUSH:
			VegGen.create_shrub(parent, pos, scale_value, seed, mats, mesh_fn)
		VegKind.TREE_SMALL:
			VegGen.create_tree(parent, pos, VegGen.TreeVariant.TREE_C, scale_value * 0.85, seed, mats, mesh_fn)
		VegKind.TREE_MEDIUM:
			VegGen.create_tree(parent, pos, VegGen.TreeVariant.TREE_B, scale_value, seed, mats, mesh_fn)
		VegKind.HERO_TREE:
			_place_hero_tree(parent, pos, seed, mats, mesh_fn, scale_value)


static func _place_broad_leaf(parent: Node3D, pos: Vector3, seed: int, mats: Dictionary, mesh_fn: Callable, scale_value: float) -> void:
	var plant := Node3D.new()
	plant.name = "BroadLeaf"
	plant.position = pos
	plant.scale = Vector3.ONE * scale_value
	parent.add_child(plant)
	var stem := MeshLib.tapered_cylinder(0.03, 0.05, 0.42, 5, seed)
	mesh_fn.call(plant, stem, mats.get("trunk", mats.get("wood")), Vector3.ZERO)
	for side in [-1.0, 1.0]:
		var leaf := MeshLib.beveled_box(Vector3(0.28, 0.06, 0.42), 0.02, seed + int(side), 0.88)
		mesh_fn.call(plant, leaf, mats.get("leaf_green", mats.get("grass")), Vector3(side * 0.12, 0.32, 0.0), Vector3.ONE, Vector3(0, 0, side * 32.0))


static func _place_hero_tree(parent: Node3D, pos: Vector3, seed: int, mats: Dictionary, mesh_fn: Callable, scale_value: float) -> void:
	var tree := Node3D.new()
	tree.name = "HeroTree"
	tree.set_meta("vegetation_kind", "hero_tree")
	tree.position = pos
	tree.scale = Vector3.ONE * scale_value
	parent.add_child(tree)
	var trunk_h: float = 1.35
	mesh_fn.call(tree, MeshLib.tapered_trunk(trunk_h, 0.22, 0.14, seed, 8), mats.get("trunk", mats.get("wood")), Vector3.ZERO)
	var crown_defs: Array[Dictionary] = [
		{"pos": Vector3(-0.55, trunk_h + 0.18, 0.22), "r": 0.78, "sq": 0.68, "mat": "leaf_dark"},
		{"pos": Vector3(0.48, trunk_h + 0.32, -0.18), "r": 0.72, "sq": 0.72, "mat": "leaf_light"},
		{"pos": Vector3(0.05, trunk_h + 0.62, 0.12), "r": 0.62, "sq": 0.78, "mat": "leaf_green"},
		{"pos": Vector3(-0.22, trunk_h + 0.82, -0.08), "r": 0.48, "sq": 0.82, "mat": "leaf_light"},
		{"pos": Vector3(0.28, trunk_h + 0.95, 0.05), "r": 0.38, "sq": 0.85, "mat": "leaf_dark"},
	]
	for i in range(crown_defs.size()):
		var def: Dictionary = crown_defs[i]
		var blob: ArrayMesh = VegGen._crown_blob_mesh(seed + i * 41, def["r"] as float, def["sq"] as float)
		mesh_fn.call(
			tree, blob, mats.get(def["mat"] as String, mats.get("leaf_green", mats.get("grass"))),
			def["pos"] as Vector3, Vector3.ONE, Vector3(0, float(i) * 28.0, 0)
		)
