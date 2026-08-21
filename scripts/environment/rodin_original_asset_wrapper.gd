extends Node3D

## Read-only Rodin original asset wrapper — Phase 17A hotfix validation.
## Does not decimate, retopologize, rescale or rewrite materials.

signal asset_ready(report: Dictionary)

@export_file("*.glb") var pbr_glb_path: String = ""
@export var asset_id: String = "asset"
@export var asset_label: String = "Rodin Original"
@export var rodin_uuid: String = ""

var visual_root: Node3D
var load_errors: PackedStringArray = []
var bounds_min := Vector3.ZERO
var bounds_max := Vector3.ZERO
var inspection_report: Dictionary = {}


func _ready() -> void:
	build_asset()


func build_asset() -> void:
	_clear_children()
	load_errors.clear()
	inspection_report = {
		"asset_id": asset_id,
		"asset_label": asset_label,
		"rodin_uuid": rodin_uuid,
		"path": pbr_glb_path,
		"scale_applied": Vector3.ONE,
		"geometry_modified": false,
		"materials_rebuilt": false,
	}
	if pbr_glb_path.is_empty():
		load_errors.append("Missing pbr_glb_path")
		asset_ready.emit(inspection_report)
		return
	if not ResourceLoader.exists(pbr_glb_path):
		load_errors.append("GLB not imported yet: %s" % pbr_glb_path)
		asset_ready.emit(inspection_report)
		return
	var packed: PackedScene = load(pbr_glb_path) as PackedScene
	if packed == null:
		load_errors.append("Failed to load GLB scene: %s" % pbr_glb_path)
		asset_ready.emit(inspection_report)
		return
	var instance := packed.instantiate()
	if not instance is Node3D:
		load_errors.append("GLB root is not Node3D: %s" % pbr_glb_path)
		instance.queue_free()
		asset_ready.emit(inspection_report)
		return
	visual_root = instance as Node3D
	visual_root.name = "RodinVisual"
	visual_root.scale = Vector3.ONE
	visual_root.rotation = Vector3.ZERO
	add_child(visual_root)
	_compute_bounds(visual_root)
	_inspect_materials(visual_root)
	inspection_report["bounds_min"] = bounds_min
	inspection_report["bounds_max"] = bounds_max
	inspection_report["load_errors"] = load_errors.duplicate()
	asset_ready.emit.call_deferred(inspection_report)


func get_bounds_center() -> Vector3:
	return (bounds_min + bounds_max) * 0.5


func get_bounds_radius() -> float:
	var size := bounds_max - bounds_min
	return maxf(size.x, maxf(size.y, size.z)) * 0.5


func get_safe_camera_position(look_target: Vector3, distance_multiplier := 2.8, lift := 1.4) -> Vector3:
	var radius := get_bounds_radius()
	var distance := maxf(4.5, radius * distance_multiplier)
	return look_target + Vector3(0.0, lift, distance)


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
	visual_root = null


func _compute_bounds(node: Node) -> void:
	bounds_min = Vector3(1e9, 1e9, 1e9)
	bounds_max = Vector3(-1e9, -1e9, -1e9)
	_accumulate_bounds(node, Transform3D.IDENTITY)


func _accumulate_bounds(node: Node, parent_xform: Transform3D) -> void:
	var local_xform := parent_xform
	if node is Node3D:
		local_xform = parent_xform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh:
			var aabb: AABB = mesh_instance.mesh.get_aabb()
			for i in range(8):
				var corner: Vector3 = local_xform * aabb.get_endpoint(i)
				bounds_min = bounds_min.min(corner)
				bounds_max = bounds_max.max(corner)
	for child in node.get_children():
		_accumulate_bounds(child, local_xform)


func _inspect_materials(node: Node) -> void:
	var material_reports: Array = []
	_collect_material_reports(node, material_reports)
	inspection_report["materials"] = material_reports
	inspection_report["material_count"] = material_reports.size()
	inspection_report["pbr_slots_ok"] = material_reports.all(func(item): return bool(item.get("base_color", false)) and bool(item.get("normal", false)) and bool(item.get("metallic_roughness", false)))
	inspection_report["uvs_present"] = material_reports.all(func(item): return int(item.get("surface_count", 0)) >= 1)


func _collect_material_reports(node: Node, reports: Array) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			return
		for surface_idx in mesh.get_surface_count():
			var material: Material = mesh_instance.get_surface_override_material(surface_idx)
			if material == null:
				material = mesh.surface_get_material(surface_idx)
			var entry := {
				"mesh": mesh_instance.name,
				"surface": surface_idx,
				"surface_count": mesh.get_surface_count(),
				"base_color": false,
				"normal": false,
				"metallic_roughness": false,
				"emissive": false,
				"transparency_disabled": true,
			}
			if material is StandardMaterial3D:
				var std: StandardMaterial3D = material as StandardMaterial3D
				entry["base_color"] = std.albedo_texture != null
				entry["normal"] = std.normal_texture != null
				entry["metallic_roughness"] = std.orm_texture != null or (std.metallic_texture != null and std.roughness_texture != null)
				entry["emissive"] = std.emission_enabled and (std.emission_texture != null or std.emission_energy_multiplier > 0.0)
				entry["transparency_disabled"] = std.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
			reports.append(entry)
	for child in node.get_children():
		_collect_material_reports(child, reports)
