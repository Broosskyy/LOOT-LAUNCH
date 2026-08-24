extends RefCounted
class_name StylizedRuinGenerator

const StylizedGroundRuinsKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")
const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func add_stone_block(parent: Node3D, pos: Vector3, size: Vector3, mats: Dictionary, mesh_fn: Callable, rot: Vector3 = Vector3.ZERO) -> void:
	StylizedGroundRuinsKit.place_ruin_block(parent, pos, size, mats, mesh_fn, 0, int(pos.x * 17.0 + pos.z * 31.0), "main", rot)


static func add_broken_wall(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> void:
	StylizedGroundRuinsKit.add_wall_segment(parent, pos, -18.0, mats, mesh_fn, true, 2201)


const StylizedHeroModels = preload("res://scripts/environment/stylized/stylized_hero_models.gd")


static func add_signpost(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> void:
	StylizedHeroModels.build_signpost(parent, pos, mats, mesh_fn)


static func add_stone_steps(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, count: int = 4) -> void:
	StylizedGroundRuinsKit.add_stair_segment(parent, pos, 0.0, mats, mesh_fn, count, 3301)


static func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh
