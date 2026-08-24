extends SceneTree

const Veg = preload("res://scripts/environment/stylized/stylized_vegetation_generator.gd")
const Density = preload("res://scripts/environment/stylized/stylized_vegetation_density.gd")
const StylizedWorldComposition = preload("res://scripts/environment/stylized/stylized_world_composition.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(is_equal_approx(Density.density_scale(0), 0.42))
	assert(is_equal_approx(Density.density_scale(1), 0.76))
	assert(is_equal_approx(Density.density_scale(2), 1.0))
	assert(Density.is_excluded(StylizedWorldComposition.PLAYER_SPAWN_OFFSET, Density.start_island_exclusions()))
	assert(not Density.is_excluded(Vector3(5.0, 0.0, 3.0), Density.start_island_exclusions()))
	assert(Density.can_place_start(Vector3(5.0, 0.0, 3.0), Density.start_island_exclusions()))
	assert(Density.is_excluded(StylizedWorldComposition.CANNON_OFFSET, Density.start_island_exclusions()))
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	for quality in [0, 1, 2]:
		var world = World.new()
		root.add_child(world)
		var game_state = root.get_node("GameState")
		game_state.settings.quality = quality
		world.begin({"seed": 2828, "session_id": "v28-density-q%d" % quality, "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
		await process_frame
		var decor: Node = world.get_node("SourceIslandDecor")
		assert(decor != null, "Start decor required")
		var counts: Dictionary = Veg.count_vegetation_nodes(decor)
		if quality == 2:
			assert(counts["grass"] >= 18, "V28 start grass: %s" % counts)
			assert(counts["flower"] >= 12, "V28 start flowers: %s" % counts)
			assert(counts["tree"] >= 4, "V28 start trees: %s" % counts)
			assert(counts["shrub"] >= 4, "V28 start shrubs: %s" % counts)
			assert(counts["vine"] >= 2, "V28 start vines: %s" % counts)
		assert(counts["total"] < 120, "Vegetation budget exceeded at Q%d: %s" % [quality, counts])
		if quality == 0:
			var counts_q2_ref := 80
			assert(counts["total"] < counts_q2_ref, "Q0 should be sparser than full density")
		world.queue_free()
		await process_frame
	# Determinism check.
	var w1 = World.new()
	root.add_child(w1)
	w1.begin({"seed": 2828, "session_id": "v28-det-a", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var c1: Dictionary = Veg.count_vegetation_nodes(w1.get_node("SourceIslandDecor"))
	w1.queue_free()
	await process_frame
	var w2 = World.new()
	root.add_child(w2)
	w2.begin({"seed": 2828, "session_id": "v28-det-b", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var c2: Dictionary = Veg.count_vegetation_nodes(w2.get_node("SourceIslandDecor"))
	assert(c1 == c2, "Vegetation must be deterministic: %s vs %s" % [c1, c2])
	print("V28 environment density validation passed: counts=", c1)
	quit(0)
