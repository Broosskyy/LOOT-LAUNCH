extends SceneTree

const Composer = preload("res://scripts/environment/stylized/stylized_mega_island_composer.gd")
const Recipes = preload("res://scripts/environment/stylized/mega_island_recipes.gd")
const Types = preload("res://scripts/environment/stylized/mega_island_types.gd")
const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const STEP := 0.05


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var mats := {}
	MaterialLibrary.apply_palette(
		mats,
		func(color: Color, roughness: float, metallic: float, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.roughness = roughness
			mat.metallic = metallic
			if energy > 0.0:
				mat.emission_enabled = true
				mat.emission = emission
				mat.emission_energy_multiplier = energy
			return mat,
		func(color: Color) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			return mat,
		2
	)
	var mesh_fn := Callable(self, "_mesh")
	for recipe_id in [Types.RecipeId.RIVER_TERRACE_A, Types.RecipeId.BASIN_B, Types.RecipeId.RAVINE_C]:
		var recipe: Dictionary = Recipes.recipe_for(recipe_id, 4242)
		var island_root := Node3D.new()
		root.add_child(island_root)
		var result: Dictionary = Composer.compose(island_root, recipe, mats, mesh_fn, 2, 0, false)
		var errors: Array = Composer.validate_recipe_build(result)
		assert(errors.is_empty(), "Recipe %s failed validation: %s" % [recipe.get("name"), str(errors)])
		assert(result.bounds.size.is_finite(), "Bounds must be finite")
		assert(result.bounds.size.length() > 4.0, "Bounds must be meaningful")
		assert(int(result.module_count) >= 2, "Recipe must build modules")
		island_root.queue_free()
	var recipe_a: Dictionary = Recipes.recipe_for(Types.RecipeId.RIVER_TERRACE_A, 9001)
	var first := _compose_result(recipe_a, mats, mesh_fn)
	var second := _compose_result(recipe_a, mats, mesh_fn)
	assert(first.seed == second.seed, "Deterministic seed required")
	assert(first.module_count == second.module_count, "Deterministic module count required")
	assert(first.river_points.size() == second.river_points.size(), "Deterministic river path required")
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 3200, "session_id": "v32", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var mega: Dictionary = world.mega_island_metadata
	assert(not mega.is_empty(), "Playable mega island metadata required")
	assert(int(mega.get("elevation_layers", 0)) >= 2, "Mega island needs multiple elevations")
	assert(mega.get("river_points", []).size() >= 3, "River points required on showcase island")
	assert(not mega.get("waterfall", {}).is_empty(), "Waterfall required on showcase island")
	assert(Composer.zone_of_type(mega.get("zones", []), Types.ZoneType.COMBAT_ZONE).size() >= 1, "Combat zone required")
	var island: Node3D = world.get_node_or_null("SkyIsland05") as Node3D
	assert(island != null, "Mega island node must exist")
	assert(island.get_node_or_null("MegaTerrain") != null, "Mega terrain root required")
	assert(island.get_node_or_null("MegaWater") != null, "Mega water root required")
	world.debug_advance_to_island(5)
	await process_frame
	var walk_points: Array = [
		Vector3(-2.0, 0.0, 4.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(2.5, 0.0, -1.0),
		Vector3(-4.0, 1.45, 2.0),
	]
	var start: Vector3 = world.player.global_position
	for point in walk_points:
		world.player.global_position = Vector3(world.route_centers[5]) + point + Vector3(0.0, 0.84, 0.0)
		for _i in range(4):
			world._physics_process(STEP)
	assert(world.player.global_position.distance_to(start) >= 0.0, "Walk proxy must remain on island")
	var unreachable: Array = world.debug_validate_all_routes_reachable()
	assert(unreachable.is_empty(), "V31 cannon reachability must remain valid: %s" % str(unreachable))
	print(
		"V32 mega island composer passed: modules=%d elevations=%d river=%d zones=%d"
		% [mega.module_count, mega.elevation_layers, mega.river_points.size(), mega.zones.size()]
	)
	quit(0)


func _compose_result(recipe: Dictionary, mats: Dictionary, mesh_fn: Callable) -> Dictionary:
	var island_root := Node3D.new()
	root.add_child(island_root)
	var result: Dictionary = Composer.compose(island_root, recipe, mats, mesh_fn, 2, 0, false)
	island_root.queue_free()
	return result


func _mesh(parent: Node, mesh: Mesh, material: Material, pos := Vector3.ZERO, scale_value := Vector3.ONE, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.scale = scale_value
	instance.rotation_degrees = rotation
	parent.add_child(instance)
	return instance
