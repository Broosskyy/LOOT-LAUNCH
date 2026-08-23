extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1818, "session_id": "v18-3-camera", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	world.apply_gameplay_camera_state(true)
	world._update_camera(0.016)
	var on_foot: Dictionary = world.capture_gameplay_camera_state()
	assert(on_foot.hop_state == world.HopState.ON_FOOT, "Spawn should be on foot")
	assert(absf(on_foot.fov - world.STYLIZED_CAMERA_FOV) < 0.01, "Spawn FOV must match stylized default")
	assert(absf(on_foot.pitch - world.STYLIZED_CAMERA_PITCH) < 0.01, "Spawn pitch must match stylized default")
	assert(absf(on_foot.distance - world.STYLIZED_CAMERA_DISTANCE) < 0.01, "Spawn distance must match stylized default")
	assert(absf(on_foot.yaw - on_foot.target_yaw) < 0.01, "Spawn yaw must be initialized immediately")
	world._set_state(world.HopState.LANDED)
	await process_frame
	world._update_camera(0.016)
	var landed_same_island: Dictionary = world.capture_gameplay_camera_state()
	assert(absf(landed_same_island.fov - on_foot.fov) < 0.01, "LANDED must reuse stylized FOV")
	assert(absf(landed_same_island.pitch - on_foot.pitch) < 0.01, "LANDED must reuse stylized pitch")
	assert(absf(landed_same_island.distance - on_foot.distance) < 0.01, "LANDED must reuse stylized distance")
	world.debug_advance_to_island(1)
	await process_frame
	world._update_camera(0.016)
	var island_one: Dictionary = world.capture_gameplay_camera_state()
	assert(island_one.hop_state == world.HopState.LANDED, "Island transition debug should land on island 1")
	assert(absf(island_one.fov - on_foot.fov) < 0.01, "FOV must stay stable across transition")
	assert(absf(island_one.pitch - on_foot.pitch) < 0.01, "Pitch must stay stable across transition")
	assert(absf(island_one.distance - on_foot.distance) < 0.01, "Distance must stay stable across transition")
	print("V18.3 camera stability passed")
	quit(0)
