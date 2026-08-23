extends RefCounted
class_name StylizedLighting

## V18.2 warm afternoon lighting tuned for reference readability.


static func apply(
	world: Node3D,
	environment: Environment,
	sky_material: ProceduralSkyMaterial,
	sun: DirectionalLight3D,
	quality_level: int
) -> void:
	sky_material.sky_top_color = Color("5eb8e8")
	sky_material.sky_horizon_color = Color("a8ddf5")
	sky_material.ground_horizon_color = Color("7eb6d8")
	sky_material.ground_bottom_color = Color("4f8eb8")
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.05
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8ddf5")
	environment.ambient_light_energy = 0.44
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.82
	environment.glow_enabled = quality_level >= 1
	environment.glow_intensity = 0.16 if quality_level == 1 else 0.2
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 1.45
	environment.fog_enabled = true
	environment.fog_light_color = Color("b5d8f2")
	environment.fog_light_energy = 0.34
	environment.fog_density = 0.0014 if quality_level >= 2 else 0.0010
	environment.fog_aerial_perspective = 0.22
	sun.rotation_degrees = Vector3(-42.0, -38.0, 0.0)
	sun.light_color = Color("ffe8b8")
	sun.light_energy = 0.78
	sun.shadow_enabled = quality_level >= 1
	sun.directional_shadow_max_distance = 58.0
