extends SceneTree

const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const ShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")
const ProcTex = preload("res://scripts/environment/stylized/stylized_procedural_textures.gd")
const SurfaceLib = preload("res://scripts/environment/stylized/stylized_surface_library.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(ShaderLibrary.validate_shaders().is_empty(), "Shader validation failed")
	ProcTex.ensure_baked()
	assert(ProcTex.memory_estimate_kb() <= 512, "Procedural texture memory too high")
	var tex_errors: Array[String] = ProcTex.validate()
	assert(tex_errors.is_empty(), "Texture validation failed: %s" % ", ".join(tex_errors))
	for quality in [0, 1, 2]:
		var mats := {}
		MaterialLibrary.apply_palette(
			mats,
			func(c: Color, r: float, m: float, _e := Color.BLACK, _en := 0.0) -> StandardMaterial3D:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = c
				mat.roughness = r
				mat.metallic = m
				return mat,
			func(c: Color) -> StandardMaterial3D:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = c
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				return mat,
			quality
		)
		var errors: Array[String] = MaterialLibrary.validate_palette(mats)
		assert(errors.is_empty(), "Palette Q%d failed: %s" % [quality, ", ".join(errors)])
		if quality >= 1:
			assert(mats["grass_main"] is ShaderMaterial, "Q1+ grass shader required")
			assert(mats["stone_main"] is ShaderMaterial, "Q1+ rock shader required")
			assert(mats["wood"] is ShaderMaterial, "Q1+ wood shader required")
			assert(mats["brass"] is ShaderMaterial, "Q1+ brass shader required")
			assert(mats["cannon_dark"] is ShaderMaterial, "Q1+ metal shader required")
			assert(mats["crystal_violet"] is ShaderMaterial, "Q1+ crystal shader required")
			assert(mats["leaf_green"] is ShaderMaterial, "Q1+ leaf shader required")
		else:
			assert(mats["grass_main"] is StandardMaterial3D, "Q0 grass standard required")
	var profile: Dictionary = SurfaceLib.quality_profile(2)
	assert(bool(profile.use_macro_textures), "Q2 macro textures required")
	print("V38 surface texture detail validation passed: tex_kb=%d shaders=8" % ProcTex.memory_estimate_kb())
	quit(0)
