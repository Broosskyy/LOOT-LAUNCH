extends RefCounted
class_name StylizedShaderLibrary

## V26 — GLES-friendly stylized surface shaders (no texture inputs).


const GRASS_SHADER := preload("res://shaders/stylized/stylized_grass.gdshader")
const ROCK_SHADER := preload("res://shaders/stylized/stylized_rock.gdshader")
const CLOUD_SHADER := preload("res://shaders/stylized/stylized_cloud.gdshader")


static func grass_material(color: Color, roughness: float = 0.94, wind_strength: float = 0.055, wind_speed: float = 1.12) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("roughness", roughness)
	mat.set_shader_parameter("variation_strength", 0.08)
	mat.set_shader_parameter("wind_strength", wind_strength)
	mat.set_shader_parameter("wind_speed", wind_speed)
	mat.set_shader_parameter("wind_phase", 0.0)
	return mat


static func rock_material(
	color: Color,
	roughness: float = 0.93,
	metallic: float = 0.0,
	cool_shadow: float = 0.12,
	warm_highlight: float = 0.08
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("roughness", roughness)
	mat.set_shader_parameter("metallic", metallic)
	mat.set_shader_parameter("cool_shadow", cool_shadow)
	mat.set_shader_parameter("warm_highlight", warm_highlight)
	return mat


static func cloud_material(top: Color, bottom: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CLOUD_SHADER
	mat.set_shader_parameter("top_color", top)
	mat.set_shader_parameter("bottom_color", bottom)
	mat.set_shader_parameter("roughness", 1.0)
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
	var errors: Array[String] = []
	for path in [
		"res://shaders/stylized/stylized_grass.gdshader",
		"res://shaders/stylized/stylized_rock.gdshader",
		"res://shaders/stylized/stylized_cloud.gdshader",
	]:
		var shader: Shader = load(path)
		if shader == null:
			errors.append("missing shader: %s" % path)
	return errors
