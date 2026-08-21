extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state = root.get_node("GameState")
	game_state.settings.quality = 0
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var economy_world = World.new()
	root.add_child(economy_world)
	economy_world.begin({"seed": 1010, "session_id": "balance-v10"}, "bouncer", "standard", false, 0)
	await process_frame
	assert(economy_world.trail_pool.size() == 12, "Battery quality uses the smallest trail pool")
	assert(economy_world.spark_pool.size() == 32, "Battery quality caps pooled burst particles")
	assert(not economy_world.sun.shadow_enabled, "Battery quality disables realtime shadows")
	assert(economy_world.clouds.size() == 2, "Battery quality reduces procedural cloud nodes")
	assert(ResourceLoader.exists("res://art/generated/sky_route_backdrop_v10.png"), "v10 premium sky asset is packaged")
	var safe_coins := 0
	var risk_coins := 0
	var risk_crystals := 0
	for item in economy_world.flight_pickups:
		if item.kind == "coin" and item.risk: risk_coins += int(item.value)
		elif item.kind == "coin": safe_coins += int(item.value)
		elif item.kind == "crystal" and item.risk: risk_crystals += int(item.value)
	assert(safe_coins == 300, "Five safe flight lines provide a readable expedition baseline")
	assert(safe_coins + 500 == 800, "Five route chests preserve a meaningful completion reward")
	assert(risk_coins == 250 and risk_crystals == 5, "Five risk lanes provide transparent optional upside")
	var node_count: int = economy_world.get_child_count()
	economy_world._spawn_burst(Vector3.ZERO, economy_world.mats.coin, 20)
	assert(economy_world.get_child_count() == node_count, "Burst effects reuse pooled nodes without runtime allocation")
	assert(int(economy_world.performance_counters.burst_reuses) > 0)
	economy_world.queue_free()
	await process_frame
	game_state.settings.quality = 3
	var portal_world = World.new()
	root.add_child(portal_world)
	portal_world.begin({"seed": 2020, "session_id": "loadout-v10"}, "blink", "portal", false, 0)
	await process_frame
	assert(portal_world.trail_pool.size() == 40 and portal_world.spark_pool.size() == 88, "Ultra quality raises only bounded pool sizes")
	assert(portal_world.ability_charges == 2, "Portal cannon grants two weaker tactical impulses")
	portal_world.debug_place_near_cannon()
	portal_world.primary_action()
	await create_timer(0.55).timeout
	portal_world.debug_begin_aim(Vector2(540, 820))
	await create_timer(0.72).timeout
	portal_world.debug_release_aim()
	await create_timer(0.05).timeout
	var before: Vector3 = portal_world.projectile.global_position
	portal_world.activate_special()
	assert(portal_world.projectile.global_position.distance_to(before) > 4.0, "Blink special teleports forward")
	portal_world.activate_special()
	assert(portal_world.ability_uses == 2 and portal_world.ability_used, "Second portal charge works and then locks")
	portal_world.activate_special()
	assert(portal_world.ability_uses == 2, "No third special can be consumed")
	print("LOOT LAUNCH v13 performance/balance passed: safe=",safe_coins+500,
		" risk=",risk_coins," fx=",portal_world.trail_pool.size()+portal_world.spark_pool.size())
	quit(0)
