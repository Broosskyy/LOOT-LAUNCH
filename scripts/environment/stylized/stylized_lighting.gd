extends RefCounted
class_name StylizedLighting

## V24 bright stylized daylight — warm sun, cool sky, soft shadows, tiered atmosphere.


static func apply(
	_world: Node3D,
	environment: Environment,
	sky_material: ProceduralSkyMaterial,
	sun: DirectionalLight3D,
	quality_level: int
) -> void:
	sky_material.sky_top_color = Color("68c4f0")
	sky_material.sky_horizon_color = Color("b8e4f8")
	sky_material.ground_horizon_color = Color("88c0e0")
	sky_material.ground_bottom_color = Color("5a9ec8")
	sky_material.sun_angle_max = 16.0
	sky_material.sun_curve = 0.04
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c0dff5")
	environment.ambient_light_energy = 0.48 if quality_level >= 1 else 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.86 if quality_level >= 2 else 0.84
	environment.glow_enabled = quality_level >= 1
	environment.glow_intensity = 0.12 if quality_level == 1 else 0.14
	environment.glow_bloom = 0.03
	environment.glow_hdr_threshold = 1.55
	environment.fog_light_color = Color("b8dcf0")
	environment.fog_light_energy = 0.38
	if quality_level >= 2:
		environment.fog_enabled = true
		environment.fog_density = 0.00135
		environment.fog_aerial_perspective = 0.28
	elif quality_level == 1:
		environment.fog_enabled = true
		environment.fog_density = 0.00085
		environment.fog_aerial_perspective = 0.18
	else:
		environment.fog_enabled = false
		environment.fog_density = 0.0
		environment.fog_aerial_perspective = 0.0
	sun.rotation_degrees = Vector3(-40.0, -36.0, 0.0)
	sun.light_color = Color("fff0c8")
	sun.light_energy = 0.82 if quality_level >= 2 else 0.76
	sun.shadow_enabled = quality_level >= 1
	sun.directional_shadow_max_distance = 62.0 if quality_level >= 2 else 52.0
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.1
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL


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
