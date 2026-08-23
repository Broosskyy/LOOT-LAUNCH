extends RefCounted
class_name StylizedMaterialLibrary

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")

## V18.2 reference-matched palette — muted greens, warm stone, readable cliffs.


static func apply_palette(
	mats: Dictionary,
	material_fn: Callable,
	transparent_fn: Callable
) -> void:
	mats["grass_main"] = StylizedTypedAccess.opaque_material(material_fn, Color("52a862"), 0.9, 0.0)
	mats["grass_light"] = StylizedTypedAccess.opaque_material(material_fn, Color("74c97a"), 0.86, 0.0)
	mats["grass_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("3f9f57"), 0.92, 0.0)
	mats["stone_main"] = StylizedTypedAccess.opaque_material(material_fn, Color("8a868f"), 0.9, 0.0)
	mats["stone_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("6f6b74"), 0.92, 0.0)
	mats["stone_light"] = StylizedTypedAccess.opaque_material(material_fn, Color("b7b0a6"), 0.84, 0.0)
	mats["path_stone"] = StylizedTypedAccess.opaque_material(material_fn, Color("b5a898"), 0.88, 0.0)
	mats["dirt"] = StylizedTypedAccess.opaque_material(material_fn, Color("7a5d45"), 0.94, 0.0)
	mats["wood"] = StylizedTypedAccess.opaque_material(material_fn, Color("6a4228"), 0.86, 0.0)
	mats["wood_light"] = StylizedTypedAccess.opaque_material(material_fn, Color("9a5f36"), 0.8, 0.0)
	mats["brass"] = StylizedTypedAccess.opaque_material(material_fn, Color("c99a3f"), 0.3, 0.72)
	mats["cannon_dark"] = StylizedTypedAccess.opaque_material(material_fn, Color("2f2d3a"), 0.34, 0.62)
	mats["crystal_violet"] = StylizedTypedAccess.opaque_material(material_fn, Color("9b5cff"), 0.2, 0.1, Color("7a42e8"), 0.48)
	mats["crystal_blue"] = StylizedTypedAccess.opaque_material(material_fn, Color("5ec8ff"), 0.18, 0.08, Color("35a8f0"), 0.38)
	mats["portal"] = StylizedTypedAccess.opaque_material(material_fn, Color("8f4dff"), 0.22, 0.12, Color("6b2fe8"), 0.72)
	mats["flower_pink"] = StylizedTypedAccess.opaque_material(material_fn, Color("f08cbc"), 0.44, 0.0, Color("d85f9d"), 0.12)
	mats["flower_white"] = StylizedTypedAccess.opaque_material(material_fn, Color("fff5ef"), 0.48, 0.0)
	mats["leaf_green"] = StylizedTypedAccess.opaque_material(material_fn, Color("4aab5d"), 0.82, 0.0)
	mats["coin"] = StylizedTypedAccess.opaque_material(material_fn, Color("e8b840"), 0.2, 0.78, Color("d9a020"), 0.28)
	mats["cloud_soft"] = StylizedTypedAccess.opaque_material(material_fn, Color("f6f9ff"), 1.0, 0.0)
	mats["cloud_mid"] = StylizedTypedAccess.opaque_material(material_fn, Color("eef4ff"), 1.0, 0.0)
	mats["distant_grass"] = StylizedTypedAccess.opaque_material(material_fn, Color("6a9f78"), 0.92, 0.0)
	mats["distant_rock"] = StylizedTypedAccess.opaque_material(material_fn, Color("9aa0ad"), 0.94, 0.0)
	mats["bouncer"] = StylizedTypedAccess.opaque_material(material_fn, Color("f0a878"), 0.46, 0.02, Color("e88958"), 0.08)
	mats["cheek"] = StylizedTypedAccess.opaque_material(material_fn, Color("ff96aa"), 0.5, 0.0)
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
	mats["cliff_warm"] = mats["stone_light"]
	mats["edge_moss"] = mats["grass_dark"]
	mats["crystal"] = mats["crystal_violet"]
	mats["violet"] = mats["portal"]
	mats["white"] = mats["stone_light"]
	mats["cannon"] = mats["cannon_dark"]
	mats["cloud"] = StylizedTypedAccess.opaque_material(material_fn, Color("f2f6ff"), 1.0, 0.0)


static func _configure_stylized_surface_flags(mats: Dictionary) -> void:
	var grass_keys: Array[String] = ["grass_main", "grass_light", "grass_dark", "distant_grass"]
	var stone_keys: Array[String] = ["stone_main", "stone_dark", "stone_light", "path_stone", "distant_rock"]
	for key in grass_keys:
		var grass_mat: StandardMaterial3D = mats[key] as StandardMaterial3D
		grass_mat.vertex_color_use_as_albedo = true
		grass_mat.cull_mode = BaseMaterial3D.CULL_BACK if key == "distant_grass" else BaseMaterial3D.CULL_DISABLED
	for key in stone_keys:
		var stone_mat: StandardMaterial3D = mats[key] as StandardMaterial3D
		stone_mat.vertex_color_use_as_albedo = false
		stone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
