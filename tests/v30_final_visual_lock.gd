extends SceneTree

const WorldComp = preload("res://scripts/environment/stylized/stylized_world_composition.gd")
const Motion = preload("res://scripts/environment/stylized/stylized_motion_controller.gd")
const VFX = preload("res://scripts/environment/stylized/stylized_vfx_controller.gd")
const StylizedLighting = preload("res://scripts/environment/stylized/stylized_lighting.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(WorldComp.CAMERA_FOV >= 50.0 and WorldComp.CAMERA_FOV <= 56.0)
	assert(WorldComp.CAMERA_FOLLOW_DISTANCE > 9.0)
	assert(WorldComp.CAMERA_LOOK_AHEAD > 3.0)
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	var game_state = root.get_node("GameState")
	game_state.settings.quality = 2
	world.begin({"seed": 2828, "session_id": "v30-lock", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	assert(world.player != null, "Player required")
	assert(world.camera != null, "Camera required")
	assert(world.cannon_root != null, "Cannon required")
	assert(world.flight_pickups.size() >= 5, "Ring route required")
	assert(world.wind_streamers.size() > 0, "Portal motion nodes required")
	assert(world.clouds.size() > 0, "Clouds required")
	world.bootstrap_gameplay_camera()
	world.assert_camera_composition_valid("v30_spawn")
	world.assert_world_composition_valid("v30_spawn")
	var env: WorldEnvironment = StylizedLighting.find_world_environment(world)
	assert(env != null and env.environment != null, "WorldEnvironment required")
	assert(StylizedLighting.count_directional_lights(world) >= 1, "DirectionalLight required")
	assert(Motion.is_transform_finite(world.player))
	assert(Motion.is_transform_finite(world.cannon_pivot))
	for key in Motion.WIND_MATERIAL_KEYS:
		if world.mats.has(key) and world.mats[key] is ShaderMaterial:
			var sm: ShaderMaterial = world.mats[key]
			assert(sm.get_shader_parameter("wind_strength") != null)
	assert(VFX.portal_particle_cap(2) <= 20)
	var visible_rings := 0
	for item in world.flight_pickups:
		if int(item.get("route", -1)) == 0:
			var screen: Vector2 = world.camera.unproject_position(item["origin"])
			if screen.y >= 0 and screen.y <= 1920:
				visible_rings += 1
	assert(visible_rings >= 3, "Start route rings must remain readable")
	world.debug_advance_to_island(1)
	await process_frame
	world._update_camera(0.033)
	world.assert_camera_composition_valid("v30_transition")
	print("V30 final visual lock validation passed: rings=", visible_rings)
	quit(0)
