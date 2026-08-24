extends RefCounted
class_name StylizedLighting

## V26/V36/V39 stylized daylight — delegates to StylizedRenderEffects.

const RenderEffects = preload("res://scripts/environment/stylized/stylized_render_effects.gd")
const EnvironmentRender = preload("res://scripts/environment/stylized/stylized_environment_render.gd")


static func apply(
	world: Node3D,
	environment: Environment,
	sky_material: ProceduralSkyMaterial,
	sun: DirectionalLight3D,
	quality_level: int
) -> void:
	RenderEffects.apply(world, environment, sky_material, sun, quality_level)


static func count_directional_lights(world: Node) -> int:
	return EnvironmentRender.count_directional_lights(world)


static func find_world_environment(world: Node) -> WorldEnvironment:
	return EnvironmentRender.find_world_environment(world)
