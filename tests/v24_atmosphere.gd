extends SceneTree

const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const Lighting = preload("res://scripts/environment/stylized/stylized_lighting.gd")
const CloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node("GameState")
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	for quality in [0, 1, 2]:
		game_state.settings.quality = quality
		var world = World.new()
		root.add_child(world)
		world.begin(
			{"seed": 2424, "session_id": "v24-atmosphere-q%d" % quality, "world_key": "wolkengarten"},
			"bouncer",
			"standard",
			false,
			quality
		)
		await process_frame
		var world_env := Lighting.find_world_environment(world)
		assert(world_env != null, "WorldEnvironment required at quality %d" % quality)
		assert(world_env.environment != null, "Environment resource required")
		assert(world.sun != null and world.sun is DirectionalLight3D, "Primary sun required")
		assert(Lighting.count_directional_lights(world) == 1, "Exactly one directional sun expected")
		var palette_errors: Array[String] = MaterialLibrary.validate_palette(world.mats)
		assert(palette_errors.is_empty(), "Palette validation failed: %s" % ", ".join(palette_errors))
		var puff_count := CloudGenerator.count_puffs_in_world(world)
		if quality == 0:
			assert(puff_count <= 12, "Quality 0 cloud puff cap exceeded: %d" % puff_count)
		else:
			assert(puff_count > 0, "Cloud puffs required at quality %d" % quality)
		assert(puff_count <= CloudGenerator.MAX_PUFFS, "Global cloud puff cap exceeded")
		assert(world.clouds.size() <= CloudGenerator.MAX_CLOUD_ROOTS, "Cloud root cap exceeded")
		world.queue_free()
		await process_frame
	print("V24 atmosphere validation passed")
	quit(0)
