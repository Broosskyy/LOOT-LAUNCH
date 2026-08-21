extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.show_launch_loadout()
	await process_frame
	for key in ["bouncer", "magneto", "blasto", "blink"]:
		assert(main.screen.find_child("LootlingChoice_" + key, true, false) != null,
			"Every Lootling is directly selectable without an arrow carousel")
	for key in ["standard", "thunder", "portal"]:
		assert(main.screen.find_child("CannonChoice_" + key, true, false) != null,
			"Every cannon is directly selectable without an arrow carousel")
	main.queue_free()
	await process_frame

	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1313, "session_id": "v13-artpass"}, "bouncer", "standard", false, 0)
	await process_frame
	assert(world.ROUTE_CENTERS.size() == 6 and world.ROUTE_RADII.min() >= 12.0,
		"Wolkengarten is a six-island route with larger walkable spaces")
	assert(world.airships.size() == 2, "Two animated sky couriers provide background life")
	for i in range(6):
		var island = world.get_node_or_null("SkyIsland%02d" % i)
		var landmark = world.get_node_or_null("BiomeLandmark%02d" % (i + 1))
		assert(island != null and landmark != null, "Every island has irregular geometry and a unique landmark")
		var has_irregular_mesh := false
		for child in island.get_children():
			if child is MeshInstance3D and child.mesh is ArrayMesh:
				has_irregular_mesh = true
		assert(has_irregular_mesh, "Island visuals use authored ArrayMesh cliffs instead of stacked cylinders")
	var contract_total := 0
	for value in world.objective_requirements.values():
		contract_total += int(value)
	assert(contract_total == 13,
		"Five distinct island contracts total thirteen targets")
	print("LOOT LAUNCH v13 Wolkengarten art pass passed: islands=6, contracts=13, airships=2")
	quit(0)
