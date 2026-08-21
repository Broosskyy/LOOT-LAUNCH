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
	assert(main.screen.find_child("LoadoutLootlingCard", true, false) != null,
		"Preflight visibly exposes the selected Lootling")
	assert(main.screen.find_child("LoadoutCannonCard", true, false) != null,
		"Preflight visibly exposes the selected cannon")
	assert(main.screen.find_child("ConfirmLoadoutButton", true, false) != null,
		"Preflight has an explicit confirmed start action")
	var old_lootling: String = root.get_node("GameState").selected_lootling
	main._cycle_lootling(1)
	assert(root.get_node("GameState").selected_lootling != old_lootling,
		"Lootling arrows immediately change the persisted loadout")
	main.queue_free()
	await process_frame

	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 1212, "session_id": "v12-objectives"}, "bouncer", "standard", false, 0)
	await process_frame
	var world_environment: WorldEnvironment = null
	for child in world.get_children():
		if child is WorldEnvironment:
			world_environment = child
			break
	assert(world_environment != null and world_environment.environment.background_mode == Environment.BG_SKY,
		"Procedural 360-degree sky replaces the finite grey backdrop")
	assert(world.objective_tokens.size() == 13, "Five islands contain thirteen visible contract targets")
	assert(world.boosters.size() == 5 and world.moving_obstacles.size() == 5,
		"Every hop has an optional booster and a moving risk obstacle")

	world.debug_place_near_cannon()
	world.primary_action()
	await create_timer(0.6).timeout
	world.debug_begin_aim(Vector2(540, 820))
	await create_timer(0.72).timeout
	world.debug_release_aim()
	var elapsed := 0.0
	while world.hop_state == world.HopState.FLYING and elapsed < 5.0:
		await create_timer(0.05).timeout
		elapsed += 0.05
	assert(world.hop_state == world.HopState.LANDED and world.current_island_index == 1,
		"Natural first flight reaches the contract island")
	world.player.global_position = world.target_chest.global_position + Vector3(0.4, world.FLOOR_OFFSET, 0.4)
	world.primary_action()
	assert(not world.opened_chests.has(1), "Chest remains locked until the island contract is complete")
	for item in world.objective_tokens:
		if int(item.island) != 1:
			continue
		world.player.global_position = item.node.global_position
		world._check_island_pickups()
	assert(world._objective_complete(1) and int(world.objective_progress[1]) == 2,
		"Collecting the two visible island targets completes the contract")
	world.player.global_position = world.target_chest.global_position + Vector3(0.4, world.FLOOR_OFFSET, 0.4)
	world.primary_action()
	assert(world.opened_chests.has(1), "Completed contract unlocks the treasure chest")

	print("LOOT LAUNCH v13 loadout/objectives passed: tokens=", world.objective_tokens.size(),
		" flight=", snapped(elapsed, 0.1), " sky=360")
	quit(0)
