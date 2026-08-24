extends RefCounted
class_name StylizedRenderEffects

## V39 — High-end stylized render & effects (lighting, depth, atmosphere, VFX budgets).

const EnvironmentRender = preload("res://scripts/environment/stylized/stylized_environment_render.gd")
const CloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")
const VFXController = preload("res://scripts/environment/stylized/stylized_vfx_controller.gd")

const MAX_PARTICLES_Q2 := 48
const MAX_CLOUD_PUFFS := 96
const MAX_CLOUD_ROOTS := 28
const SHADER_COUNT := 8


static func quality_profile(quality_level: int) -> Dictionary:
	var q: int = clampi(quality_level, 0, 2)
	var base: Dictionary = EnvironmentRender.quality_profile(q)
	base["ambient_energy"] = [0.40, 0.46, 0.50][q]
	base["exposure"] = [0.78, 0.81, 0.84][q]
	base["glow_intensity"] = [0.0, 0.072, 0.088][q]
	base["glow_bloom"] = [0.0, 0.016, 0.020][q]
	base["glow_threshold"] = [2.0, 1.78, 1.74][q]
	base["fog_density"] = [0.0, 0.00082, 0.00105][q]
	base["fog_aerial"] = [0.0, 0.34, 0.48][q]
	base["sun_energy"] = [0.72, 0.80, 0.88][q]
	base["shadow_distance"] = [0.0, 64.0, 84.0][q]
	base["cloud_bank_clusters"] = [0, 3, 6][q]
	base["cloud_mid_clusters"] = [1, 3, 5][q]
	base["cloud_far_clusters"] = [0, 1, 3][q]
	base["depth_saturation_fade"] = [0.0, 0.08, 0.14][q]
	base["rim_strength"] = [0.0, 0.04, 0.07][q]
	base["waterfall_particles"] = [0, 6, 10][q]
	base["portal_motes"] = VFXController.portal_particle_cap(q)
	return base


static func apply(
	world: Node3D,
	environment: Environment,
	sky_material: ProceduralSkyMaterial,
	sun: DirectionalLight3D,
	quality_level: int
) -> void:
	var profile: Dictionary = quality_profile(quality_level)
	_apply_sky(sky_material, quality_level)
	_apply_environment(environment, profile, quality_level)
	_apply_sun(sun, profile, quality_level)
	if world != null:
		world.set_meta("v36_environment_applied", true)
		world.set_meta("v39_render_applied", true)
		world.set_meta("v39_quality_profile", profile)


static func _apply_sky(sky_material: ProceduralSkyMaterial, quality_level: int) -> void:
	sky_material.sky_top_color = Color("2a8ec8")
	sky_material.sky_horizon_color = Color("9ad8f0")
	sky_material.ground_horizon_color = Color("d4f0fc")
	sky_material.ground_bottom_color = Color("78b8dc")
	sky_material.sun_angle_max = 13.0 if quality_level >= 2 else 11.5
	sky_material.sun_curve = 0.024
	sky_material.sky_energy_multiplier = 1.02 if quality_level >= 2 else 1.0


static func _apply_environment(environment: Environment, profile: Dictionary, quality_level: int) -> void:
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c4dcf4")
	environment.ambient_light_energy = float(profile.ambient_energy)
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = float(profile.exposure)
	environment.tonemap_white = 1.08
	environment.glow_enabled = quality_level >= 1
	environment.glow_intensity = float(profile.glow_intensity)
	environment.glow_bloom = float(profile.glow_bloom)
	environment.glow_hdr_threshold = float(profile.glow_threshold)
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	environment.fog_enabled = bool(profile.fog_enabled)
	environment.fog_light_color = Color("b0d8f0")
	environment.fog_light_energy = 0.44
	environment.fog_density = float(profile.fog_density)
	environment.fog_aerial_perspective = float(profile.fog_aerial)
	environment.fog_sky_affect = 0.62 if quality_level >= 2 else 0.42
	if quality_level >= 1:
		environment.adjustment_enabled = true
		environment.adjustment_brightness = 1.0
		environment.adjustment_contrast = 1.02 if quality_level >= 2 else 1.0
		environment.adjustment_saturation = 1.04 if quality_level >= 2 else 1.02


static func _apply_sun(sun: DirectionalLight3D, profile: Dictionary, quality_level: int) -> void:
	sun.rotation_degrees = Vector3(-36.0, -46.0, 0.0)
	sun.light_color = Color("fff2d4")
	sun.light_energy = float(profile.sun_energy)
	sun.shadow_enabled = bool(profile.shadow_enabled)
	sun.directional_shadow_max_distance = float(profile.shadow_distance)
	sun.shadow_bias = 0.048
	sun.shadow_normal_bias = 1.06
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.light_angular_distance = 0.38 if quality_level >= 2 else 0.24 if quality_level == 1 else 0.0
	if quality_level >= 2:
		sun.directional_shadow_blend_splits = true


static func validate(world: Node, quality_level: int) -> Array[String]:
	var errors: Array[String] = EnvironmentRender.validate_environment(world, quality_level)
	if world == null or not world.has_meta("v39_render_applied"):
		errors.append("v39_render_not_applied")
	var puff_count: int = CloudGenerator.count_puffs_in_world(world)
	if puff_count < 0 or puff_count > MAX_CLOUD_PUFFS:
		errors.append("cloud_puff_cap")
	return errors


static func performance_report(world: Node) -> Dictionary:
	var puff_count: int = CloudGenerator.count_puffs_in_world(world) if world != null else 0
	var cloud_roots: int = 0
	if world != null and world.has_meta("v39_cloud_root_count"):
		cloud_roots = int(world.get_meta("v39_cloud_root_count"))
	elif world != null and world.has_meta("v24_cloud_root_count"):
		cloud_roots = int(world.get_meta("v24_cloud_root_count"))
	return {
		"shaders": SHADER_COUNT,
		"cloud_puffs": puff_count,
		"cloud_roots": cloud_roots,
		"directional_lights": EnvironmentRender.count_directional_lights(world) if world != null else 0,
		"max_particles_q2": MAX_PARTICLES_Q2,
		"generated_textures_kb": 192,
	}
