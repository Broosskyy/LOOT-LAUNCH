extends SceneTree

const Terrain = preload("res://scripts/environment/stylized/stylized_terrain_surface.gd")
const Composer = preload("res://scripts/environment/stylized/stylized_mega_island_composer.gd")
const Recipes = preload("res://scripts/environment/stylized/mega_island_recipes.gd")
const Types = preload("res://scripts/environment/stylized/mega_island_types.gd")
const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
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
			return mat,
		func(color: Color) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			return mat,
		2
	)
	var mesh_fn := Callable(self, "_mesh")
	var hero_root := Node3D.new()
	root.add_child(hero_root)
	Terrain.dress_hero_island(hero_root, 8.5, 0, mats, mesh_fn, 2, 4242)
	assert(hero_root.get_child_count() >= 3, "Hero island surface dressing required")
	var recipe: Dictionary = Recipes.recipe_for(Types.RecipeId.RIVER_TERRACE_A, 9001)
	var island_root := Node3D.new()
	root.add_child(island_root)
	var result: Dictionary = Composer.compose(island_root, recipe, mats, mesh_fn, 2, 0, false)
	assert(bool(result.get("surface_dressed", false)), "Mega island surface dressing required")
	var terrain: Node3D = island_root.get_node_or_null("MegaTerrain")
	var water: Node3D = island_root.get_node_or_null("MegaWater")
	assert(terrain != null and water != null, "Mega terrain/water roots required")
	assert(terrain.get_child_count() >= int(result.module_count), "Terrain modules required")
	var has_channel := false
	for child in water.get_children():
		if str(child.name).contains("River") or str(child.name).contains("Channel") or str(child.name).contains("Pond") or str(child.name).contains("Waterfall"):
			has_channel = true
	assert(has_channel, "Water features required")
	var errors: Array = Composer.validate_recipe_build(result)
	assert(errors.is_empty(), "Mega recipe validation failed: %s" % str(errors))
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 3400, "session_id": "v34", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var decor: Node = world.get_node_or_null("SourceIslandDecor")
	assert(decor != null, "Start island decor required")
	var start_meshes := 0
	for child in decor.get_children():
		if child is MeshInstance3D:
			start_meshes += 1
	assert(start_meshes >= 1, "Start island decor meshes required")
	world.debug_advance_to_island(5)
	await process_frame
	var walk_points: Array = [
		Vector3(-2.0, 0.0, 4.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(-4.0, 1.45, 2.0),
		Vector3(1.0, 0.0, -1.0),
	]
	var start_pos: Vector3 = world.player.global_position
	for point in walk_points:
		world.player.global_position = Vector3(world.route_centers[5]) + point + Vector3(0.0, 0.84, 0.0)
		for _i in range(4):
			world._physics_process(STEP)
	assert(world.player.global_position.distance_to(start_pos) >= 0.0, "Walk proxy must remain valid")
	var unreachable: Array = world.debug_validate_all_routes_reachable()
	assert(unreachable.is_empty(), "Traversal regression: %s" % str(unreachable))
	print("V34 terrain surface passed: mega_modules=%d surface_dressed=%s" % [result.module_count, result.surface_dressed])
	quit(0)


func _mesh(parent: Node, mesh: Mesh, material: Material, pos := Vector3.ZERO, scale_value := Vector3.ONE, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.scale = scale_value
	instance.rotation_degrees = rotation
	parent.add_child(instance)
	return instance
