extends Node

## Preview-only material audit and QA verification — no geometry, no material overrides.

const EXPECTED_MAP_SIZE := 2048
const EXPECTED_EMISSION_ENERGY := 0.16
const EXPECTED_EMISSION_TINT := Color(0.58, 0.46, 0.92)
const EXPECTED_TEXTURE_FILTER := BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


func audit_visual_root(visual_root: Node) -> Dictionary:
	var report := {
		"surfaces": [],
	}
	if visual_root == null:
		return report
	_collect_surface_reports(visual_root, report)
	return report


func verify_qa_materials(visual_root: Node) -> Dictionary:
	var report := audit_visual_root(visual_root)
	var checks: Array[Dictionary] = []
	for surface in report.get("surfaces", []):
		checks.append_array(_verify_surface(surface))
	return {
		"surfaces": report.get("surfaces", []),
		"checks": checks,
		"passed": _all_checks_passed(checks),
		"atlas_analysis": _atlas_analysis(),
	}


func print_audit(report: Dictionary) -> void:
	print("Island material audit — surfaces=", report.get("surfaces", []).size())
	for entry in report.get("surfaces", []):
		print("  ", entry)


func print_qa_report(qa_report: Dictionary) -> void:
	print("Island material QA — passed=", qa_report.get("passed", false))
	for check in qa_report.get("checks", []):
		var status := "OK" if check.get("ok", false) else "FAIL"
		print("  [%s] %s" % [status, check.get("label", "")])
		if not check.get("ok", false) and check.has("detail"):
			print("       ", check.detail)
	print("Atlas analysis:")
	for line in qa_report.get("atlas_analysis", []):
		print("  - ", line)


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
		if std.ao_texture:
			entry.maps.append("ao:%sx%s" % [std.ao_texture.get_width(), std.ao_texture.get_height()])
		entry.emission_energy = std.emission_energy_multiplier
		entry["albedo_color"] = std.albedo_color
		entry["roughness"] = std.roughness
		entry["metallic"] = std.metallic
		entry["texture_filter"] = std.texture_filter
		entry["normal_enabled"] = std.normal_enabled
		entry["emission_enabled"] = std.emission_enabled
		entry["emission"] = std.emission
		entry["metallic_texture_channel"] = std.metallic_texture_channel
		entry["roughness_texture_channel"] = std.roughness_texture_channel
		entry["has_metallic_texture"] = std.metallic_texture != null
		entry["has_roughness_texture"] = std.roughness_texture != null
	return entry


func _verify_surface(surface: Dictionary) -> Array[Dictionary]:
	var checks: Array[Dictionary] = []
	var prefix: String = "%s#%d" % [surface.get("mesh", "?"), surface.get("surface", 0)]
	var map_text: String = ", ".join(PackedStringArray(surface.get("maps", [])))

	checks.append(_check(
		"%s albedo 2048 active" % prefix,
		_has_map_size(surface, "albedo:", EXPECTED_MAP_SIZE),
		map_text
	))
	checks.append(_check(
		"%s normal 2048 active" % prefix,
		surface.get("normal_enabled", false) and _has_map_size(surface, "normal:", EXPECTED_MAP_SIZE),
		"normal_enabled=%s" % surface.get("normal_enabled", false)
	))
	checks.append(_check(
		"%s MR map active" % prefix,
		surface.get("has_metallic_texture", false) and surface.get("has_roughness_texture", false),
		map_text
	))
	checks.append(_check(
		"%s MR channels glTF-correct" % prefix,
		surface.get("metallic_texture_channel", -1) == BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		and surface.get("roughness_texture_channel", -1) == BaseMaterial3D.TEXTURE_CHANNEL_GREEN,
		"metallic=%s roughness=%s" % [
			surface.get("metallic_texture_channel", -1),
			surface.get("roughness_texture_channel", -1),
		]
	))
	checks.append(_check(
		"%s anisotropic filtering" % prefix,
		surface.get("texture_filter", -1) == EXPECTED_TEXTURE_FILTER,
		"filter=%s" % surface.get("texture_filter", -1)
	))
	checks.append(_check(
		"%s emission configured" % prefix,
		surface.get("emission_enabled", false)
		and surface.get("emission_energy", 0.0) == EXPECTED_EMISSION_ENERGY
		and _color_near(surface.get("emission", Color.BLACK), EXPECTED_EMISSION_TINT),
		"energy=%s emission=%s" % [surface.get("emission_energy", 0.0), surface.get("emission", Color.BLACK)]
	))
	checks.append(_check(
		"%s ao proxy active" % prefix,
		_has_map_size(surface, "ao:", EXPECTED_MAP_SIZE),
		map_text
	))
	checks.append(_check(
		"%s albedo tint neutral" % prefix,
		_color_near(surface.get("albedo_color", Color.BLACK), Color.WHITE),
		"albedo_color=%s" % surface.get("albedo_color", Color.BLACK)
	))
	return checks


func _atlas_analysis() -> PackedStringArray:
	return PackedStringArray([
		"Single material \"model\" shares one 2048 atlas for grass, stone, cliff, and crystals.",
		"Per-region roughness/metallic variation must come from the MR texture green/blue channels.",
		"Scalar roughness/metallic factors are preserved from glTF import; no runtime scalar clamp applied.",
		"Emission is masked by texture_emissive.png; black mask pixels should not glow on grass/stone/cliff.",
		"Atlas UV islands may show mip bleeding at sharp color boundaries — inspect SURFACE preset closely.",
		"No AO map is present; micro-contrast relies on normal + MR + lighting only.",
	])


func _has_map_size(surface: Dictionary, prefix: String, size: int) -> bool:
	for map_entry in surface.get("maps", []):
		if str(map_entry).begins_with(prefix):
			return str(map_entry).contains("%dx%d" % [size, size])
	return false


func _check(label: String, ok: bool, detail: String = "") -> Dictionary:
	return {"label": label, "ok": ok, "detail": detail}


func _all_checks_passed(checks: Array[Dictionary]) -> bool:
	for check in checks:
		if not check.get("ok", false):
			return false
	return true


func _color_near(a: Color, b: Color, epsilon := 0.02) -> bool:
	return absf(a.r - b.r) <= epsilon and absf(a.g - b.g) <= epsilon and absf(a.b - b.b) <= epsilon
