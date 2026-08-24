extends SceneTree

const Motion = preload("res://scripts/environment/stylized/stylized_motion_controller.gd")
const VFX = preload("res://scripts/environment/stylized/stylized_vfx_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(Motion.wind_strength_for_quality(0) == 0.0)
	assert(Motion.wind_strength_for_quality(2) > Motion.wind_strength_for_quality(1))
	assert(VFX.portal_particle_cap(0) < VFX.portal_particle_cap(2))
	assert(VFX.cannon_burst_cap(2) <= 25)
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	var game_state = root.get_node("GameState")
	game_state.settings.quality = 2
	world.begin({"seed": 2828, "session_id": "v29-motion", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	assert(world.clouds.size() > 0, "Clouds required")
	var cloud: Node3D = world.clouds[0]
	var cloud_x_a: float = cloud.position.x
	world.idle_time = 0.0
	world._process(0.5)
	var cloud_x_b: float = cloud.position.x
	assert(absf(cloud_x_b - cloud_x_a) > 0.01, "Cloud drift expected")
	assert(world.flight_pickups.size() > 0, "Route rings required")
	var ring: Node3D = world.flight_pickups[0].node
	var ring_y_a: float = ring.position.y
	world._process(0.4)
	var ring_y_b: float = ring.position.y
	assert(absf(ring_y_b - ring_y_a) > 0.001, "Ring bob expected")
	assert(world.wind_streamers.size() > 0, "Portal rings required")
	var portal_ring: Node3D = world.wind_streamers[0]
	var portal_rot_a: float = portal_ring.rotation.y
	world._process(0.25)
	assert(absf(portal_ring.rotation.y - portal_rot_a) > 0.001, "Portal rotation expected")
	assert(world.player_visual != null)
	world._physics_process(0.05)
	world._process(0.5)
	world._physics_process(1.2)
	assert(absf(world.player_visual.position.y) > 0.001 or absf(world.player_visual.scale.y - 1.0) > 0.001, "Lootling idle motion expected")
	assert(Motion.is_transform_finite(world.player), "Player physics root must stay finite")
	var pivot: Node3D = world.cannon_pivot
	var pivot_pos: Vector3 = pivot.position
	world._cannon_recoil()
	await process_frame
	await process_frame
	world._process(0.35)
	assert(pivot.position.distance_to(pivot_pos) < 0.05, "Cannon recoil should return to origin")
	assert(Motion.is_transform_finite(pivot))
	var mats: Dictionary = world.mats
	for key in Motion.WIND_MATERIAL_KEYS:
		if mats.has(key) and mats[key] is ShaderMaterial:
			var sm: ShaderMaterial = mats[key]
			assert(sm.get_shader_parameter("wind_strength") != null)
	assert(VFX.clamp_active_particles(int(world.performance_counters.peak_active_fx), 2))
	print("V29 VFX animation validation passed")
	quit(0)
