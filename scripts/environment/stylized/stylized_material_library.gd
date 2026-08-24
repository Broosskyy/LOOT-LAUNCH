extends RefCounted
class_name StylizedMaterialLibrary

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const StylizedShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")
const StylizedMotionController = preload("res://scripts/environment/stylized/stylized_motion_controller.gd")

## V26 render foundation — muted palette + GLES stylized surface shaders.


static func apply_palette(
	mats: Dictionary,
	material_fn: Callable,
	transparent_fn: Callable,
	quality_level: int = 2
) -> void:
	var use_shaders: bool = quality_level >= 1
	# Grass family
	mats["grass_main"] = _surface(
		use_shaders, material_fn, Color("4a9c58"), 0.94, 0.0, true, 0.10, 0.07
	)
	mats["grass_light"] = _surface(
		use_shaders, material_fn, Color("68b470"), 0.92, 0.0, true, 0.09, 0.07
	)
	mats["grass_dark"] = _surface(
		use_shaders, material_fn, Color("3d8c4c"), 0.95, 0.0, true, 0.11, 0.06
	)
	# Rock / cliff family
	mats["stone_main"] = _surface(
		use_shaders, material_fn, Color("918b84"), 0.94, 0.0, false, 0.13, 0.07
	)
	mats["stone_dark"] = _surface(
		use_shaders, material_fn, Color("726c66"), 0.95, 0.0, false, 0.15, 0.05
	)
	mats["stone_light"] = _surface(
		use_shaders, material_fn, Color("b8b0a4"), 0.9, 0.0, false, 0.10, 0.09
	)
	mats["path_stone"] = _surface(
		use_shaders, material_fn, Color("c4b8a6"), 0.88, 0.0, false, 0.08, 0.11
	)
	mats["stone_warm"] = _surface(
		use_shaders, material_fn, Color("a89888"), 0.9, 0.0, false, 0.10, 0.10
	)
	mats["ruin_stone"] = _surface(
		use_shaders, material_fn, Color("a89a8a"), 0.91, 0.0, false, 0.11, 0.09
	)
	mats["dirt"] = StylizedShaderLibrary.standard_surface(material_fn, Color("7a5d45"), 0.95, 0.0)
	mats["wood"] = StylizedShaderLibrary.standard_surface(material_fn, Color("6a4228"), 0.9, 0.0)
	mats["wood_dark"] = StylizedShaderLibrary.standard_surface(material_fn, Color("4a3020"), 0.92, 0.0)
	mats["wood_light"] = StylizedShaderLibrary.standard_surface(material_fn, Color("9a5f36"), 0.86, 0.0)
	mats["brass"] = StylizedShaderLibrary.standard_surface(material_fn, Color("b88830"), 0.38, 0.72)
	mats["cannon_dark"] = StylizedShaderLibrary.standard_surface(material_fn, Color("2c2f3a"), 0.42, 0.62)
	mats["crystal_violet"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("9068e0"), 0.24, 0.06, Color("6840d0"), 0.34
	)
	mats["crystal_blue"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("58b0e0"), 0.22, 0.05, Color("3898d0"), 0.28
	)
	mats["portal"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("8250e0"), 0.26, 0.08, Color("6030c8"), 0.52
	)
	mats["pad_energy"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("b868c8"), 0.3, 0.05, Color("c870d8"), 0.46
	)
	mats["flower_pink"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("e080a0"), 0.48, 0.0, Color("c86890"), 0.08
	)
	mats["flower_white"] = StylizedShaderLibrary.standard_surface(material_fn, Color("fff5ef"), 0.52, 0.0)
	mats["flower_violet"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("b080d0"), 0.46, 0.0, Color("9860b8"), 0.06
	)
	mats["flower_center"] = StylizedShaderLibrary.standard_surface(material_fn, Color("e0b848"), 0.42, 0.0)
	mats["leaf_green"] = _surface(
		use_shaders, material_fn, Color("488850"), 0.88, 0.0, true, 0.09, 0.07
	)
	mats["leaf_dark"] = _surface(
		use_shaders, material_fn, Color("3a8044"), 0.9, 0.0, true, 0.10, 0.06
	)
	mats["leaf_light"] = _surface(
		use_shaders, material_fn, Color("68a868"), 0.88, 0.0, true, 0.08, 0.07
	)
	mats["trunk"] = StylizedShaderLibrary.standard_surface(material_fn, Color("7a5230"), 0.92, 0.0)
	mats["coin"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("d0a030"), 0.28, 0.7, Color("b88820"), 0.18
	)
	mats["cloud_soft"] = _cloud_surface(use_shaders, material_fn, Color("f4f8ff"), Color("dce8f4"))
	mats["cloud_mid"] = _cloud_surface(use_shaders, material_fn, Color("eef4fc"), Color("d4e0ec"))
	mats["cloud_shadow"] = _cloud_surface(use_shaders, material_fn, Color("e8f0fa"), Color("ccd8e8"))
	mats["distant_grass"] = _surface(
		use_shaders, material_fn, Color("7a9888"), 0.95, 0.0, true, 0.07, 0.05
	)
	mats["distant_rock"] = _surface(
		use_shaders, material_fn, Color("98a4b0"), 0.96, 0.0, false, 0.14, 0.04
	)
	mats["bouncer"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("f0a878"), 0.5, 0.02, Color("e88958"), 0.05
	)
	mats["cheek"] = StylizedShaderLibrary.standard_surface(material_fn, Color("ff96aa"), 0.52, 0.0)
	# V21 hero aliases
	mats["cannon_dark_metal"] = mats["cannon_dark"]
	mats["brass_gold"] = mats["brass"]
	mats["chest_wood"] = mats["wood"]
	mats["chest_metal"] = mats["brass"]
	mats["portal_stone"] = mats["stone_dark"]
	mats["portal_energy"] = mats["portal"]
	mats["pad_stone"] = mats["stone_main"]
	mats["sign_wood"] = mats["wood"]
	mats["sign_frame"] = mats["wood_dark"]
	_configure_stylized_surface_flags(mats)
	StylizedMotionController.configure_wind_materials(mats, quality_level)
	# Legacy keys
	mats["grass"] = mats["grass_main"]
	mats["grass_mint"] = mats["grass_light"]
	mats["grass_gold"] = mats["grass_light"]
	mats["grass_blue"] = mats["grass_light"]
	mats["grass_lilac"] = mats["grass_light"]
	mats["grass_amber"] = mats["grass_dark"]
	mats["grass_royal"] = mats["grass_main"]
	mats["rock"] = mats["stone_main"]
	mats["rock_mid"] = mats["stone_dark"]
	mats["rock_dark"] = mats["stone_dark"]
	mats["cliff_warm"] = mats["stone_warm"]
	mats["edge_moss"] = mats["grass_dark"]
	mats["crystal"] = mats["crystal_violet"]
	mats["violet"] = mats["portal"]
	mats["white"] = mats["stone_light"]
	mats["cannon"] = mats["cannon_dark"]
	mats["cloud"] = mats["cloud_soft"]


static func _surface(
	use_shaders: bool,
	material_fn: Callable,
	color: Color,
	roughness: float,
	metallic: float,
	is_grass: bool,
	cool_shadow: float,
	warm_highlight: float
) -> Material:
	if use_shaders:
		if is_grass:
			return StylizedShaderLibrary.grass_material(color, roughness)
		return StylizedShaderLibrary.rock_material(color, roughness, metallic, cool_shadow, warm_highlight)
	return StylizedShaderLibrary.standard_surface(material_fn, color, roughness, metallic)


static func _cloud_surface(
	use_shaders: bool,
	material_fn: Callable,
	top: Color,
	bottom: Color
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.cloud_material(top, bottom)
	return StylizedShaderLibrary.standard_surface(material_fn, top, 1.0, 0.0)


static func validate_palette(mats: Dictionary) -> Array[String]:
	var errors: Array[String] = StylizedShaderLibrary.validate_shaders()
	var required: Array[String] = [
		"grass_main", "grass_light", "grass_dark", "stone_main", "stone_dark", "stone_light",
		"path_stone", "ruin_stone", "wood", "wood_dark", "brass", "cannon_dark",
		"leaf_green", "leaf_light", "leaf_dark", "portal_energy", "pad_energy",
		"crystal_violet", "crystal_blue", "cloud", "cloud_shadow", "distant_grass", "distant_rock",
	]
	for key in required:
		if not mats.has(key):
			errors.append("missing material key: %s" % key)
			continue
		var material: Material = mats[key]
		if material is StandardMaterial3D:
			var std := material as StandardMaterial3D
			if not _color_finite(std.albedo_color):
				errors.append("invalid albedo for %s" % key)
			if std.metallic < 0.0 or std.metallic > 1.0:
				errors.append("metallic out of range for %s" % key)
			if std.roughness < 0.0 or std.roughness > 1.0:
				errors.append("roughness out of range for %s" % key)
			if std.emission_enabled:
				if not _color_finite(std.emission):
					errors.append("invalid emission for %s" % key)
				if std.emission_energy_multiplier < 0.0 or std.emission_energy_multiplier > 2.5:
					errors.append("emission energy out of range for %s" % key)
		elif material is ShaderMaterial:
			if (material as ShaderMaterial).shader == null:
				errors.append("shader missing for %s" % key)
		else:
			errors.append("unsupported material type for %s" % key)
	return errors


static func _color_finite(color: Color) -> bool:
	return is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and color.r >= 0.0 and color.g >= 0.0 and color.b >= 0.0


static func _configure_stylized_surface_flags(mats: Dictionary) -> void:
	var grass_keys: Array[String] = ["grass_main", "grass_light", "grass_dark", "distant_grass", "leaf_green", "leaf_dark", "leaf_light"]
	var stone_keys: Array[String] = ["stone_main", "stone_dark", "stone_light", "stone_warm", "path_stone", "ruin_stone", "distant_rock"]
	for key in grass_keys:
		var mat: Material = mats[key]
		if mat is StandardMaterial3D:
			var grass_mat := mat as StandardMaterial3D
			grass_mat.vertex_color_use_as_albedo = true
			grass_mat.cull_mode = BaseMaterial3D.CULL_BACK if key == "distant_grass" else BaseMaterial3D.CULL_DISABLED
	for key in stone_keys:
		var stone_mat: Material = mats[key]
		if stone_mat is StandardMaterial3D:
			(stone_mat as StandardMaterial3D).vertex_color_use_as_albedo = false
			(stone_mat as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
