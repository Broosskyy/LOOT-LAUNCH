extends RefCounted
class_name V41PropKit

## V41 — Crystal altar, chest polish, portal ring endpoint.

const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const HeroModels = preload("res://scripts/environment/stylized/stylized_hero_models.gd")
const PortalGen = preload("res://scripts/environment/stylized/stylized_portal_generator.gd")
const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func place_chest(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> Node3D:
	return HeroModels.build_chest(parent, pos, mats, mesh_fn)


static func place_crystal_altar(
	parent: Node3D,
	pos: Vector3,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int = 4200
) -> Node3D:
	var altar := Node3D.new()
	altar.name = "CrystalAltar"
	altar.position = pos
	parent.add_child(altar)
	var stone_mat: Material = StylizedTypedAccess.material(mats, "ruin_stone", "stone_main")
	var crystal_mat: Material = StylizedTypedAccess.material(mats, "crystal", "portal")
	mesh_fn.call(altar, MeshLib.octagonal_plinth(0.62, 0.42, 0.28, seed), stone_mat, Vector3.ZERO)
	mesh_fn.call(altar, MeshLib.beveled_box(Vector3(0.52, 0.12, 0.52), 0.04, seed + 1, 0.86), stone_mat, Vector3(0, 0.28, 0))
	var shard := MeshLib.faceted_crystal(0.95, 0.22, seed + 2)
	mesh_fn.call(altar, shard, crystal_mat, Vector3(0, 0.62, 0), Vector3.ONE, Vector3(0, 18.0, 0))
	var glow := MeshLib.faceted_crystal(0.35, 0.12, seed + 3)
	mesh_fn.call(altar, glow, crystal_mat, Vector3(0.12, 0.48, 0.08), Vector3(0.8, 1.1, 0.8), Vector3(-12, 40, 8))
	return altar


static func place_portal_endpoint(
	parent: Node3D,
	pos: Vector3,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array,
	scale_value: float = 1.0
) -> Node3D:
	var site := Node3D.new()
	site.name = "PortalEndpoint"
	site.position = pos
	site.scale = Vector3.ONE * scale_value
	parent.add_child(site)
	PortalGen.build_monument(site, mats, mesh_fn, transparent_fn, animated_nodes, scale_value)
	return site
