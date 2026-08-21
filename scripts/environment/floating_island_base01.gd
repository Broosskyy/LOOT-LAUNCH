extends Node3D

## Production GLB island — Phase 17A.
## Visual LOD meshes and simplified gameplay collision are intentionally separate.

signal island_built

const LOD_PATHS := [
	"res://art/models/environment/islands/floating_island_base01/LL_FloatingIsland_Base01_LOD0.glb",
	"res://art/models/environment/islands/floating_island_base01/LL_FloatingIsland_Base01_LOD1.glb",
	"res://art/models/environment/islands/floating_island_base01/LL_FloatingIsland_Base01_LOD2.glb",
]
const GLB_HALF_EXTENT_X := 0.96
const DEFAULT_SOURCE_RADIUS := 12.8
const COLLISION_RADIUS_FACTOR := 0.91

@export var source_radius: float = DEFAULT_SOURCE_RADIUS
@export var collision_thickness: float = 1.45
@export var visual_scale_override: float = 0.0
@export var gameplay_radius_override: float = 0.0
@export_range(20.0, 90.0) var lod0_end: float = 55.0
@export_range(40.0, 140.0) var lod1_begin: float = 50.0
@export_range(60.0, 180.0) var lod1_end: float = 120.0
@export_range(90.0, 220.0) var lod2_begin: float = 115.0

var visual_root: Node3D
var collision_body: StaticBody3D
var visual_scale: float
var gameplay_radius: float
var load_errors: PackedStringArray = []
var lod_instances: Array[Node3D] = []


func _ready() -> void:
	build_island()


func build_island() -> void:
	_clear_children()
	load_errors.clear()
	lod_instances.clear()
	visual_scale = visual_scale_override if visual_scale_override > 0.0 else source_radius / GLB_HALF_EXTENT_X
	gameplay_radius = gameplay_radius_override if gameplay_radius_override > 0.0 else source_radius * COLLISION_RADIUS_FACTOR
	_build_visual_lods()
	_build_gameplay_collision()
	island_built.emit.call_deferred()


func get_walk_surface_y() -> float:
	return 0.0


func get_floor_offset() -> float:
	return 0.84


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
	visual_root = null
	collision_body = null


func _build_visual_lods() -> void:
	visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	var lod_configs := [
		{"end": lod0_end, "margin": 8.0},
		{"begin": lod1_begin, "end": lod1_end, "margin": 10.0},
		{"begin": lod2_begin, "margin": 12.0},
	]
	for i in LOD_PATHS.size():
		var path: String = LOD_PATHS[i]
		if not ResourceLoader.exists(path):
			load_errors.append("Missing GLB: %s" % path)
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			load_errors.append("GLB not imported yet: %s" % path)
			continue
		var instance := packed.instantiate()
		if not instance is Node3D:
			load_errors.append("GLB root is not Node3D: %s" % path)
			instance.queue_free()
			continue
		var lod_root: Node3D = instance as Node3D
		lod_root.name = "LOD%d" % i
		lod_root.scale = Vector3.ONE * visual_scale
		_apply_visibility_ranges(lod_root, lod_configs[i])
		_enforce_opaque_materials(lod_root)
		visual_root.add_child(lod_root)
		lod_instances.append(lod_root)


func _apply_visibility_ranges(node: Node, config: Dictionary) -> void:
	if node is GeometryInstance3D:
		var geo: GeometryInstance3D = node as GeometryInstance3D
		if config.has("begin"):
			geo.visibility_range_begin = float(config.begin)
		if config.has("end"):
			geo.visibility_range_end = float(config.end)
		var margin: float = float(config.get("margin", 6.0))
		geo.visibility_range_begin_margin = margin * 0.6
		geo.visibility_range_end_margin = margin
		geo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_apply_visibility_ranges(child, config)


func _enforce_opaque_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh:
			for surface_idx in mesh.get_surface_count():
				var material: Material = mesh_instance.get_surface_override_material(surface_idx)
				if material == null:
					material = mesh.surface_get_material(surface_idx)
				if material is BaseMaterial3D:
					_ensure_opaque(material as BaseMaterial3D)
	for child in node.get_children():
		_enforce_opaque_materials(child)


func _ensure_opaque(material: BaseMaterial3D) -> void:
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	if material.emission_enabled:
		material.emission_energy_multiplier = maxf(material.emission_energy_multiplier, 0.35)


func _build_gameplay_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "GameplayCollision"
	collision_body.collision_layer = 1
	collision_body.collision_mask = 0
	add_child(collision_body)
	var walk := CollisionShape3D.new()
	walk.name = "WalkSurface"
	var walk_shape := CylinderShape3D.new()
	walk_shape.radius = gameplay_radius
	walk_shape.height = collision_thickness
	walk.shape = walk_shape
	walk.position.y = -collision_thickness * 0.5
	collision_body.add_child(walk)
	var rim := CollisionShape3D.new()
	rim.name = "LandingRim"
	var rim_shape := CylinderShape3D.new()
	rim_shape.radius = gameplay_radius + 0.45
	rim_shape.height = 0.35
	rim.shape = rim_shape
	rim.position.y = 0.12
	collision_body.add_child(rim)


func validate_materials() -> PackedStringArray:
	var issues: PackedStringArray = []
	if visual_root == null:
		issues.append("Visual root missing")
		return issues
	_collect_material_issues(visual_root, issues)
	return issues


func _collect_material_issues(node: Node, issues: PackedStringArray) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			return
		for surface_idx in mesh.get_surface_count():
			var material: Material = mesh_instance.get_surface_override_material(surface_idx)
			if material == null:
				material = mesh.surface_get_material(surface_idx)
			if material is BaseMaterial3D:
				var base: BaseMaterial3D = material as BaseMaterial3D
				if base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					issues.append("%s surface %d uses transparency" % [mesh_instance.name, surface_idx])
				if base.depth_draw_mode != BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY:
					issues.append("%s surface %d does not write opaque depth" % [mesh_instance.name, surface_idx])
	for child in node.get_children():
		_collect_material_issues(child, issues)
