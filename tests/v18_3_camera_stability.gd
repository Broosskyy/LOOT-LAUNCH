extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1818, "session_id": "v18-3-camera", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	assert(world.camera_bootstrapped, "Camera must bootstrap in begin()")
	world.assert_camera_composition_valid("spawn")
	world._set_state(world.HopState.LANDED)
	world._update_camera(0.016)
	world.assert_camera_composition_valid("landed")
	world.debug_advance_to_island(1)
	world._update_camera(0.016)
	world.assert_camera_composition_valid("island_one")
	print("V18.3 camera stability passed")
	quit(0)
