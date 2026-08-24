extends RefCounted
class_name StylizedShaderLibrary

## V26/V38 — GLES-friendly stylized surface shaders with optional procedural macro textures.

const SurfaceLib = preload("res://scripts/environment/stylized/stylized_surface_library.gd")
const ProcTex = preload("res://scripts/environment/stylized/stylized_procedural_textures.gd")

const GRASS_SHADER := preload("res://shaders/stylized/stylized_grass.gdshader")
const ROCK_SHADER := preload("res://shaders/stylized/stylized_rock.gdshader")
const CLOUD_SHADER := preload("res://shaders/stylized/stylized_cloud.gdshader")
const WATER_SHADER := preload("res://shaders/stylized/stylized_water.gdshader")
const WOOD_SHADER := preload("res://shaders/stylized/stylized_wood.gdshader")
const METAL_SHADER := preload("res://shaders/stylized/stylized_metal.gdshader")
const CRYSTAL_SHADER := preload("res://shaders/stylized/stylized_crystal.gdshader")
const LEAF_SHADER := preload("res://shaders/stylized/stylized_leaf.gdshader")


static func grass_material(
	color: Color,
	roughness: float = 0.94,
	variant: String = "main",
	quality_level: int = 2,
	wind_strength: float = 0.055,
	wind_speed: float = 1.12
) -> ShaderMaterial:
	var profile: Dictionary = SurfaceLib.quality_profile(quality_level)
	var grass_profile: Dictionary = SurfaceLib.grass_profile(variant)
	ProcTex.ensure_baked()
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("dry_patch_tint", grass_profile.dry_tint)
	mat.set_shader_parameter("roughness", roughness)
	mat.set_shader_parameter("variation_strength", float(profile.vertex_variation) + 0.04)
	mat.set_shader_parameter("macro_strength", float(profile.macro_strength) * float(grass_profile.patch_strength) * 1.85)
	mat.set_shader_parameter("edge_strength", float(grass_profile.edge_strength))
	mat.set_shader_parameter("wind_strength", wind_strength)
	mat.set_shader_parameter("wind_speed", wind_speed)
	mat.set_shader_parameter("wind_phase", 0.0)
	mat.set_shader_parameter("macro_tex", ProcTex.grass_macro())
	return mat


static func rock_material(
	color: Color,
	roughness: float = 0.93,
	metallic: float = 0.0,
	family: int = SurfaceLib.StoneFamily.CLIFF,
	quality_level: int = 2
) -> ShaderMaterial:
	var qprofile: Dictionary = SurfaceLib.quality_profile(quality_level)
	var stone: Dictionary = SurfaceLib.stone_profile(family)
	ProcTex.ensure_baked()
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("secondary_tint", stone.secondary_tint)
	mat.set_shader_parameter("roughness", roughness)
	mat.set_shader_parameter("metallic", metallic)
	mat.set_shader_parameter("cool_shadow", float(stone.cool_shadow))
	mat.set_shader_parameter("warm_highlight", float(stone.warm_highlight))
	mat.set_shader_parameter("macro_strength", float(qprofile.macro_strength))
	mat.set_shader_parameter("macro_mul", float(stone.macro_mul))
	mat.set_shader_parameter("moss_strength", float(stone.moss_strength))
	mat.set_shader_parameter("wet_darken", float(stone.wet_darken))
	mat.set_shader_parameter("macro_tex", ProcTex.rock_macro())
	return mat


static func wood_material(color: Color, roughness: float = 0.90, quality_level: int = 2) -> ShaderMaterial:
	var profile: Dictionary = SurfaceLib.quality_profile(quality_level)
	ProcTex.ensure_baked()
	var mat := ShaderMaterial.new()
	mat.shader = WOOD_SHADER
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("roughness", roughness)
	mat.set_shader_parameter("grain_strength", float(profile.macro_strength) * 0.85)
	mat.set_shader_parameter("grain_tex", ProcTex.wood_grain())
	return mat


static func metal_material(
	color: Color,
	family: int = SurfaceLib.MetalFamily.DARK_METAL,
	quality_level: int = 2
) -> ShaderMaterial:
	var metal: Dictionary = SurfaceLib.metal_profile(family)
	var mat := ShaderMaterial.new()
	mat.shader = METAL_SHADER
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("rim_tint", metal.rim_tint)
	mat.set_shader_parameter("roughness", float(metal.roughness))
	mat.set_shader_parameter("metallic", float(metal.metallic))
	mat.set_shader_parameter("bevel_boost", float(metal.bevel_boost))
	mat.set_shader_parameter("recess_darken", float(metal.recess_darken))
	return mat


static func crystal_material(
	base: Color,
	core: Color,
	emission: Color,
	energy: float,
	quality_level: int = 2,
	hero := false
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CRYSTAL_SHADER
	mat.set_shader_parameter("base_color", base)
	mat.set_shader_parameter("core_color", core)
	mat.set_shader_parameter("emission_color", emission)
	mat.set_shader_parameter("emission_strength", energy)
	mat.set_shader_parameter("roughness", 0.22 if quality_level >= 2 else 0.26)
	mat.set_shader_parameter("pulse_speed", 1.6 if hero else 1.2)
	mat.set_shader_parameter("sparkle_strength", 0.28 if hero and quality_level >= 2 else 0.12 if quality_level >= 1 else 0.0)
	return mat


static func leaf_material(color: Color, roughness: float = 0.88, quality_level: int = 2) -> ShaderMaterial:
	var profile: Dictionary = SurfaceLib.quality_profile(quality_level)
	var mat := ShaderMaterial.new()
	mat.shader = LEAF_SHADER
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("highlight_tint", color.lightened(0.22))
	mat.set_shader_parameter("roughness", roughness)
	mat.set_shader_parameter("variation_strength", float(profile.vertex_variation) + 0.05)
	return mat


static func cloud_material(top: Color, bottom: Color, side_shade: float = 0.07, depth_fade: float = 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CLOUD_SHADER
	mat.set_shader_parameter("top_color", top)
	mat.set_shader_parameter("bottom_color", bottom)
	mat.set_shader_parameter("roughness", 1.0)
	mat.set_shader_parameter("side_shade", side_shade)
	mat.set_shader_parameter("depth_fade", depth_fade)
	return mat


static func water_material(shallow: Color, deep: Color, quality_level: int = 2, waterfall := false) -> ShaderMaterial:
	var profile: Dictionary = SurfaceLib.quality_profile(quality_level)
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("shallow_color", shallow)
	mat.set_shader_parameter("deep_color", deep)
	mat.set_shader_parameter("roughness", 0.16)
	mat.set_shader_parameter("wave_strength", 0.012 if quality_level < 2 else 0.018)
	mat.set_shader_parameter("wave_speed", 0.7 if quality_level < 2 else 0.85)
	mat.set_shader_parameter("flow_strength", float(profile.macro_strength))
	mat.set_shader_parameter("foam_strength", 0.35 if quality_level >= 2 and not waterfall else 0.18 if quality_level >= 1 and not waterfall else 0.0)
	mat.set_shader_parameter("waterfall_mode", 1.0 if waterfall else 0.0)
	mat.render_priority = 1
	return mat


static func standard_surface(
	material_fn: Callable,
	color: Color,
	roughness: float,
	metallic: float,
	emission: Color = Color.BLACK,
	energy: float = 0.0
) -> StandardMaterial3D:
	return material_fn.call(color, roughness, metallic, emission, energy) as StandardMaterial3D


static func validate_shaders() -> Array[String]:
	var errors: Array[String] = ProcTex.validate()
	for path in [
		"res://shaders/stylized/stylized_grass.gdshader",
		"res://shaders/stylized/stylized_rock.gdshader",
		"res://shaders/stylized/stylized_cloud.gdshader",
		"res://shaders/stylized/stylized_water.gdshader",
		"res://shaders/stylized/stylized_wood.gdshader",
		"res://shaders/stylized/stylized_metal.gdshader",
		"res://shaders/stylized/stylized_crystal.gdshader",
		"res://shaders/stylized/stylized_leaf.gdshader",
	]:
		var shader: Shader = load(path)
		if shader == null:
			errors.append("missing shader: %s" % path)
	return errors
