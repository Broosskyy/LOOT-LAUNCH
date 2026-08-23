extends RefCounted
class_name StylizedLighting

## Warm afternoon stylized lighting for Wolkengarten V18.


static func apply(
	world: Node3D,
	environment: Environment,
	sky_material: ProceduralSkyMaterial,
	sun: DirectionalLight3D,
	quality_level: int
) -> void:
	sky_material.sky_top_color = Color("4a8fd4")
	sky_material.sky_horizon_color = Color("9fd0f5")
	sky_material.ground_horizon_color = Color("5a8ab8")
	sky_material.ground_bottom_color = Color("3a6a94")
	sky_material.sun_angle_max = 16.0
	sky_material.sun_curve = 0.06
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8d8f5")
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = quality_level >= 1
	environment.glow_intensity = 0.22 if quality_level == 1 else 0.28
	environment.glow_bloom = 0.06
	environment.glow_hdr_threshold = 1.35
	if quality_level >= 2:
		environment.fog_enabled = true
		environment.fog_light_color = Color("b8d4f0")
		environment.fog_light_energy = 0.28
		environment.fog_density = 0.0012
	sun.rotation_degrees = Vector3(-46.0, -34.0, 0.0)
	sun.light_color = Color("fff0c8")
	sun.light_energy = 0.88
	sun.shadow_enabled = quality_level >= 1
	sun.directional_shadow_max_distance = 52.0
