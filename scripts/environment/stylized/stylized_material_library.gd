extends RefCounted
class_name StylizedMaterialLibrary

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")

## V24 reference palette — muted fresh greens, warm stone, controlled magic emission.


static func apply_palette(
	mats: Dictionary,
	material_fn: Callable,
	transparent_fn: Callable
) -> void:
	mats["grass_main"] = StylizedTypedAccess.opaque_material(material_fn, Color("4a9e5c"), 0.92, 0.0)
	mats["grass_light"] = StylizedTypedAccess.opaque_material(material_fn, Color("6eb874"), 0.9, 0.0)
	mats["grass_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("3d8f4f"), 0.94, 0.0)
	mats["stone_main"] = StylizedTypedAccess.opaque_material(material_fn, Color("8f8a84"), 0.92, 0.0)
	mats["stone_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("746f6a"), 0.94, 0.0)
	mats["stone_light"] = StylizedTypedAccess.opaque_material(material_fn, Color("b8b0a4"), 0.88, 0.0)
	mats["path_stone"] = StylizedTypedAccess.opaque_material(material_fn, Color("c0b5a4"), 0.9, 0.0)
	mats["stone_warm"] = StylizedTypedAccess.opaque_material(material_fn, Color("a89a8c"), 0.9, 0.0)
	mats["ruin_stone"] = StylizedTypedAccess.opaque_material(material_fn, Color("a89a8c"), 0.9, 0.0)
	mats["dirt"] = StylizedTypedAccess.opaque_material(material_fn, Color("7a5d45"), 0.94, 0.0)
	mats["wood"] = StylizedTypedAccess.opaque_material(material_fn, Color("6a4228"), 0.88, 0.0)
	mats["wood_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("4a3020"), 0.9, 0.0)
	mats["wood_light"] = StylizedTypedAccess.opaque_material(material_fn, Color("9a5f36"), 0.84, 0.0)
	mats["brass"] = StylizedTypedAccess.opaque_material(material_fn, Color("c49438"), 0.34, 0.68)
	mats["cannon_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("2a2d38"), 0.38, 0.58)
	mats["crystal_violet"] = StylizedTypedAccess.opaque_material(material_fn, Color("9468e8"), 0.22, 0.08, Color("7040d8"), 0.38)
	mats["crystal_blue"] = StylizedTypedAccess.opaque_material(material_fn, Color("58b8e8"), 0.2, 0.06, Color("38a0d8"), 0.32)
	mats["portal"] = StylizedTypedAccess.opaque_material(material_fn, Color("8650e8"), 0.24, 0.1, Color("6830d0"), 0.58)
	mats["pad_energy"] = StylizedTypedAccess.opaque_material(material_fn, Color("c070d0"), 0.28, 0.06, Color("d878e8"), 0.52)
	mats["flower_pink"] = StylizedTypedAccess.opaque_material(material_fn, Color("e888a8"), 0.46, 0.0, Color("d07098"), 0.1)
	mats["flower_white"] = StylizedTypedAccess.opaque_material(material_fn, Color("fff5ef"), 0.5, 0.0)
	mats["flower_violet"] = StylizedTypedAccess.opaque_material(material_fn, Color("b888d8"), 0.44, 0.0, Color("9868c8"), 0.08)
	mats["flower_center"] = StylizedTypedAccess.opaque_material(material_fn, Color("e8c050"), 0.4, 0.0)
	mats["leaf_green"] = StylizedTypedAccess.opaque_material(material_fn, Color("489858"), 0.86, 0.0)
	mats["leaf_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("3a8848"), 0.9, 0.0)
	mats["leaf_light"] = StylizedTypedAccess.opaque_material(material_fn, Color("68b070"), 0.86, 0.0)
	mats["trunk"] = StylizedTypedAccess.opaque_material(material_fn, Color("7a5230"), 0.9, 0.0)
	mats["coin"] = StylizedTypedAccess.opaque_material(material_fn, Color("d8a838"), 0.24, 0.72, Color("c89028"), 0.22)
	mats["cloud_soft"] = StylizedTypedAccess.opaque_material(material_fn, Color("f4f8ff"), 1.0, 0.0)
	mats["cloud_mid"] = StylizedTypedAccess.opaque_material(material_fn, Color("e8f0fa"), 1.0, 0.0)
	mats["distant_grass"] = StylizedTypedAccess.opaque_material(material_fn, Color("7a9a88"), 0.94, 0.0)
	mats["distant_rock"] = StylizedTypedAccess.opaque_material(material_fn, Color("9aa4b0"), 0.96, 0.0)
	mats["bouncer"] = StylizedTypedAccess.opaque_material(material_fn, Color("f0a878"), 0.48, 0.02, Color("e88958"), 0.06)
	mats["cheek"] = StylizedTypedAccess.opaque_material(material_fn, Color("ff96aa"), 0.5, 0.0)
	# V21 hero model palette.
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
	# Remap legacy keys used across world systems.
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


static func validate_palette(mats: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var required: Array[String] = [
		"grass_main", "grass_light", "grass_dark", "stone_main", "stone_dark", "stone_light",
		"path_stone", "ruin_stone", "wood", "wood_dark", "brass", "cannon_dark",
		"leaf_green", "leaf_light", "leaf_dark", "portal_energy", "pad_energy",
		"crystal_violet", "crystal_blue", "cloud", "distant_grass", "distant_rock",
	]
	for key in required:
		if not mats.has(key):
			errors.append("missing material key: %s" % key)
			continue
		var material := mats[key] as StandardMaterial3D
		if material == null:
			errors.append("material is not StandardMaterial3D: %s" % key)
			continue
		if not _color_finite(material.albedo_color):
			errors.append("invalid albedo for %s" % key)
		if material.metallic < 0.0 or material.metallic > 1.0:
			errors.append("metallic out of range for %s" % key)
		if material.roughness < 0.0 or material.roughness > 1.0:
			errors.append("roughness out of range for %s" % key)
		if material.emission_enabled:
			if not _color_finite(material.emission):
				errors.append("invalid emission for %s" % key)
			if material.emission_energy_multiplier < 0.0 or material.emission_energy_multiplier > 2.5:
				errors.append("emission energy out of range for %s" % key)
	return errors


static func _color_finite(color: Color) -> bool:
	return is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and color.r >= 0.0 and color.g >= 0.0 and color.b >= 0.0


static func _configure_stylized_surface_flags(mats: Dictionary) -> void:
	var grass_keys: Array[String] = ["grass_main", "grass_light", "grass_dark", "distant_grass", "leaf_green", "leaf_dark", "leaf_light"]
	var stone_keys: Array[String] = ["stone_main", "stone_dark", "stone_light", "stone_warm", "path_stone", "ruin_stone", "distant_rock"]
	for key in grass_keys:
		var grass_mat: StandardMaterial3D = mats[key] as StandardMaterial3D
		grass_mat.vertex_color_use_as_albedo = true
		grass_mat.cull_mode = BaseMaterial3D.CULL_BACK if key == "distant_grass" else BaseMaterial3D.CULL_DISABLED
	for key in stone_keys:
		var stone_mat: StandardMaterial3D = mats[key] as StandardMaterial3D
		stone_mat.vertex_color_use_as_albedo = false
		stone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
