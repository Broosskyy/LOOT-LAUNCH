extends SceneTree

## Boots main.tscn and starts the Wolkengarten expedition like a real player session.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "main.tscn must load")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.show_launch_loadout()
	await process_frame
	main.start_launch()
	await process_frame
	await create_timer(0.5).timeout
	assert(main.world != null, "Gameplay world must be active after start_launch")
	assert(main.world.get_node_or_null("BouncerPlayer") != null, "Player must exist in gameplay world")
	assert(main.world.get_node_or_null("SkyIsland00") != null, "Start island must exist")
	print("V18.1A main gameplay boot passed: expedition=", main.world.expedition_key)
	quit(0)
