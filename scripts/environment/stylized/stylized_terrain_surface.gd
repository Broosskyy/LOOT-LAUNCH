extends RefCounted
class_name StylizedTerrainSurface

## V34 — Stylized terrain surface layering (grass → lip → cliff).

const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const Stones = preload("res://scripts/environment/stylized/mesh/stylized_stone_builder.gd")
const Profiles = preload("res://scripts/environment/stylized/mesh/stylized_profile_builder.gd")
const Curves = preload("res://scripts/environment/stylized/mesh/stylized_curve_builder.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const TypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const MegaTypes = preload("res://scripts/environment/stylized/mega_island_types.gd")

enum SurfaceTag { GRASS, FOREST_FLOOR, RUINS_GROUND, CRYSTAL_GROUND, WET_BANK, FLOWER_MEADOW }

const SURFACE_META := "terrain_surface_tag"


static func dress_hero_island(
	parent: Node3D,
	radius: float,
	island_index: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	seed: int = 0
) -> void:
	var rng := _rng(seed + island_index * 97)
	var detail: int = 2 if quality_level >= 2 else 1
	_build_edge_lip_ring(parent, Vector3.ZERO, radius, radius * 0.94, 0.0, 18, rng, mats, mesh_fn, detail)
	_place_surface_breakup(parent, radius, rng, mats, mesh_fn, detail, 5)
	_place_outcrops(parent, radius, rng, mats, mesh_fn, detail, 4)


static func dress_mega_island(
	terrain_root: Node3D,
	water_root: Node3D,
	modules: Array,
	recipe: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	seed: int
) -> Dictionary:
	var rng := _rng(seed + 44)
	var detail: int = 2 if quality_level >= 2 else 1
	var combat_centers: Array = _combat_centers(recipe)
	for module in modules:
		var pos: Vector3 = module.get("position", Vector3.ZERO)
		var rx: float = float(module.get("radius_x", 4.0))
		var rz: float = float(module.get("radius_z", 4.0))
		var elevation: float = float(module.get("elevation", 0.0))
		if not _near_combat_center(pos, combat_centers, 3.5):
			_build_module_edge_lip(terrain_root, pos, rx, rz, elevation, rng, mats, mesh_fn, detail)
			if rng.randf() > 0.45:
				_build_grass_shelf(terrain_root, pos, rx, rz, elevation, rng, mats, mesh_fn, detail)
	_build_module_seams(terrain_root, modules, rng, mats, mesh_fn, detail)
	var river_points: Array = []
	if bool(recipe.get("river", {}).get("enabled", false)):
		river_points = Curves.sample_path(recipe.get("river", {}).get("control_points", []), 6)
		_build_river_channel(water_root, river_points, float(recipe.get("river", {}).get("width", 1.2)), float(recipe.get("river", {}).get("depth", 0.22)), seed, mats, mesh_fn, detail)
	var waterfall_spec: Dictionary = recipe.get("waterfall", {})
	if bool(waterfall_spec.get("enabled", false)):
		_build_waterfall_notch(water_root, waterfall_spec, river_points, mats, mesh_fn, detail, seed)
	for module in modules:
		if int(module.get("type", -1)) == MegaTypes.ModuleType.WATER_BASIN:
			var pos: Vector3 = module.get("position", Vector3.ZERO)
			var rx: float = float(module.get("radius_x", 4.0)) * 0.62
			var rz: float = float(module.get("radius_z", 4.0)) * 0.62
			var elevation: float = float(module.get("elevation", 0.0))
			_build_pond_shoreline(water_root, pos + Vector3(0.0, elevation, 0.0), rx, rz, mats, mesh_fn, seed, detail)
		if int(module.get("type", -1)) == MegaTypes.ModuleType.RAVINE_SECTION:
			_build_ravine_walls(terrain_root, module, mats, mesh_fn, seed, detail)
	return {"river_points": river_points, "module_count": modules.size()}


static func dress_path_embedded(
	parent: Node3D,
	waypoints: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int,
	quality_level: int = 2
) -> void:
	if waypoints.size() < 2:
		return
	var points: Array[Vector3] = []
	for data in waypoints:
		var pos: Vector3 = data["pos"]
		points.append(Vector3(pos.x, float(data.get("y", 0.04)) - 0.03, pos.z))
	_build_path_channel(parent, points, 0.95, seed, mats, mesh_fn, 2 if quality_level >= 2 else 1)


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 34007 + seed * 811
	return rng


static func _combat_centers(recipe: Dictionary) -> Array:
	var centers: Array = []
	for zone in recipe.get("zones", []):
		if int(zone.get("type", -1)) == MegaTypes.ZoneType.COMBAT_ZONE:
			centers.append(zone.get("center", Vector3.ZERO))
	return centers


static func _near_combat_center(pos: Vector3, centers: Array, margin: float) -> bool:
	for center in centers:
		if Vector2(pos.x - center.x, pos.z - center.z).length() < margin:
			return true
	return false


static func _build_edge_lip_ring(
	parent: Node3D,
	center: Vector3,
	rx: float,
	rz: float,
	elevation: float,
	segments: int,
	rng: RandomNumberGenerator,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int
) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var earth := Color(0.52, 0.46, 0.4, 1.0)
	var stone := Color(0.46, 0.44, 0.42, 1.0)
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var w0: float = 1.0 + rng.randf_range(-0.06, 0.08)
		var w1: float = 1.0 + rng.randf_range(-0.06, 0.08)
		var outer0 := center + Vector3(cos(a0) * rx * w0, elevation + 0.01, sin(a0) * rz * w0)
		var outer1 := center + Vector3(cos(a1) * rx * w1, elevation + 0.01, sin(a1) * rz * w1)
		var inner0 := center + Vector3(cos(a0) * rx * 0.9 * w0, elevation - 0.06, sin(a0) * rz * 0.9 * w0)
		var inner1 := center + Vector3(cos(a1) * rx * 0.9 * w1, elevation - 0.06, sin(a1) * rz * 0.9 * w1)
		var shelf0 := center + Vector3(cos(a0) * rx * 0.82 * w0, elevation - 0.14, sin(a0) * rz * 0.82 * w0)
		var shelf1 := center + Vector3(cos(a1) * rx * 0.82 * w1, elevation - 0.14, sin(a1) * rz * 0.82 * w1)
		MeshLib._add_quad(st, outer0, outer1, inner1, inner0, earth)
		MeshLib._add_quad(st, inner0, inner1, shelf1, shelf0, stone)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var node: MeshInstance3D = mesh_fn.call(parent, mesh, TypedAccess.material(mats, "dirt", "dirt"))
	node.name = "TerrainEdgeLip"
	node.set_meta(SURFACE_META, SurfaceTag.GRASS)


static func _build_module_edge_lip(
	parent: Node3D,
	center: Vector3,
	rx: float,
	rz: float,
	elevation: float,
	rng: RandomNumberGenerator,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int
) -> void:
	_build_edge_lip_ring(parent, center, rx * 0.94, rz * 0.94, elevation + 0.02, 14 if detail >= 2 else 10, rng, mats, mesh_fn, detail)


static func _build_grass_shelf(
	parent: Node3D,
	center: Vector3,
	rx: float,
	rz: float,
	elevation: float,
	rng: RandomNumberGenerator,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int
) -> void:
	var angle: float = rng.randf_range(0.0, TAU)
	var dist: float = rng.randf_range(rx * 0.35, rx * 0.72)
	var shelf_pos := center + Vector3(cos(angle) * dist, elevation + 0.08, sin(angle) * dist * (rz / maxf(rx, 0.1)))
	var mesh: ArrayMesh = Toolkit.beveled_box(Vector3(1.4, 0.14, 1.0), 0.06, int(rng.randi() % 9000), 0.9, 0.04, 0.0, 0.06, 1, detail)
	mesh_fn.call(parent, mesh, TypedAccess.material(mats, "grass_dark", "grass_dark"), shelf_pos, Vector3.ONE, Vector3(0.0, rad_to_deg(angle), 0.0))


static func _place_surface_breakup(
	parent: Node3D,
	radius: float,
	rng: RandomNumberGenerator,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int,
	count: int
) -> void:
	for i in range(count):
		var angle: float = TAU * float(i) / float(count) + rng.randf_range(-0.25, 0.25)
		var dist: float = radius * rng.randf_range(0.25, 0.78)
		var mound := Toolkit.beveled_box(
			Vector3(rng.randf_range(0.8, 1.4), rng.randf_range(0.08, 0.16), rng.randf_range(0.7, 1.2)),
			0.05, 8100 + i, 0.88, 0.03, 0.0, 0.05, 1, detail
		)
		mesh_fn.call(
			parent, mound, TypedAccess.material(mats, "grass_light", "grass_light"),
			Vector3(cos(angle) * dist, 0.06, sin(angle) * dist * 0.9), Vector3.ONE,
			Vector3(0.0, rng.randf_range(0.0, 360.0), 0.0)
		)


static func _place_outcrops(
	parent: Node3D,
	radius: float,
	rng: RandomNumberGenerator,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int,
	count: int
) -> void:
	for i in range(count):
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = radius * rng.randf_range(0.72, 0.92)
		var rock := Toolkit.irregular_stone(
			Stones.StoneKind.CLIFF_CHUNK if i % 2 == 0 else Stones.StoneKind.BLOCK_STONE,
			rng.randf_range(0.22, 0.38), rng.randf_range(0.18, 0.32), 5, 0.1, 0.15, 0.2,
			9200 + i, detail
		)
		mesh_fn.call(
			parent, rock, TypedAccess.material(mats, "stone_main", "rock"),
			Vector3(cos(angle) * dist, 0.02, sin(angle) * dist), Vector3.ONE,
			Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(0.0, 360.0), rng.randf_range(-8.0, 8.0))
		)


static func _build_module_seams(
	parent: Node3D,
	modules: Array,
	rng: RandomNumberGenerator,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int
) -> void:
	for i in range(modules.size()):
		for j in range(i + 1, modules.size()):
			var a: Dictionary = modules[i]
			var b: Dictionary = modules[j]
			var pa: Vector3 = a.get("position", Vector3.ZERO)
			var pb: Vector3 = b.get("position", Vector3.ZERO)
			var dist: float = Vector2(pa.x - pb.x, pa.z - pb.z).length()
			var touch: float = float(a.get("radius_x", 4.0)) + float(b.get("radius_x", 4.0))
			if dist > touch * 0.95:
				continue
			var mid := (pa + pb) * 0.5
			mid.y = maxf(float(a.get("elevation", 0.0)), float(b.get("elevation", 0.0))) + 0.04
			var blend := Toolkit.beveled_box(Vector3(1.6, 0.08, 1.0), 0.05, 9400 + i * 17 + j, 0.86, 0.0, 0.0, 0.04, 1, detail)
			var yaw: float = rad_to_deg(atan2(pb.x - pa.x, pb.z - pa.z))
			mesh_fn.call(parent, blend, TypedAccess.material(mats, "grass_main", "grass_main"), mid, Vector3.ONE, Vector3(0.0, yaw, 0.0))


static func _build_path_channel(
	parent: Node3D,
	points: Array[Vector3],
	width: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int
) -> void:
	if points.size() < 2:
		return
	var profile: PackedVector2Array = Profiles.sample_profile(Profiles.ProfileKind.TRAPEZOID, width, 0.08, 4, seed)
	var mesh: ArrayMesh = Curves.extrude_profile(profile, points, seed, 0.35, false)
	var node: MeshInstance3D = mesh_fn.call(parent, mesh, TypedAccess.material(mats, "dirt", "dirt"))
	node.name = "PathChannel"
	node.set_meta(SURFACE_META, SurfaceTag.RUINS_GROUND)


static func _build_river_channel(
	parent: Node3D,
	path: Array,
	width: float,
	depth: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int
) -> void:
	if path.is_empty():
		return
	var channel_points: Array[Vector3] = []
	for p in path:
		channel_points.append(Vector3(p.x, float(p.y) - depth * 0.35, p.z))
	var profile: PackedVector2Array = Profiles.sample_profile(Profiles.ProfileKind.STONE_EDGE, width * 1.15, depth * 0.55, 5, seed)
	var channel: ArrayMesh = Curves.extrude_profile(profile, channel_points, seed + 11, 0.2, false)
	mesh_fn.call(parent, channel, TypedAccess.material(mats, "dirt", "dirt")).name = "RiverChannel"
	for i in range(0, channel_points.size(), 3 if detail >= 2 else 4):
		for side in [-1.0, 1.0]:
			var pos: Vector3 = channel_points[i]
			var forward: Vector3 = Vector3.FORWARD
			if i < channel_points.size() - 1:
				forward = (channel_points[i + 1] - channel_points[i]).normalized()
			var right: Vector3 = Vector3(-forward.z, 0.0, forward.x) * float(side) * width * 0.62
			var rock := Toolkit.irregular_stone(Stones.StoneKind.FLAT_STONE, 0.18, 0.08, 5, 0.08, 0.0, 0.35, seed + i, detail)
			mesh_fn.call(parent, rock, TypedAccess.material(mats, "path_stone", "stone_light"), pos + right + Vector3(0.0, 0.02, 0.0))


static func _build_pond_shoreline(
	parent: Node3D,
	center: Vector3,
	radius_x: float,
	radius_z: float,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int,
	detail: int
) -> void:
	var ring := Toolkit.terrain_contour_ring(radius_x * 1.05, 16 if detail >= 2 else 12, 0.1, radius_z / maxf(radius_x, 0.1), -0.08, seed, detail)
	mesh_fn.call(parent, ring, TypedAccess.material(mats, "dirt", "dirt"), center).name = "PondShore"
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0
		var rock := Toolkit.irregular_stone(Stones.StoneKind.FLAT_STONE, 0.16, 0.06, 5, 0.1, 0.0, 0.4, seed + i * 3, detail)
		mesh_fn.call(
			parent, rock, TypedAccess.material(mats, "stone_warm", "stone_warm"),
			center + Vector3(cos(angle) * radius_x * 0.92, -0.02, sin(angle) * radius_z * 0.92)
		)


static func _build_waterfall_notch(
	parent: Node3D,
	spec: Dictionary,
	river_points: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	detail: int,
	seed: int
) -> void:
	var origin: Vector3 = spec.get("origin", Vector3.ZERO)
	var width: float = float(spec.get("width", 1.4))
	var notch := Toolkit.beveled_box(Vector3(width * 1.1, 0.22, 0.55), 0.06, seed + 501, 0.82, 0.0, 0.05, 0.06, 1, detail)
	mesh_fn.call(parent, notch, TypedAccess.material(mats, "stone_dark", "rock_dark"), origin + Vector3(0.0, -0.08, 0.28))
	if river_points.size() >= 2:
		var approach: Array = [river_points[river_points.size() - 2], origin]
		var lip := Toolkit.curved_beam(approach, Profiles.ProfileKind.STONE_EDGE, width * 0.9, 0.12, seed + 502, 3, detail)
		mesh_fn.call(parent, lip, TypedAccess.material(mats, "path_stone", "stone_light"), origin)
	for side in [-0.42, 0.42]:
		var chunk := Toolkit.irregular_stone(Stones.StoneKind.CLIFF_CHUNK, 0.28, 0.35, 5, 0.1, 0.2, 0.0, seed + int(side * 100.0), detail)
		mesh_fn.call(parent, chunk, TypedAccess.material(mats, "stone_main", "rock"), origin + Vector3(side, -0.12, 0.15))


static func _build_ravine_walls(
	parent: Node3D,
	module: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	seed: int,
	detail: int
) -> void:
	var pos: Vector3 = module.get("position", Vector3.ZERO)
	var rx: float = float(module.get("radius_x", 4.0))
	var rz: float = float(module.get("radius_z", 4.0))
	var elevation: float = float(module.get("elevation", 0.0))
	var wall_l := Toolkit.beveled_box(Vector3(0.35, 0.75, rz * 0.9), 0.05, seed + 601, 0.8, 0.0, 0.0, 0.05, 1, detail)
	var wall_r := Toolkit.beveled_box(Vector3(0.35, 0.75, rz * 0.9), 0.05, seed + 602, 0.78, 0.0, 0.0, 0.05, 1, detail)
	mesh_fn.call(parent, wall_l, TypedAccess.material(mats, "stone_dark", "rock_dark"), pos + Vector3(-rx * 0.55, elevation - 0.35, 0.0))
	mesh_fn.call(parent, wall_r, TypedAccess.material(mats, "stone_dark", "rock_dark"), pos + Vector3(rx * 0.55, elevation - 0.35, 0.0))
	var floor := Toolkit.irregular_stone(Stones.StoneKind.FLAT_STONE, rx * 0.45, 0.12, 6, 0.08, 0.0, 0.5, seed + 603, detail)
	mesh_fn.call(parent, floor, TypedAccess.material(mats, "dirt", "dirt"), pos + Vector3(0.0, elevation - 0.52, 0.0))


static func validate_surface_metadata(root: Node) -> bool:
	for child in root.get_children():
		if child is Node3D and not validate_surface_metadata(child):
			return false
	return true
