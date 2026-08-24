extends SceneTree

const WorldComp = preload("res://scripts/environment/stylized/stylized_world_composition.gd")
const EnvironmentRender = preload("res://scripts/environment/stylized/stylized_environment_render.gd")
const CloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")
const Composer = preload("res://scripts/environment/stylized/stylized_mega_island_composer.gd")
const Recipes = preload("res://scripts/environment/stylized/mega_island_recipes.gd")
const Types = preload("res://scripts/environment/stylized/mega_island_types.gd")
const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const Motion = preload("res://scripts/environment/stylized/stylized_motion_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(WorldComp.CAMERA_FOV >= 50.0 and WorldComp.CAMERA_FOV <= 56.0)
	assert(WorldComp.CAMERA_FOLLOW_DISTANCE > 9.0)
	assert(WorldComp.CAMERA_LOOK_AHEAD > 3.0)
	assert(WorldComp.CAMERA_PITCH < 20.0, "V37 camera must reduce top-down pitch")
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	var game_state = root.get_node("GameState")
	game_state.settings.quality = 2
	world.begin({"seed": 3700, "session_id": "v37-reference", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	await process_frame
	assert(world.player != null, "Player required")
	assert(world.camera != null, "Camera required")
	assert(world.cannon_root != null, "Cannon required")
	assert(world.flight_pickups.size() >= 5, "Ring route required")
	assert(world.clouds.size() > 0, "Clouds required")
	assert(CloudGenerator.count_puffs_in_world(world) > 0, "Cloud puffs required")
	world.bootstrap_gameplay_camera()
	world.assert_camera_composition_valid("v37_spawn")
	world.assert_world_composition_valid("v37_spawn")
	var comp: Dictionary = world.evaluate_camera_composition()
	assert(comp.player_screen_x_pct >= 0.42 and comp.player_screen_x_pct <= 0.58,
		"V37 player x=%.2f outside center band" % comp.player_screen_x_pct)
	assert(comp.player_screen_y_pct >= 0.62 and comp.player_screen_y_pct <= 0.88,
		"V37 player y=%.2f outside lower band" % comp.player_screen_y_pct)
	var screen: Dictionary = world.evaluate_world_composition_screen()
	assert(screen.has("cannon") and screen["cannon"]["in_view"], "Cannon must be visible")
	assert(screen.has("primary_destination"), "Primary destination marker required")
	assert(screen.has("hero_landmark"), "Hero landmark marker required")
	var env_errors: Array[String] = EnvironmentRender.validate_environment(world, 2)
	assert(env_errors.is_empty(), "Environment validation failed: %s" % ", ".join(env_errors))
	var palette_errors: Array[String] = MaterialLibrary.validate_palette(world.mats)
	assert(palette_errors.is_empty(), "Palette validation failed")
	assert(Motion.is_transform_finite(world.player))
	assert(Motion.is_transform_finite(world.cannon_pivot))
	var visible_rings := 0
	for item in world.flight_pickups:
		if int(item.get("route", -1)) == 0:
			var s: Vector2 = world.camera.unproject_position(item["origin"])
			if s.y >= 0.0 and s.y <= 1920.0:
				visible_rings += 1
	assert(visible_rings >= 3, "Start route rings must remain readable")
	var limits: Vector2 = world.debug_get_aim_pitch_limits()
	assert(limits.x < 14.0 and limits.y > 50.0, "V31 aim pitch range must remain")
	var unreachable: Array = world.debug_validate_all_routes_reachable()
	assert(unreachable.is_empty(), "Ballistic routes must remain reachable: %s" % str(unreachable))
	# Mega island smoke.
	var mats := {}
	MaterialLibrary.apply_palette(
		mats,
		func(c: Color, r: float, m: float, _e := Color.BLACK, _en := 0.0) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = c
			mat.roughness = r
			mat.metallic = m
			return mat,
		func(c: Color) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = c
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			return mat,
		2
	)
	var island_root := Node3D.new()
	root.add_child(island_root)
	var recipe: Dictionary = Recipes.recipe_for(Types.RecipeId.RIVER_TERRACE_A, 3701)
	var animated: Array = []
	var result: Dictionary = Composer.compose(
		island_root, recipe, mats, Callable(self, "_mesh"), 2, 0, false,
		func(c: Color) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = c
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			return mat,
		animated
	)
	assert(bool(result.get("architecture", {}).get("portal", false)), "Mega island portal required")
	world.debug_advance_to_island(1)
	await process_frame
	world._update_camera(0.033)
	world.assert_camera_composition_valid("v37_transition")
	print("V37 final reference reconstruction validation passed: rings=%d" % visible_rings)
	quit(0)


func _mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, scale := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.scale = scale
	instance.rotation_degrees = rot
	parent.add_child(instance)
	return instance
