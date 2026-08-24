extends SceneTree

const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const ShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")
const VisualMaster = preload("res://scripts/environment/stylized/stylized_visual_master.gd")
const WorldComp = preload("res://scripts/environment/stylized/stylized_world_composition.gd")
const Lighting = preload("res://scripts/environment/stylized/stylized_lighting.gd")

const STEP := 0.033


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(ShaderLibrary.validate_shaders().is_empty(), "Shader compile validation failed")
	assert(WorldComp.CAMERA_FOV == VisualMaster.CAMERA_FOV, "Camera FOV master mismatch")
	assert(WorldComp.CAMERA_PITCH == VisualMaster.CAMERA_PITCH, "Camera pitch master mismatch")
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	for quality in [0, 1, 2]:
		var world = World.new()
		root.add_child(world)
		var game_state = root.get_node("GameState")
		game_state.settings.quality = quality
		world.begin(
			{"seed": 4000, "session_id": "v40-master-q%d" % quality, "world_key": "wolkengarten"},
			"bouncer",
			"standard",
			false,
			0
		)
		await process_frame
		var palette_errors: Array[String] = MaterialLibrary.validate_palette(world.mats)
		assert(palette_errors.is_empty(), "Palette validation failed: %s" % ", ".join(palette_errors))
		assert(world.has_meta("v40_visual_master_applied"), "V40 master meta required")
		var validation_errors: Array[String] = VisualMaster.validate(world, quality)
		assert(validation_errors.is_empty(), "V40 validation failed: %s" % ", ".join(validation_errors))
		assert(Lighting.count_directional_lights(world) == 1, "Exactly one sun expected")
		var perf: Dictionary = VisualMaster.performance_report(world)
		assert(int(perf.visual_version) == VisualMaster.VisualVersion, "Visual version mismatch")
		assert(int(perf.vista_islands) == VisualMaster.visible_vista_entries().size(), "Vista count mismatch")
		world.queue_free()
		await process_frame
	print("V40 visual master lock validation passed: fov=%.1f pitch=%.1f vistas=%d" % [
		VisualMaster.CAMERA_FOV, VisualMaster.CAMERA_PITCH, VisualMaster.visible_vista_entries().size()
	])
	quit(0)
