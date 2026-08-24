extends SceneTree

const VIEWPORT_SIZE := Vector2i(1080, 1920)
const GODOT_STEP := 0.05


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	viewport.add_child(world)
	world.begin({"seed": 3131, "session_id": "v31-foundation", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	await process_frame

	# TEST A — SPAWN
	assert(world.camera_bootstrapped, "Camera must bootstrap on spawn")
	assert(world.player != null and world.camera != null, "Player and camera required")
	var composition: Dictionary = world.evaluate_camera_composition()
	assert(composition.player_in_front_of_camera, "Player must be in front of camera at spawn")
	assert(world.hop_state == world.HopState.ON_FOOT, "Spawn state must be ON_FOOT")
	assert(world.active_pointer == -999 and world.camera_orbit_pointer == -999, "Touch IDs must start clean")

	# TEST B — MOVEMENT
	var basis: Dictionary = world._camera_movement_basis()
	var start_pos: Vector3 = world.player.global_position
	world.set_move_vector(Vector2(0.0, -1.0))
	for _i in range(8):
		world._physics_process(GODOT_STEP)
		world._process(GODOT_STEP)
	world.set_move_vector(Vector2.ZERO)
	var moved: Vector3 = world.player.global_position - start_pos
	moved.y = 0.0
	assert(moved.length() > 0.08, "Forward joystick input must move player")
	assert(basis.forward.dot(moved.normalized()) > 0.9, "Movement must follow camera forward")

	# TEST C — CAMERA SWIPE
	world.target_orbit_yaw = world.orbit_yaw + 24.0
	for _i in range(12):
		world._process(GODOT_STEP)
		world._update_camera(GODOT_STEP)
	var basis_after_swipe: Dictionary = world._camera_movement_basis()
	var start_after_swipe: Vector3 = world.player.global_position
	world.set_move_vector(Vector2(0.0, -1.0))
	for _i in range(8):
		world._physics_process(GODOT_STEP)
		world._process(GODOT_STEP)
	world.set_move_vector(Vector2.ZERO)
	var moved_after_swipe: Vector3 = world.player.global_position - start_after_swipe
	moved_after_swipe.y = 0.0
	assert(moved_after_swipe.length() > 0.08, "Movement after camera swipe must still work")
	assert(basis_after_swipe.forward.dot(moved_after_swipe.normalized()) > 0.9, "Movement must follow updated camera forward")

	# TEST D/E — CANNON AIM DOWN + UP
	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.75).timeout
	assert(world.hop_state == world.HopState.AIMING, "Must enter aiming state")
	var limits: Vector2 = world.debug_get_aim_pitch_limits()
	assert(limits.x < 14.0, "Pitch minimum must allow low trajectories (was 18)")
	assert(limits.y > 50.0, "Pitch maximum must allow high trajectories")
	var pitch_before_drag: float = world.aim_pitch
	assert(world.debug_begin_aim(Vector2(540.0, 620.0)), "Aim gesture must start")
	world.debug_drag_aim(Vector2(540.0, 1380.0))
	var pitch_after_down: float = world.aim_pitch
	assert(pitch_after_down < pitch_before_drag - 4.0, "Downward drag must decrease pitch materially")
	assert(pitch_after_down <= limits.x + 1.5, "Downward drag must reach near pitch minimum")
	world.debug_drag_aim(Vector2(540.0, 520.0))
	var pitch_after_up: float = world.aim_pitch
	assert(pitch_after_up > pitch_after_down + 4.0, "Upward drag must increase pitch after downward drag")

	# TEST F — REACHABILITY
	var unreachable: Array = world.debug_validate_all_routes_reachable()
	assert(unreachable.is_empty(), "All cannon routes must be reachable, failed=%s limits=%s" % [str(unreachable), str(limits)])

	# TEST G — ACTUAL LAUNCH
	world.debug_prepare_nominal_shot()
	world.debug_release_aim()
	await process_frame
	assert(world.hop_state == world.HopState.FLYING, "Nominal shot must launch")
	var landed := false
	var elapsed := 0.0
	while elapsed < 9.5:
		world._physics_process(GODOT_STEP)
		world._process(GODOT_STEP)
		world._update_camera(GODOT_STEP)
		elapsed += GODOT_STEP
		if world.hop_state == world.HopState.LANDED:
			landed = true
			break
	assert(landed, "Nominal ballistic launch must land on target island")

	# TEST H — THREE ISLAND TRAVERSAL
	for hop in range(2):
		assert(world.current_island_index == hop + 1, "Traversal hop %d must advance island index" % hop)
		world.debug_unlock_cannon_for_traversal()
		world.debug_place_near_cannon()
		world.primary_action()
		await create_timer(0.75).timeout
		assert(world.hop_state == world.HopState.AIMING, "Traversal hop %d must enter aiming" % hop)
		world.debug_prepare_nominal_shot()
		world.debug_fire_prepared_shot()
		await process_frame
		var hop_landed := false
		var hop_elapsed := 0.0
		while hop_elapsed < 9.5:
			world._physics_process(GODOT_STEP)
			world._process(GODOT_STEP)
			world._update_camera(GODOT_STEP)
			hop_elapsed += GODOT_STEP
			if world.hop_state == world.HopState.LANDED:
				hop_landed = true
				break
		assert(hop_landed, "Traversal hop %d must land" % hop)
	assert(world.current_island_index == 3, "Three successful hops must reach island index 3")

	print(
		"V31 gameplay foundation passed: pitch_limits=%s down_delta=%.2f up_delta=%.2f island=%d"
		% [str(limits), pitch_before_drag - pitch_after_down, pitch_after_up - pitch_after_down, world.current_island_index]
	)
	quit(0)
