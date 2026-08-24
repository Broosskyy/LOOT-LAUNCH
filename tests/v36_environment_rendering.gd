extends SceneTree

const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const ShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")
const EnvironmentRender = preload("res://scripts/environment/stylized/stylized_environment_render.gd")
const CloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")
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
			{"seed": 3600, "session_id": "v36-render-q%d" % quality, "world_key": "wolkengarten"},
			"bouncer",
			"standard",
			false,
			0
		)
		await process_frame
		var palette_errors: Array[String] = MaterialLibrary.validate_palette(world.mats)
		assert(palette_errors.is_empty(), "Palette validation failed: %s" % ", ".join(palette_errors))
		var world_env: WorldEnvironment = EnvironmentRender.find_world_environment(world)
		assert(world_env != null and world_env.environment != null, "WorldEnvironment required")
		assert(EnvironmentRender.count_directional_lights(world) == 1, "Exactly one sun expected")
		assert(world.has_meta("v36_environment_applied"), "V36 environment apply meta required")
		var profile: Dictionary = EnvironmentRender.quality_profile(quality)
		var env: Environment = world_env.environment
		assert(is_finite(env.tonemap_exposure) and env.tonemap_exposure > 0.0, "Exposure must be finite")
		assert(env.background_mode == Environment.BG_SKY, "Sky background required")
		assert(env.sky != null, "Sky resource required")
		assert(bool(profile.fog_enabled) == env.fog_enabled, "Fog tier mismatch at Q%d" % quality)
		if quality >= 1:
			assert(world.mats["grass_main"] is ShaderMaterial, "Q1+ grass shader required")
			assert(world.mats["stone_main"] is ShaderMaterial, "Q1+ rock shader required")
			assert(world.mats["cloud"] is ShaderMaterial, "Q1+ cloud shader required")
			assert(world.mats["water"] is ShaderMaterial, "Q1+ water shader required")
		var validation_errors: Array[String] = EnvironmentRender.validate_environment(world, quality)
		assert(validation_errors.is_empty(), "Environment validation failed: %s" % ", ".join(validation_errors))
		var puff_count: int = CloudGenerator.count_puffs_in_world(world)
		assert(puff_count >= 0 and puff_count <= 96, "Cloud puff cap violated: %d" % puff_count)
		world.queue_free()
		await process_frame
	# Backward-compatible lighting wrapper.
	var legacy_world = World.new()
	root.add_child(legacy_world)
	legacy_world.begin(
		{"seed": 3601, "session_id": "v36-lighting-wrap", "world_key": "wolkengarten"},
		"bouncer",
		"standard",
		false,
		2
	)
	await process_frame
	assert(Lighting.find_world_environment(legacy_world) != null, "Lighting wrapper must find WorldEnvironment")
	assert(Lighting.count_directional_lights(legacy_world) == 1, "Lighting wrapper sun count")
	legacy_world.queue_free()
	print("V36 environment rendering validation passed")
	quit(0)
