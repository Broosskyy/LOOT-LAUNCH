extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	var game_state = root.get_node("GameState")
	game_state.energy.current = game_state.energy.maximum
	var session: Dictionary = await game_state.start_launch()
	assert(session.get("ok", false))
	main._begin_launch(session, false, 0)
	await process_frame
	assert(main.world != null)
	assert(main.launch_pad != null and main.launch_pad.visible)
	assert(main.launch_action != null)
	main.world.debug_place_near_cannon()
	await process_frame
	assert(not main.launch_action.disabled, "Cannon action becomes available by proximity")
	main._world_primary_action()
	await create_timer(0.7).timeout
	assert(main.world.hop_state == main.world.HopState.AIMING)
	assert(not main.launch_pad.visible, "Movement pad hides during cannon aim")
	assert(not main.launch_action.visible, "Empty action button does not cover cannon view")
	assert(main.launch_reticle.visible and main.launch_power_bar.visible, "Aim HUD is visible")
	print("LOOT LAUNCH v10 UI smoke passed: action=", main.launch_action.text,
		" mode=", main.launch_mode_label.text)
	quit(0)
