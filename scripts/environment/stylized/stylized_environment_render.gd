extends RefCounted
class_name StylizedEnvironmentRender

## V36 — Central stylized environment rendering (sun, sky, fog, exposure, glow).


static func quality_profile(quality_level: int) -> Dictionary:
	var q: int = clampi(quality_level, 0, 2)
	return {
		"ambient_energy": [0.42, 0.48, 0.54][q],
		"exposure": [0.77, 0.79, 0.82][q],
		"glow_intensity": [0.0, 0.085, 0.095][q],
		"glow_bloom": [0.0, 0.020, 0.022][q],
		"glow_threshold": [2.0, 1.72, 1.70][q],
		"fog_enabled": q >= 1,
		"fog_density": [0.0, 0.00088, 0.00115][q],
		"fog_aerial": [0.0, 0.30, 0.44][q],
		"sun_energy": [0.70, 0.76, 0.82][q],
		"shadow_distance": [0.0, 62.0, 78.0][q],
		"shadow_enabled": q >= 1,
		"cloud_bank_clusters": [0, 2, 5][q],
		"cloud_mid_clusters": [1, 2, 4][q],
	}


static func apply(
	world: Node3D,
	environment: Environment,
	sky_material: ProceduralSkyMaterial,
	sun: DirectionalLight3D,
	quality_level: int
) -> void:
	var profile: Dictionary = quality_profile(quality_level)
	_apply_sky(sky_material)
	_apply_environment(environment, profile, quality_level)
	_apply_sun(sun, profile, quality_level)
	if world != null:
		world.set_meta("v36_environment_applied", true)
		world.set_meta("v36_quality_profile", profile)


static func _apply_sky(sky_material: ProceduralSkyMaterial) -> void:
	sky_material.sky_top_color = Color("4aabdd")
	sky_material.sky_horizon_color = Color("a8d8f4")
	sky_material.ground_horizon_color = Color("8ec8e8")
	sky_material.ground_bottom_color = Color("68b4d8")
	sky_material.sun_angle_max = 11.0
	sky_material.sun_curve = 0.028
	sky_material.sky_energy_multiplier = 1.0


static func _apply_environment(environment: Environment, profile: Dictionary, quality_level: int) -> void:
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c8e2f8")
	environment.ambient_light_energy = float(profile.ambient_energy)
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = float(profile.exposure)
	environment.tonemap_white = 1.10
	environment.glow_enabled = quality_level >= 1
	environment.glow_intensity = float(profile.glow_intensity)
	environment.glow_bloom = float(profile.glow_bloom)
	environment.glow_hdr_threshold = float(profile.glow_threshold)
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	environment.fog_enabled = bool(profile.fog_enabled)
	environment.fog_light_color = Color("b4dcf0")
	environment.fog_light_energy = 0.40
	environment.fog_density = float(profile.fog_density)
	environment.fog_aerial_perspective = float(profile.fog_aerial)
	environment.fog_sky_affect = 0.55 if quality_level >= 2 else 0.35


static func _apply_sun(sun: DirectionalLight3D, profile: Dictionary, quality_level: int) -> void:
	sun.rotation_degrees = Vector3(-34.0, -48.0, 0.0)
	sun.light_color = Color("fff4d8")
	sun.light_energy = float(profile.sun_energy)
	sun.shadow_enabled = bool(profile.shadow_enabled)
	sun.directional_shadow_max_distance = float(profile.shadow_distance)
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.15
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.light_angular_distance = 0.35 if quality_level >= 2 else 0.22 if quality_level == 1 else 0.0
	if quality_level >= 2:
		sun.directional_shadow_blend_splits = true


static func find_world_environment(world: Node) -> WorldEnvironment:
	for child in world.get_children():
		if child is WorldEnvironment:
			return child as WorldEnvironment
	return null


static func count_directional_lights(world: Node) -> int:
	var count := 0
	for child in world.get_children():
		if child is DirectionalLight3D:
			count += 1
	return count


static func validate_environment(world: Node, quality_level: int) -> Array[String]:
	var errors: Array[String] = []
	var world_env := find_world_environment(world)
	if world_env == null or world_env.environment == null:
		errors.append("missing_world_environment")
		return errors
	var env: Environment = world_env.environment
	if not is_finite(env.tonemap_exposure) or env.tonemap_exposure <= 0.0:
		errors.append("invalid_exposure")
	if env.fog_enabled and (not is_finite(env.fog_density) or env.fog_density < 0.0):
		errors.append("invalid_fog_density")
	if count_directional_lights(world) != 1:
		errors.append("directional_light_count")
	var profile: Dictionary = quality_profile(quality_level)
	if bool(profile.fog_enabled) != env.fog_enabled:
		errors.append("fog_tier_mismatch")
	return errors
