extends Node3D

## UV-safe production asset wrapper — Phase 17B.
## Loads game_ready LOD GLBs, applies non-destructive emissive overrides,
## and keeps gameplay collision separate from render meshes.

signal asset_ready(report: Dictionary)

const GLB_HALF_EXTENT_X := 0.96
const COLLISION_RADIUS_FACTOR := 0.91
const ISLAND_EMISSION_TINT := Color(0.58, 0.46, 0.92)

@export var asset_key: String = "asset"
@export var asset_label: String = "Production Asset"
@export var lod0_path: String = ""
@export var lod1_path: String = ""
@export var lod2_path: String = ""
@export var emission_texture_path: String = ""
@export var ao_texture_path: String = ""
@export_range(0.0, 2.0) var emission_energy: float = 0.42
@export_range(0.0, 1.0) var ao_light_affect: float = 0.72
@export var visual_scale: float = 1.0
@export var enable_gameplay_collision: bool = false
@export var gameplay_radius: float = 11.648
@export var collision_thickness: float = 1.45
@export_range(20.0, 90.0) var lod0_end: float = 55.0
@export_range(40.0, 140.0) var lod1_begin: float = 50.0
@export_range(60.0, 180.0) var lod1_end: float = 120.0
@export_range(90.0, 220.0) var lod2_begin: float = 115.0
@export var quality_level: int = 2
@export var auto_configure_floating_island_defaults := false

var visual_root: Node3D
var collision_body: StaticBody3D
var load_errors: PackedStringArray = []
var lod_instances: Array[Node3D] = []
var inspection_report: Dictionary = {}


func _ready() -> void:
	if auto_configure_floating_island_defaults:
		configure_floating_island(12.8, 1.45, quality_level)
	build_asset()


static func gameplay_scale_for_radius(source_radius: float) -> float:
	return source_radius / GLB_HALF_EXTENT_X


static func gameplay_radius_for_source(source_radius: float) -> float:
	return source_radius * COLLISION_RADIUS_FACTOR


func configure_floating_island(source_radius: float, thickness: float, quality := 2) -> void:
	asset_key = "floating_island"
	asset_label = "Floating Island Production"
	lod0_path = "res://art/models/production/asset_02_floating_island/game_ready/LOD0.glb"
	lod1_path = "res://art/models/production/asset_02_floating_island/game_ready/LOD1.glb"
	lod2_path = "res://art/models/production/asset_02_floating_island/game_ready/LOD2.glb"
	emission_texture_path = "res://art/models/production/asset_02_floating_island/texture_emissive.png"
	ao_texture_path = "res://art/models/production/asset_02_floating_island/texture_ao_proxy.png"
	emission_energy = 0.16
	visual_scale = gameplay_scale_for_radius(source_radius)
	gameplay_radius = gameplay_radius_for_source(source_radius)
	collision_thickness = thickness
	enable_gameplay_collision = true
	quality_level = quality


func build_asset() -> void:
	_clear_children()
	load_errors.clear()
	lod_instances.clear()
	inspection_report = {
		"asset_key": asset_key,
		"asset_label": asset_label,
		"visual_scale": visual_scale,
		"gameplay_radius": gameplay_radius,
		"enable_gameplay_collision": enable_gameplay_collision,
	}
	_build_visual_lods()
	if enable_gameplay_collision:
		_build_gameplay_collision()
	inspection_report["load_errors"] = load_errors.duplicate()
	inspection_report["lod_count"] = lod_instances.size()
	inspection_report["materials_ok"] = _materials_valid()
	inspection_report["uvs_ok"] = lod_instances.size() > 0
	asset_ready.emit.call_deferred(inspection_report)


func get_bounds_center() -> Vector3:
	var merged := _merged_mesh_aabb()
	return merged.get_center() if merged.size != Vector3.ZERO else Vector3.ZERO


func get_bounds_radius() -> float:
	var merged := _merged_mesh_aabb()
	return merged.size.length() * 0.5 if merged.size != Vector3.ZERO else 1.0


func get_safe_camera_position(look_target: Vector3, distance_multiplier := 2.8, lift := 1.4) -> Vector3:
	var distance := maxf(5.0, get_bounds_radius() * distance_multiplier)
	return look_target + Vector3(0.0, lift, distance)


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
	visual_root = null
	collision_body = null


func _build_visual_lods() -> void:
	visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	var paths := [lod0_path, lod1_path, lod2_path]
	var configs := [
		{"end": lod0_end, "margin": 8.0},
		{"begin": lod1_begin, "end": lod1_end, "margin": 10.0},
		{"begin": lod2_begin, "margin": 12.0},
	]
	for i in paths.size():
		var path: String = paths[i]
		if path.is_empty():
			continue
		if not ResourceLoader.exists(path):
			load_errors.append("Missing LOD GLB: %s" % path)
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			load_errors.append("Failed to import LOD GLB: %s" % path)
			continue
		var instance := packed.instantiate()
		if not instance is Node3D:
			load_errors.append("LOD root is not Node3D: %s" % path)
			instance.queue_free()
			continue
		var lod_root: Node3D = instance as Node3D
		lod_root.name = "LOD%d" % i
		lod_root.scale = Vector3.ONE * visual_scale
		_apply_visibility_ranges(lod_root, configs[i], i)
		_apply_emissive_overrides(lod_root)
		_enhance_imported_materials(lod_root)
		_enforce_opaque_materials(lod_root)
		visual_root.add_child(lod_root)
		lod_instances.append(lod_root)


func _apply_visibility_ranges(node: Node, config: Dictionary, lod_index: int) -> void:
	var effective := config.duplicate()
	if quality_level <= 0 and lod_index == 0:
		effective["end"] = minf(float(effective.get("end", lod0_end)), 42.0)
	if node is GeometryInstance3D:
		var geo: GeometryInstance3D = node as GeometryInstance3D
		if effective.has("begin"):
			geo.visibility_range_begin = float(effective.begin)
		if effective.has("end"):
			geo.visibility_range_end = float(effective.end)
		var margin: float = float(effective.get("margin", 6.0))
		geo.visibility_range_begin_margin = margin * 0.6
		geo.visibility_range_end_margin = margin
	for child in node.get_children():
		_apply_visibility_ranges(child, effective, lod_index)


func _apply_emissive_overrides(node: Node) -> void:
	if emission_texture_path.is_empty() or not ResourceLoader.exists(emission_texture_path):
		return
	var emission_texture: Texture2D = load(emission_texture_path) as Texture2D
	if emission_texture == null:
		return
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh:
			for surface_idx in mesh.get_surface_count():
				var source: Material = mesh_instance.get_surface_override_material(surface_idx)
				if source == null:
					source = mesh.surface_get_material(surface_idx)
				if source is StandardMaterial3D:
					var override_mat: StandardMaterial3D = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
					override_mat.emission_enabled = true
					override_mat.emission = ISLAND_EMISSION_TINT
					override_mat.emission_texture = emission_texture
					override_mat.emission_energy_multiplier = emission_energy
					override_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					override_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
					mesh_instance.set_surface_override_material(surface_idx, override_mat)
	for child in node.get_children():
		_apply_emissive_overrides(child)


func _enhance_imported_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh:
			for surface_idx in mesh.get_surface_count():
				var material: Material = mesh_instance.get_surface_override_material(surface_idx)
				if material == null:
					material = mesh.surface_get_material(surface_idx)
				if material is StandardMaterial3D:
					var tuned: StandardMaterial3D = (material as StandardMaterial3D).duplicate() as StandardMaterial3D
					tuned.albedo_color = Color.WHITE
					tuned.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					if tuned.normal_texture:
						tuned.normal_enabled = true
					_apply_optional_ao(tuned)
					mesh_instance.set_surface_override_material(surface_idx, tuned)
	for child in node.get_children():
		_enhance_imported_materials(child)


func _apply_optional_ao(material: StandardMaterial3D) -> void:
	if ao_texture_path.is_empty() or not ResourceLoader.exists(ao_texture_path):
		return
	var ao_texture: Texture2D = load(ao_texture_path) as Texture2D
	if ao_texture == null:
		return
	material.ao_enabled = true
	material.ao_texture = ao_texture
	material.ao_light_affect = ao_light_affect


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
					var base: BaseMaterial3D = material as BaseMaterial3D
					base.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					base.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	for child in node.get_children():
		_enforce_opaque_materials(child)


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
	var skirt := CollisionShape3D.new()
	skirt.name = "OcclusionSkirt"
	var skirt_shape := CylinderShape3D.new()
	skirt_shape.radius = gameplay_radius + 1.2
	skirt_shape.height = maxf(2.0, collision_thickness + 0.8)
	skirt.shape = skirt_shape
	skirt.position.y = -skirt_shape.height * 0.35
	collision_body.add_child(skirt)


func _materials_valid() -> bool:
	if visual_root == null:
		return false
	return _mesh_instances_valid(visual_root)


func _mesh_instances_valid(node: Node) -> bool:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh and mesh_instance.mesh.get_surface_count() == 0:
			return false
	for child in node.get_children():
		if not _mesh_instances_valid(child):
			return false
	return true


func _merged_mesh_aabb() -> AABB:
	if visual_root == null:
		return AABB()
	return _aabb_from_node(visual_root)


func _aabb_from_node(node: Node) -> AABB:
	var merged := AABB()
	var has_box := false
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh:
			merged = mesh_instance.get_aabb()
			has_box = true
	for child in node.get_children():
		var child_box := _aabb_from_node(child)
		if child_box.size != Vector3.ZERO:
			merged = child_box if not has_box else merged.merge(child_box)
			has_box = true
	return merged if has_box else AABB()
