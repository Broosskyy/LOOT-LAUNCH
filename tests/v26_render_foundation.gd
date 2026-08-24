extends SceneTree

const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const ShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")
const Lighting = preload("res://scripts/environment/stylized/stylized_lighting.gd")


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
			{"seed": 2626, "session_id": "v26-render-q%d" % quality, "world_key": "wolkengarten"},
			"bouncer",
			"standard",
			false,
			0
		)
		await process_frame
		var palette_errors: Array[String] = MaterialLibrary.validate_palette(world.mats)
		assert(palette_errors.is_empty(), "Palette validation failed: %s" % ", ".join(palette_errors))
		assert(Lighting.find_world_environment(world) != null, "WorldEnvironment required")
		assert(Lighting.count_directional_lights(world) == 1, "Exactly one sun expected")
		if quality >= 1:
			assert(world.mats["grass_main"] is ShaderMaterial, "Q1+ grass should use shader")
			assert(world.mats["stone_main"] is ShaderMaterial, "Q1+ rock should use shader")
			assert(world.mats["cloud"] is ShaderMaterial, "Q1+ cloud should use shader")
		else:
			assert(world.mats["grass_main"] is StandardMaterial3D, "Q0 grass should use standard material")
		world.queue_free()
		await process_frame
	print("V26 render foundation validation passed")
	quit(0)
