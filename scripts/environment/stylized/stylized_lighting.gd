extends RefCounted
class_name StylizedLighting

## V26 stylized daylight — refined exposure, grounding shadows, cool ambient fill.


static func apply(
	_world: Node3D,
	environment: Environment,
	sky_material: ProceduralSkyMaterial,
	sun: DirectionalLight3D,
	quality_level: int
) -> void:
	sky_material.sky_top_color = Color("62bce8")
	sky_material.sky_horizon_color = Color("b0ddf5")
	sky_material.ground_horizon_color = Color("84bcd8")
	sky_material.ground_bottom_color = Color("5898c0")
	sky_material.sun_angle_max = 14.0
	sky_material.sun_curve = 0.035
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8d8f0")
	environment.ambient_light_energy = 0.50 if quality_level >= 2 else 0.44 if quality_level == 1 else 0.40
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.80 if quality_level >= 2 else 0.78
	environment.tonemap_white = 1.15
	environment.glow_enabled = quality_level >= 1
	environment.glow_intensity = 0.10 if quality_level == 1 else 0.11
	environment.glow_bloom = 0.025
	environment.glow_hdr_threshold = 1.68
	environment.fog_light_color = Color("b4d8ec")
	environment.fog_light_energy = 0.36
	if quality_level >= 2:
		environment.fog_enabled = true
		environment.fog_density = 0.00128
		environment.fog_aerial_perspective = 0.30
	elif quality_level == 1:
		environment.fog_enabled = true
		environment.fog_density = 0.0008
		environment.fog_aerial_perspective = 0.20
	else:
		environment.fog_enabled = false
		environment.fog_density = 0.0
		environment.fog_aerial_perspective = 0.0
	sun.rotation_degrees = Vector3(-40.0, -36.0, 0.0)
	sun.light_color = Color("fff2cc")
	sun.light_energy = 0.80 if quality_level >= 2 else 0.74
	sun.shadow_enabled = quality_level >= 1
	sun.directional_shadow_max_distance = 64.0 if quality_level >= 2 else 54.0
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.05
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	if quality_level >= 2:
		sun.directional_shadow_blend_splits = true


static func count_directional_lights(world: Node) -> int:
	var count := 0
	for child in world.get_children():
		if child is DirectionalLight3D:
			count += 1
	return count


static func find_world_environment(world: Node) -> WorldEnvironment:
	for child in world.get_children():
		if child is WorldEnvironment:
			return child as WorldEnvironment
	return null
