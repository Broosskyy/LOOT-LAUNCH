extends RefCounted
class_name StylizedMegaIslandComposer

const Types = preload("res://scripts/environment/stylized/mega_island_types.gd")
const Recipes = preload("res://scripts/environment/stylized/mega_island_recipes.gd")
const Water = preload("res://scripts/environment/stylized/mega_island_water.gd")
const Collision = preload("res://scripts/environment/stylized/mega_island_collision.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const RuinsKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")
const VegGen = preload("res://scripts/environment/stylized/stylized_vegetation_generator.gd")
const TypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const TerrainSurface = preload("res://scripts/environment/stylized/stylized_terrain_surface.gd")
const ArchGen = preload("res://scripts/environment/stylized/stylized_architecture_generator.gd")
const LandmarkGen = preload("res://scripts/environment/stylized/stylized_landmark_generator.gd")

const MEGA_ISLAND_INDEX := 5
const DEBUG_VIEW_META := "mega_island_debug_view"


static func is_mega_island_index(island_index: int) -> bool:
	return island_index == MEGA_ISLAND_INDEX


static func compose(
	root: Node3D,
	recipe: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	route_variant: int = 0,
	debug_view: bool = false,
	transparent_fn: Callable = Callable(),
	animated_nodes: Array = []
) -> Dictionary:
	var seed: int = int(recipe.get("seed", 3200))
	var rng := _rng(seed, route_variant)
	var segments: int = 20 if quality_level >= 2 else 16
	var modules: Array = recipe.get("modules", [])
	var terrain_root := Node3D.new()
	terrain_root.name = "MegaTerrain"
	root.add_child(terrain_root)
	var water_root := Node3D.new()
	water_root.name = "MegaWater"
	root.add_child(water_root)
	var decor_root := Node3D.new()
	decor_root.name = "MegaDecor"
	root.add_child(decor_root)
	for module in modules:
		_build_module(terrain_root, module, mats, mesh_fn, segments, rng)
	_build_unified_cliff_shell(terrain_root, modules, mats, mesh_fn, segments, rng)
	var river_spec: Dictionary = recipe.get("river", {}).duplicate(true)
	river_spec["seed"] = seed
	var river_result: Dictionary = Water.build_river(water_root, river_spec, mats, mesh_fn, quality_level)
	var waterfall_result: Dictionary = Water.build_waterfall(water_root, recipe.get("waterfall", {}), mats, mesh_fn, quality_level)
	_build_bridge(decor_root, recipe.get("bridge", {}), mats, mesh_fn, quality_level)
	var arch_meta: Dictionary = LandmarkGen.build_mega_architecture_cluster(
		decor_root, recipe, mats, mesh_fn, transparent_fn, animated_nodes, quality_level, seed
	)
	_dress_vegetation(decor_root, recipe, mats, mesh_fn, quality_level, seed)
	var surface_meta: Dictionary = TerrainSurface.dress_mega_island(
		terrain_root, water_root, modules, recipe, mats, mesh_fn, quality_level, seed
	)
	if debug_view:
		_build_debug_overlay(root, recipe)
	var elevations: Array = []
	for module in modules:
		elevations.append(float(module.get("elevation", 0.0)))
	var bounds: AABB = _compute_bounds(modules)
	return {
		"recipe": recipe.get("name", "unknown"),
		"recipe_id": recipe.get("id", -1),
		"seed": seed,
		"modules": modules,
		"zones": recipe.get("zones", []),
		"river_points": river_result.get("points", []),
		"waterfall": waterfall_result,
		"bridge": recipe.get("bridge", {}),
		"elevations": elevations,
		"elevation_min": _array_min(elevations),
		"elevation_max": _array_max(elevations),
		"elevation_layers": _count_elevation_layers(elevations),
		"bounds": bounds,
		"vertex_count": _count_vertices(root),
		"module_count": modules.size(),
		"connected": modules.size() >= 2,
		"surface_dressed": true,
		"surface_river_points": surface_meta.get("river_points", []),
		"architecture": arch_meta,
	}


static func compose_playable_showcase(
	root: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	world_seed: int,
	route_variant: int = 0,
	debug_view: bool = false,
	transparent_fn: Callable = Callable(),
	animated_nodes: Array = []
) -> Dictionary:
	var recipe_seed: int = 32007 + world_seed * 131 + route_variant * 17
	var recipe: Dictionary = Recipes.recipe_for(Types.RecipeId.RIVER_TERRACE_A, recipe_seed)
	return compose(root, recipe, mats, mesh_fn, quality_level, route_variant, debug_view, transparent_fn, animated_nodes)


static func zone_of_type(zones: Array, zone_type: int) -> Array:
	var found: Array = []
	for zone in zones:
		if int(zone.get("type", -1)) == zone_type:
			found.append(zone)
	return found


static func _rng(seed: int, route_variant: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 32007 + seed * 811 + route_variant * 313
	return rng


static func _build_module(
	parent: Node3D,
	module: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	segments: int,
	rng: RandomNumberGenerator
) -> void:
	var pos: Vector3 = module.get("position", Vector3.ZERO)
	var rx: float = float(module.get("radius_x", 4.0)) * 1.06
	var rz: float = float(module.get("radius_z", 4.0)) * 1.06
	var elevation: float = float(module.get("elevation", 0.0))
	var module_type: int = int(module.get("type", Types.ModuleType.MAIN_PLATEAU))
	var overlap: float = 1.04 if module_type == Types.ModuleType.NARROW_CONNECTOR else 1.0
	rx *= overlap
	rz *= overlap
	_build_ellipse_cap(parent, pos, rx, rz, elevation, segments, mats, mesh_fn, rng, module_type)
	_build_module_rock_skirt(parent, pos, rx, rz, elevation, segments, mats, mesh_fn, module_type)
	if module_type == Types.ModuleType.RAVINE_SECTION:
		pass # V34 ravine walls applied in dress_mega_island
	if module_type == Types.ModuleType.WATER_BASIN:
		Water.build_pond(parent, pos + Vector3(0.0, elevation, 0.0), rx * 0.62, rz * 0.62, 0.28, mats, mesh_fn)


static func _build_ellipse_cap(
	parent: Node3D,
	center: Vector3,
	rx: float,
	rz: float,
	elevation: float,
	segments: int,
	mats: Dictionary,
	mesh_fn: Callable,
	rng: RandomNumberGenerator,
	module_type: int
) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grass_color := Color(0.42, 0.78, 0.38, 1.0)
	var y: float = elevation + 0.02
	var hub := Vector3(center.x, y, center.z)
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var wobble0: float = 1.0 + rng.randf_range(-0.04, 0.04)
		var wobble1: float = 1.0 + rng.randf_range(-0.04, 0.04)
		var p0 := Vector3(center.x + cos(a0) * rx * wobble0, y, center.z + sin(a0) * rz * wobble0)
		var p1 := Vector3(center.x + cos(a1) * rx * wobble1, y, center.z + sin(a1) * rz * wobble1)
		MeshLib._add_tri(st, hub, p0, p1, grass_color)
	var mesh: ArrayMesh = st.commit()
	var node: MeshInstance3D = mesh_fn.call(parent, mesh, TypedAccess.material(mats, "grass_main", "grass_main"))
	node.name = "MegaCap_%d" % module_type
	node.set_meta("mega_module_type", module_type)


static func _build_module_rock_skirt(
	parent: Node3D,
	center: Vector3,
	rx: float,
	rz: float,
	elevation: float,
	segments: int,
	mats: Dictionary,
	mesh_fn: Callable,
	module_type: int
) -> void:
	var depth: float = 2.2 if module_type == Types.ModuleType.MAIN_PLATEAU else 1.6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cliff_color := Color(0.34, 0.36, 0.4, 1.0)
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var top0 := Vector3(center.x + cos(a0) * rx, elevation, center.z + sin(a0) * rz)
		var top1 := Vector3(center.x + cos(a1) * rx, elevation, center.z + sin(a1) * rz)
		var bot0 := Vector3(center.x + cos(a0) * rx * 0.72, elevation - depth, center.z + sin(a0) * rz * 0.72)
		var bot1 := Vector3(center.x + cos(a1) * rx * 0.72, elevation - depth, center.z + sin(a1) * rz * 0.72)
		MeshLib._add_quad(st, top0, top1, bot1, bot0, cliff_color)
	var mesh: ArrayMesh = st.commit()
	var node: MeshInstance3D = mesh_fn.call(parent, mesh, TypedAccess.material(mats, "stone_dark", "rock_dark"))
	node.name = "MegaSkirt_%d" % module_type


static func _build_ravine_cut(
	parent: Node3D,
	center: Vector3,
	rx: float,
	rz: float,
	elevation: float,
	mats: Dictionary,
	mesh_fn: Callable
) -> void:
	var block := MeshLib.beveled_box(Vector3(rx * 1.1, 0.65, rz * 0.55), 0.12, 991, 0.72)
	mesh_fn.call(parent, block, TypedAccess.material(mats, "stone_main", "rock"), center + Vector3(0.0, elevation - 0.45, 0.0))


static func _build_unified_cliff_shell(
	parent: Node3D,
	modules: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	segments: int,
	rng: RandomNumberGenerator
) -> void:
	if modules.is_empty():
		return
	var bounds: AABB = _compute_bounds(modules)
	var shell_rx: float = bounds.size.x * 0.55 + 1.2
	var shell_rz: float = bounds.size.z * 0.55 + 1.2
	var center := Vector3(bounds.position.x + bounds.size.x * 0.5, 0.0, bounds.position.z + bounds.size.z * 0.5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rock_color := Color(0.28, 0.3, 0.34, 1.0)
	var top_y := 0.05
	var bottom_y := -4.2
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments) + rng.randf_range(-0.03, 0.03)
		var a1: float = TAU * float(i + 1) / float(segments) + rng.randf_range(-0.03, 0.03)
		var w0: float = 1.0 + rng.randf_range(-0.08, 0.12)
		var w1: float = 1.0 + rng.randf_range(-0.08, 0.12)
		var top0 := Vector3(center.x + cos(a0) * shell_rx * w0, top_y, center.z + sin(a0) * shell_rz * w0)
		var top1 := Vector3(center.x + cos(a1) * shell_rx * w1, top_y, center.z + sin(a1) * shell_rz * w1)
		var bot0 := Vector3(center.x + cos(a0) * shell_rx * 0.42, bottom_y, center.z + sin(a0) * shell_rz * 0.42)
		var bot1 := Vector3(center.x + cos(a1) * shell_rx * 0.42, bottom_y, center.z + sin(a1) * shell_rz * 0.42)
		MeshLib._add_quad(st, top0, top1, bot1, bot0, rock_color)
	var mesh: ArrayMesh = st.commit()
	var shell: MeshInstance3D = mesh_fn.call(parent, mesh, TypedAccess.material(mats, "stone_main", "rock"))
	shell.name = "MegaCliffShell"


static func _build_bridge(parent: Node3D, bridge_spec: Dictionary, mats: Dictionary, mesh_fn: Callable, quality_level: int) -> void:
	if not bridge_spec.has("start") or not bridge_spec.has("end"):
		return
	ArchGen.build_stone_bridge(parent, bridge_spec["start"], bridge_spec["end"], 1203, mats, mesh_fn, quality_level)


static func _build_landmark(
	parent: Node3D,
	recipe: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int
) -> void:
	pass # V35 architecture cluster replaces standalone landmark placement.


static func _dress_vegetation(
	parent: Node3D,
	recipe: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	seed: int
) -> void:
	var combat_centers: Array = []
	for zone in recipe.get("zones", []):
		if int(zone.get("type", -1)) == Types.ZoneType.COMBAT_ZONE:
			combat_centers.append(zone.get("center", Vector3.ZERO))
	var rng := _rng(seed + 77, 0)
	for module in recipe.get("modules", []):
		var pos: Vector3 = module.get("position", Vector3.ZERO)
		var elevation: float = float(module.get("elevation", 0.0))
		var rx: float = float(module.get("radius_x", 4.0))
		var rz: float = float(module.get("radius_z", 4.0))
		var tree_count: int = 2 if quality_level >= 2 else 1
		for i in range(tree_count):
			var angle: float = rng.randf_range(0.0, TAU)
			var dist: float = rng.randf_range(rx * 0.45, rx * 0.82)
			var tree_pos := pos + Vector3(cos(angle) * dist, elevation, sin(angle) * dist * (rz / maxf(rx, 0.1)))
			if _point_in_combat_zone(tree_pos, combat_centers, 2.8):
				continue
			var variant: VegGen.TreeVariant = VegGen.TreeVariant.TREE_A
			if i % 3 == 1:
				variant = VegGen.TreeVariant.TREE_B
			elif i % 3 == 2:
				variant = VegGen.TreeVariant.TREE_C
			VegGen.create_tree(
				parent,
				tree_pos,
				variant,
				0.82 + rng.randf_range(-0.08, 0.1),
				seed + i,
				mats,
				mesh_fn
			)
		for i in range(4):
			var g_angle: float = rng.randf_range(0.0, TAU)
			var g_dist: float = rng.randf_range(0.5, rx * 0.7)
			var grass_pos := pos + Vector3(cos(g_angle) * g_dist, elevation, sin(g_angle) * g_dist * (rz / maxf(rx, 0.1)))
			if _point_in_combat_zone(grass_pos, combat_centers, 2.2):
				continue
			VegGen.create_grass_clump(
				parent,
				grass_pos,
				VegGen.GrassVariant.MEDIUM,
				0.9 + rng.randf_range(-0.1, 0.12),
				seed + 40 + i,
				mats,
				mesh_fn
			)


static func _point_in_combat_zone(point: Vector3, combat_centers: Array, margin: float) -> bool:
	for center in combat_centers:
		if Vector2(point.x - center.x, point.z - center.z).length() < margin:
			return true
	return false


static func _build_debug_overlay(root: Node3D, recipe: Dictionary) -> void:
	var debug_root := Node3D.new()
	debug_root.name = "MegaDebug"
	root.add_child(debug_root)
	for zone in recipe.get("zones", []):
		var center: Vector3 = zone.get("center", Vector3.ZERO)
		var radius: float = float(zone.get("radius", 2.0))
		var marker := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = 0.08
		marker.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 1.0, 0.18)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.material_override = mat
		marker.position = center + Vector3(0.0, 0.12, 0.0)
		marker.set_meta(Types.ZONE_META_KEY, zone.get("type", -1))
		debug_root.add_child(marker)
	var river_points: Array = Water.sample_river_path(recipe.get("river", {}).get("control_points", []), 4)
	for point in river_points:
		var dot := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.18
		dot.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.5, 1.0, 0.65)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dot.material_override = mat
		dot.position = point
		debug_root.add_child(dot)


static func _compute_bounds(modules: Array) -> AABB:
	if modules.is_empty():
		return AABB(Vector3.ZERO, Vector3.ONE)
	var min_v := Vector3(9999, 9999, 9999)
	var max_v := Vector3(-9999, -9999, -9999)
	for module in modules:
		var pos: Vector3 = module.get("position", Vector3.ZERO)
		var rx: float = float(module.get("radius_x", 1.0))
		var rz: float = float(module.get("radius_z", 1.0))
		var elevation: float = float(module.get("elevation", 0.0))
		min_v.x = minf(min_v.x, pos.x - rx)
		min_v.y = minf(min_v.y, elevation - 2.0)
		min_v.z = minf(min_v.z, pos.z - rz)
		max_v.x = maxf(max_v.x, pos.x + rx)
		max_v.y = maxf(max_v.y, elevation + 1.5)
		max_v.z = maxf(max_v.z, pos.z + rz)
	return AABB(min_v, max_v - min_v)


static func _count_elevation_layers(elevations: Array) -> int:
	var buckets := {}
	for value in elevations:
		var bucket: int = int(round(float(value) * 2.0))
		buckets[bucket] = true
	return buckets.size()


static func _array_min(values: Array) -> float:
	var result := 9999.0
	for value in values:
		result = minf(result, float(value))
	return result


static func _array_max(values: Array) -> float:
	var result := -9999.0
	for value in values:
		result = maxf(result, float(value))
	return result


static func _count_vertices(root: Node) -> int:
	var total := 0
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh != null:
			total += child.mesh.get_surface_count()
		total += _count_vertices(child)
	return total


static func validate_recipe_build(result: Dictionary) -> Array:
	var errors: Array = []
	if not bool(result.get("connected", false)):
		errors.append("modules_not_connected")
	if int(result.get("module_count", 0)) < 2:
		errors.append("module_count_low")
	if int(result.get("elevation_layers", 0)) < 2:
		errors.append("elevation_layers_low")
	var bounds: AABB = result.get("bounds", AABB())
	if not bounds.size.is_finite() or bounds.size.length() < 1.0:
		errors.append("invalid_bounds")
	var zones: Array = result.get("zones", [])
	if zone_of_type(zones, Types.ZoneType.COMBAT_ZONE).is_empty():
		errors.append("missing_combat_zone")
	if zone_of_type(zones, Types.ZoneType.LANDMARK_ZONE).is_empty():
		errors.append("missing_landmark_zone")
	var recipe_name: String = str(result.get("recipe", ""))
	if recipe_name == "river_terrace_a":
		if result.get("river_points", []).size() < 3:
			errors.append("river_points_missing")
		if result.get("waterfall", {}).is_empty():
			errors.append("waterfall_missing")
	return errors
