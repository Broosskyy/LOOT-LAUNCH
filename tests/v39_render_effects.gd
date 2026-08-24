extends SceneTree

const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const ShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")
const RenderEffects = preload("res://scripts/environment/stylized/stylized_render_effects.gd")
const CloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")
const VFXController = preload("res://scripts/environment/stylized/stylized_vfx_controller.gd")
const Lighting = preload("res://scripts/environment/stylized/stylized_lighting.gd")

const STEP := 0.033


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(ShaderLibrary.validate_shaders().is_empty(), "Shader compile validation failed")
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	for quality in [0, 1, 2]:
		var world = World.new()
		root.add_child(world)
		var game_state = root.get_node("GameState")
		game_state.settings.quality = quality
		world.begin(
			{"seed": 3900, "session_id": "v39-render-q%d" % quality, "world_key": "wolkengarten"},
			"bouncer",
			"standard",
			false,
			0
		)
		await process_frame
		var palette_errors: Array[String] = MaterialLibrary.validate_palette(world.mats)
		assert(palette_errors.is_empty(), "Palette validation failed: %s" % ", ".join(palette_errors))
		var world_env: WorldEnvironment = Lighting.find_world_environment(world)
		assert(world_env != null and world_env.environment != null, "WorldEnvironment required")
		assert(Lighting.count_directional_lights(world) == 1, "Exactly one sun expected")
		assert(world.has_meta("v39_render_applied"), "V39 render apply meta required")
		var profile: Dictionary = RenderEffects.quality_profile(quality)
		var env: Environment = world_env.environment
		assert(is_finite(env.tonemap_exposure) and env.tonemap_exposure > 0.0, "Exposure must be finite")
		assert(env.background_mode == Environment.BG_SKY, "Sky background required")
		assert(env.sky != null, "Sky resource required")
		assert(bool(profile.fog_enabled) == env.fog_enabled, "Fog tier mismatch at Q%d" % quality)
		if quality >= 1:
			assert(world.mats["cloud_far"] is ShaderMaterial, "Q1+ far cloud shader required")
			assert(world.mats["waterfall"] is ShaderMaterial, "Q1+ waterfall water shader required")
		var validation_errors: Array[String] = RenderEffects.validate(world, quality)
		assert(validation_errors.is_empty(), "Render validation failed: %s" % ", ".join(validation_errors))
		var puff_count: int = CloudGenerator.count_puffs_in_world(world)
		assert(puff_count >= 0 and puff_count <= RenderEffects.MAX_CLOUD_PUFFS, "Cloud puff cap violated: %d" % puff_count)
		var perf: Dictionary = RenderEffects.performance_report(world)
		assert(int(perf.shaders) == RenderEffects.SHADER_COUNT, "Shader budget mismatch")
		assert(VFXController.clamp_active_particles(0, quality), "Particle cap helper failed")
		world.queue_free()
		await process_frame
	print("V39 render effects validation passed: shaders=%d" % RenderEffects.SHADER_COUNT)
	quit(0)
