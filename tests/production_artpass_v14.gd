extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _count_type(node: Node, type_name: String) -> int:
	var total := 1 if node.get_class() == type_name else 0
	for child in node.get_children():
		total += _count_type(child, type_name)
	return total


func _run() -> void:
	assert(ResourceLoader.exists("res://art/generated/ui/hud_crystal_frame_v14.png"),
		"The production HUD frame is part of the importable project")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main._begin_launch({"seed": 1414, "session_id": "v14-hud"}, false, 0)
	await process_frame
	var hud = main.screen.find_child("CrystalRouteHUD", true, false)
	assert(hud != null and hud.get_child_count() > 0 and hud.get_child(0) is NinePatchRect,
		"Gameplay uses the crystal-and-brass nine-patch HUD without stretching its corners")
	main.queue_free()
	await process_frame

	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1414, "session_id": "v14-art"}, "bouncer", "portal", false, 0)
	await process_frame
	for key in ["grass_mint", "grass_blue", "grass_lilac", "grass_amber", "grass_royal", "edge_moss", "brass_light"]:
		assert(world.mats.has(key), "The v14 biome/material palette is complete")
	var cannon = world.get_node_or_null("RouteCannon01")
	assert(cannon != null and _count_type(cannon, "MeshInstance3D") >= 25,
		"The cannon has a layered carriage, receiver, ornaments, coils and readable muzzle")
	var chest = world.route_chests[0]
	assert(_count_type(chest, "MeshInstance3D") >= 10,
		"Treasure chests use an authored rounded lid, straps, lock and aether detail")
	assert(_count_type(world, "MeshInstance3D") >= 550,
		"The six-island route contains the denser production-art scenery")
	var flowers = world.find_children("SkyFlower*", "Node3D", true, false)
	var lanterns = world.find_children("AetherLantern*", "Node3D", true, false)
	print("v14 decoration probe: flowers=", flowers.size(), " lanterns=", lanterns.size())
	assert(flowers.size() >= 48 and lanterns.size() >= 12,
		"Organic flowers and aether lanterns replace empty debug plateaus")
	print("LOOT LAUNCH v14 production art pass passed: meshes=", _count_type(world, "MeshInstance3D"),
		" flowers=", flowers.size(), " lanterns=", lanterns.size())
	quit(0)
