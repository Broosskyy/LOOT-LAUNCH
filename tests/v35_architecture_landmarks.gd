extends SceneTree

const ArchGen = preload("res://scripts/environment/stylized/stylized_architecture_generator.gd")
const LandmarkGen = preload("res://scripts/environment/stylized/stylized_landmark_generator.gd")
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
	var transparent_fn := Callable(self, "_transparent")
	var animated: Array = []
	var root := Node3D.new()
	self.root.add_child(root)
	# Builder smoke tests.
	var wall := ArchGen.build_wall(root, Vector3.ZERO, 0.0, 2.4, 1.1, ArchGen.WallKind.BROKEN_WALL, ArchGen.DamageLevel.BROKEN, 100, mats, mesh_fn, 2)
	assert(wall != null and wall.get_child_count() >= 1, "Wall builder required")
	var arch := ArchGen.build_archway(root, Vector3(3, 0, 0), 0.0, 2.2, 1.4, true, 101, mats, mesh_fn, 2)
	assert(arch != null, "Archway builder required")
	var gate := ArchGen.build_gate(root, Vector3(6, 0, 0), 0.0, 102, mats, mesh_fn, 2)
	assert(gate != null and gate.get_node_or_null("ArchCollider") != null, "Gate collision required")
	var bridge := ArchGen.build_stone_bridge(root, Vector3(0, 0.1, 0), Vector3(4, 0.2, 0), 103, mats, mesh_fn, 2)
	assert(bridge != null, "Bridge builder required")
	var tower := LandmarkGen.build_tower(root, Vector3(10, 0, 0), 0.0, LandmarkGen.TowerKind.HERO_TOWER, ArchGen.DamageLevel.LIGHT_RUIN, 104, mats, mesh_fn, 2)
	assert(tower != null, "Hero tower required")
	var courtyard := LandmarkGen.build_ruin_courtyard(root, Vector3(14, 0, 0), 0.0, 105, mats, mesh_fn, 2)
	assert(courtyard != null, "Ruin courtyard required")
	var portal := LandmarkGen.build_portal_monument_site(root, mats, mesh_fn, transparent_fn, animated, 1.0, 106, 2)
	assert(portal != null and animated.size() >= 2, "Portal monument energy required")
	var hero := LandmarkGen.build_hero_landmark(root, mats, mesh_fn, 2, 107)
	assert(hero != null, "Hero landmark required")
	# Triangle budget sanity.
	var tris: int = ArchGen.estimate_triangles(hero)
	assert(tris > 200 and tris < 8000, "Hero landmark triangle budget: %d" % tris)
	# Silhouette bounds.
	var tower_tris: int = ArchGen.estimate_triangles(tower)
	assert(tower_tris > wall.get_child_count(), "Tower should exceed wall complexity")
	# Mega island integration.
	var island_root := Node3D.new()
	root.add_child(island_root)
	var recipe: Dictionary = Recipes.recipe_for(Types.RecipeId.RIVER_TERRACE_A, 9001)
	var result: Dictionary = Composer.compose(island_root, recipe, mats, mesh_fn, 2, 0, false, transparent_fn, animated)
	var arch_meta: Dictionary = result.get("architecture", {})
	assert(bool(arch_meta.get("courtyard", false)), "Mega courtyard required")
	assert(bool(arch_meta.get("gate", false)), "Mega gate required")
	assert(bool(arch_meta.get("portal", false)), "Mega portal monument required")
	var decor: Node3D = island_root.get_node_or_null("MegaDecor")
	assert(decor != null, "Mega decor root required")
	assert(decor.get_node_or_null("StoneBridge") != null or _has_named(decor, "StoneBridge"), "Bridge in mega decor")
	assert(_has_named(decor, "RuinCourtyard"), "Courtyard in mega decor")
	# Gameplay integration roots.
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 3500, "session_id": "v35", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	var start_decor: Node = world.get_node_or_null("SourceIslandDecor")
	assert(start_decor != null, "Start island decor required")
	world.debug_advance_to_island(1)
	await process_frame
	world.debug_advance_to_island(5)
	await process_frame
	var walk_points: Array = [
		Vector3(-2.0, 0.0, 4.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(-4.0, 1.45, 2.0),
	]
	for point in walk_points:
		world.player.global_position = Vector3(world.route_centers[5]) + point + Vector3(0.0, 0.84, 0.0)
		for _i in range(4):
			world._physics_process(STEP)
	var unreachable: Array = world.debug_validate_all_routes_reachable()
	assert(unreachable.is_empty(), "Traversal regression: %s" % str(unreachable))
	print("V35 architecture landmarks passed: hero_tris=%d arch=%s" % [tris, str(arch_meta)])
	quit(0)


func _has_named(node: Node, name_part: String) -> bool:
	if str(node.name).contains(name_part):
		return true
	for child in node.get_children():
		if _has_named(child, name_part):
			return true
	return false


func _mesh(parent: Node, mesh: Mesh, material: Material, pos := Vector3.ZERO, scale_value := Vector3.ONE, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.scale = scale_value
	instance.rotation_degrees = rotation
	parent.add_child(instance)
	return instance


func _transparent(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
