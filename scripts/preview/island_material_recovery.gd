extends Node

## Preview-only material audit log helper — no geometry, no overrides beyond logging.

func audit_visual_root(visual_root: Node) -> Dictionary:
	var report := {
		"surfaces": [],
		"embedded_textures": [],
		"external_emissive": "",
	}
	if visual_root == null:
		return report
	_collect_surface_reports(visual_root, report)
	return report


func print_audit(report: Dictionary) -> void:
	print("Island material audit — surfaces=", report.get("surfaces", []).size())
	for entry in report.get("surfaces", []):
		print("  ", entry)


func _collect_surface_reports(node: Node, report: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			return
		for surface_idx in mesh.get_surface_count():
			var material: Material = mesh_instance.get_surface_override_material(surface_idx)
			if material == null:
				material = mesh.surface_get_material(surface_idx)
			report.surfaces.append(_describe_material(mesh_instance.name, surface_idx, material))
	for child in node.get_children():
		_collect_surface_reports(child, report)


func _describe_material(owner_name: String, surface_idx: int, material: Material) -> Dictionary:
	var entry := {
		"mesh": owner_name,
		"surface": surface_idx,
		"type": material.get_class() if material else "none",
		"maps": [],
		"emission_energy": 0.0,
	}
	if material is StandardMaterial3D:
		var std: StandardMaterial3D = material as StandardMaterial3D
		if std.albedo_texture:
			entry.maps.append("albedo:%sx%s" % [std.albedo_texture.get_width(), std.albedo_texture.get_height()])
		if std.normal_texture:
			entry.maps.append("normal:%sx%s" % [std.normal_texture.get_width(), std.normal_texture.get_height()])
		if std.orm_texture:
			entry.maps.append("orm:%sx%s" % [std.orm_texture.get_width(), std.orm_texture.get_height()])
		elif std.metallic_texture or std.roughness_texture:
			entry.maps.append("metallic_roughness")
		if std.emission_texture:
			entry.maps.append("emission:%sx%s" % [std.emission_texture.get_width(), std.emission_texture.get_height()])
		entry.emission_energy = std.emission_energy_multiplier
		entry["albedo_color"] = std.albedo_color
		entry["roughness"] = std.roughness
		entry["metallic"] = std.metallic
	return entry
