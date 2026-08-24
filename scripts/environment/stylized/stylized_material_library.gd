extends RefCounted
class_name StylizedMaterialLibrary

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const StylizedShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")
const StylizedMotionController = preload("res://scripts/environment/stylized/stylized_motion_controller.gd")
const SurfaceLib = preload("res://scripts/environment/stylized/stylized_surface_library.gd")

## V26/V38 render foundation — muted palette + Surface 3.0 stylized shaders.


static func apply_palette(
	mats: Dictionary,
	material_fn: Callable,
	transparent_fn: Callable,
	quality_level: int = 2
) -> void:
	var use_shaders: bool = quality_level >= 1
	# Grass family
	mats["grass_main"] = _grass_surface(use_shaders, material_fn, Color("448a52"), 0.93, "main", quality_level)
	mats["grass_light"] = _grass_surface(use_shaders, material_fn, Color("5ea662"), 0.91, "light", quality_level)
	mats["grass_dark"] = _grass_surface(use_shaders, material_fn, Color("367a44"), 0.94, "dark", quality_level)
	# Rock / cliff family
	mats["stone_main"] = _rock_surface(use_shaders, material_fn, Color("8e8880"), 0.93, SurfaceLib.StoneFamily.CLIFF, quality_level)
	mats["stone_dark"] = _rock_surface(use_shaders, material_fn, Color("6e6862"), 0.94, SurfaceLib.StoneFamily.CLIFF, quality_level)
	mats["stone_light"] = _rock_surface(use_shaders, material_fn, Color("b4aca0"), 0.89, SurfaceLib.StoneFamily.ARCHITECTURE, quality_level)
	mats["path_stone"] = _rock_surface(use_shaders, material_fn, Color("c4b8a6"), 0.88, SurfaceLib.StoneFamily.PATH, quality_level)
	mats["stone_warm"] = _rock_surface(use_shaders, material_fn, Color("a89888"), 0.9, SurfaceLib.StoneFamily.CLIFF, quality_level)
	mats["ruin_stone"] = _rock_surface(use_shaders, material_fn, Color("a89a8a"), 0.91, SurfaceLib.StoneFamily.RUIN, quality_level)
	mats["dirt"] = StylizedShaderLibrary.standard_surface(material_fn, Color("7a5d45"), 0.95, 0.0)
	mats["wood"] = _wood_surface(use_shaders, material_fn, Color("6a4228"), 0.9, quality_level)
	mats["wood_dark"] = _wood_surface(use_shaders, material_fn, Color("4a3020"), 0.92, quality_level)
	mats["wood_light"] = _wood_surface(use_shaders, material_fn, Color("9a5f36"), 0.86, quality_level)
	mats["brass"] = _metal_surface(use_shaders, material_fn, Color("b88830"), SurfaceLib.MetalFamily.BRASS, quality_level)
	mats["cannon_dark"] = _metal_surface(use_shaders, material_fn, Color("2c2f3a"), SurfaceLib.MetalFamily.DARK_METAL, quality_level)
	mats["crystal_violet"] = _crystal_surface(use_shaders, material_fn, Color("9068e0"), Color("6840d0"), Color("5830b8"), 0.36, quality_level, true)
	mats["crystal_blue"] = _crystal_surface(use_shaders, material_fn, Color("58b0e0"), Color("3898d0"), Color("2878b8"), 0.30, quality_level, false)
	mats["portal"] = _crystal_surface(use_shaders, material_fn, Color("7a48d8"), Color("5830b8"), Color("4828a0"), 0.44, quality_level, true)
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
	mats["leaf_green"] = _leaf_surface(use_shaders, material_fn, Color("488850"), 0.88, quality_level)
	mats["leaf_dark"] = _leaf_surface(use_shaders, material_fn, Color("3a8044"), 0.9, quality_level)
	mats["leaf_light"] = _leaf_surface(use_shaders, material_fn, Color("68a868"), 0.88, quality_level)
	mats["trunk"] = _wood_surface(use_shaders, material_fn, Color("7a5230"), 0.92, quality_level)
	mats["coin"] = _metal_surface(use_shaders, material_fn, Color("d0a030"), SurfaceLib.MetalFamily.BRASS, quality_level)
	mats["cloud_soft"] = _cloud_surface(use_shaders, material_fn, Color("fafcff"), Color("c8d8ec"), 0.06, 0.0)
	mats["cloud_mid"] = _cloud_surface(use_shaders, material_fn, Color("f2f8ff"), Color("bccede"), 0.08, 0.08)
	mats["cloud_shadow"] = _cloud_surface(use_shaders, material_fn, Color("e8f2fc"), Color("a8bdd4"), 0.10, 0.0)
	mats["cloud_far"] = _cloud_surface(use_shaders, material_fn, Color("f6fbff"), Color("d0e4f4"), 0.05, 0.18)
	mats["distant_grass"] = _grass_surface(use_shaders, material_fn, Color("7a9888"), 0.95, "dark", quality_level)
	mats["distant_rock"] = _rock_surface(use_shaders, material_fn, Color("98a4b0"), 0.96, SurfaceLib.StoneFamily.CLIFF, quality_level)
	mats["bouncer"] = StylizedShaderLibrary.standard_surface(
		material_fn, Color("f0a878"), 0.5, 0.02, Color("e88958"), 0.08 if quality_level >= 2 else 0.05
	)
	mats["cheek"] = StylizedShaderLibrary.standard_surface(material_fn, Color("ff96aa"), 0.52, 0.0)
	# V21 hero aliases
	mats["cannon_dark_metal"] = mats["cannon_dark"]
	mats["brass_gold"] = mats["brass"]
	mats["chest_wood"] = mats["wood"]
	mats["chest_metal"] = mats["brass"]
	mats["portal_stone"] = mats["ruin_stone"]
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
	mats["water"] = _water_surface(use_shaders, transparent_fn, quality_level, false)
	mats["waterfall"] = _water_surface(use_shaders, transparent_fn, quality_level, true)


static func _grass_surface(
	use_shaders: bool,
	material_fn: Callable,
	color: Color,
	roughness: float,
	variant: String,
	quality_level: int
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.grass_material(color, roughness, variant, quality_level)
	return StylizedShaderLibrary.standard_surface(material_fn, color, roughness, 0.0)


static func _rock_surface(
	use_shaders: bool,
	material_fn: Callable,
	color: Color,
	roughness: float,
	family: int,
	quality_level: int
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.rock_material(color, roughness, 0.0, family, quality_level)
	return StylizedShaderLibrary.standard_surface(material_fn, color, roughness, 0.0)


static func _wood_surface(
	use_shaders: bool,
	material_fn: Callable,
	color: Color,
	roughness: float,
	quality_level: int
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.wood_material(color, roughness, quality_level)
	return StylizedShaderLibrary.standard_surface(material_fn, color, roughness, 0.0)


static func _metal_surface(
	use_shaders: bool,
	material_fn: Callable,
	color: Color,
	family: int,
	quality_level: int
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.metal_material(color, family, quality_level)
	return StylizedShaderLibrary.standard_surface(material_fn, color, 0.38 if family == SurfaceLib.MetalFamily.BRASS else 0.42, 0.72 if family == SurfaceLib.MetalFamily.BRASS else 0.62)


static func _crystal_surface(
	use_shaders: bool,
	material_fn: Callable,
	base: Color,
	core: Color,
	emission: Color,
	energy: float,
	quality_level: int,
	hero: bool = false
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.crystal_material(base, core, emission, energy, quality_level, hero)
	return StylizedShaderLibrary.standard_surface(material_fn, base, 0.24, 0.06, emission, energy)


static func _leaf_surface(
	use_shaders: bool,
	material_fn: Callable,
	color: Color,
	roughness: float,
	quality_level: int
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.leaf_material(color, roughness, quality_level)
	return StylizedShaderLibrary.standard_surface(material_fn, color, roughness, 0.0)


static func _water_surface(use_shaders: bool, transparent_fn: Callable, quality_level: int, waterfall := false) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.water_material(
			Color(0.44, 0.88, 0.99, 0.74) if waterfall else Color(0.42, 0.86, 0.98, 0.72),
			Color(0.20, 0.58, 0.86, 0.84) if waterfall else Color(0.22, 0.62, 0.88, 0.82),
			quality_level,
			waterfall
		)
	return transparent_fn.call(Color(0.32, 0.87, 1.0, 0.48) if waterfall else Color(0.28, 0.82, 1.0, 0.52)) as Material


static func _cloud_surface(
	use_shaders: bool,
	material_fn: Callable,
	top: Color,
	bottom: Color,
	side_shade: float = 0.07,
	depth_fade: float = 0.0
) -> Material:
	if use_shaders:
		return StylizedShaderLibrary.cloud_material(top, bottom, side_shade, depth_fade)
	return StylizedShaderLibrary.standard_surface(material_fn, top, 1.0, 0.0)


static func validate_palette(mats: Dictionary) -> Array[String]:
	var errors: Array[String] = StylizedShaderLibrary.validate_shaders()
	var required: Array[String] = [
		"grass_main", "grass_light", "grass_dark", "stone_main", "stone_dark", "stone_light",
		"path_stone", "ruin_stone", "wood", "wood_dark", "brass", "cannon_dark",
		"leaf_green", "leaf_light", "leaf_dark", "portal_energy", "pad_energy",
		"crystal_violet", "crystal_blue", "cloud", "cloud_shadow", "cloud_far", "distant_grass", "distant_rock", "water", "waterfall",
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
