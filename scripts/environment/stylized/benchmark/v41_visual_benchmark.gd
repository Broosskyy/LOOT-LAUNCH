extends RefCounted
class_name V41VisualBenchmark

## V41 — Procedural low-poly visual benchmark composer (single showcase island).

const CliffBuilder = preload("res://scripts/environment/stylized/benchmark/v41_cliff_builder.gd")
const PathKit = preload("res://scripts/environment/stylized/benchmark/v41_path_kit.gd")
const RuinKit = preload("res://scripts/environment/stylized/benchmark/v41_ruin_kit.gd")
const RockKit = preload("res://scripts/environment/stylized/benchmark/v41_rock_kit.gd")
const VegKit = preload("res://scripts/environment/stylized/benchmark/v41_vegetation_kit.gd")
const PropKit = preload("res://scripts/environment/stylized/benchmark/v41_prop_kit.gd")
const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const StylizedWorldComposition = preload("res://scripts/environment/stylized/stylized_world_composition.gd")

const VisualVersion := 41
const BENCHMARK_SEED := 4100

const PLAYER_SPAWN_OFFSET := Vector3(-2.05, 0.0, 2.35)
const CANNON_OFFSET := Vector3(1.35, 2.15, -6.65)
const UPPER_PLATEAU_Y := 2.15

static var _module_registry: Dictionary = {}


static func player_spawn_offset() -> Vector3:
	return PLAYER_SPAWN_OFFSET


static func cannon_offset() -> Vector3:
	return CANNON_OFFSET


static func module_registry() -> Dictionary:
	return _module_registry.duplicate(true)


static func compose_main_island(
	root: Node3D,
	radius: float,
	thickness: float,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	quality_level: int,
	seed: int,
	animated_nodes: Array,
	debug_visuals: bool = false
) -> Dictionary:
	_module_registry.clear()
	var decor := Node3D.new()
	decor.name = "V41BenchmarkDecor"
	root.add_child(decor)
	var cliff_depth: float = maxf(4.8, thickness * 5.2)
	var segments: int = 14 if quality_level >= 2 else 12
	var shell: Dictionary = CliffBuilder.build_island_shell(radius, segments, cliff_depth, seed, CliffBuilder.all_kinds())
	_register_modules("cliff", CliffBuilder.all_kinds())
	var grass_mat: Material = StylizedTypedAccess.material(mats, "grass_main", "grass")
	var rock_mat: Material = StylizedTypedAccess.material(mats, "stone_dark", "rock_dark")
	var cliff_mat: Material = StylizedTypedAccess.material(mats, "cliff_warm", "cliff_warm")
	mesh_fn.call(root, shell["grass"] as ArrayMesh, grass_mat, Vector3.ZERO)
	mesh_fn.call(root, shell["rock"] as ArrayMesh, rock_mat, Vector3.ZERO)
	for seg_data in shell["segments"]:
		var mid: Vector3 = (seg_data["p0"] + seg_data["p1"]) * 0.5
		var angle: float = (seg_data["a0"] + seg_data["a1"]) * 0.5 + PI * 0.5
		mesh_fn.call(
			root, seg_data["mesh"] as ArrayMesh, cliff_mat,
			mid + Vector3(0.0, -0.08, 0.0), Vector3.ONE, Vector3(0.0, rad_to_deg(angle), 0.0)
		)
	_build_upper_plateau(root, mats, mesh_fn, seed)
	_build_stairs(decor, mats, mesh_fn, seed)
	_place_path(decor, mats, mesh_fn, seed)
	_place_ruins(decor, mats, mesh_fn, seed)
	_place_rocks(decor, mats, mesh_fn, seed)
	_place_vegetation(decor, mats, mesh_fn, seed)
	PropKit.place_chest(decor, Vector3(-1.2, 0.04, 0.85), mats, mesh_fn)
	PropKit.place_crystal_altar(decor, Vector3(0.8, UPPER_PLATEAU_Y + 0.04, -8.6), mats, mesh_fn, seed + 44)
	if debug_visuals:
		_add_debug_markers(decor, shell)
	root.set_meta("v41_benchmark_island", true)
	root.set_meta("v41_upper_y", UPPER_PLATEAU_Y)
	return {"radius": radius, "thickness": thickness, "upper_y": UPPER_PLATEAU_Y, "segments": segments}


static func compose_endpoint_island(
	root: Node3D,
	radius: float,
	thickness: float,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	seed: int,
	animated_nodes: Array
) -> void:
	var shell: Dictionary = CliffBuilder.build_island_shell(radius, 10, maxf(3.5, thickness * 4.0), seed + 99, [
		CliffBuilder.CliffKind.STRAIGHT_A, CliffBuilder.CliffKind.CORNER_B, CliffBuilder.CliffKind.PLATEAU_EDGE_A,
	])
	mesh_fn.call(root, shell["grass"] as ArrayMesh, StylizedTypedAccess.material(mats, "grass_main", "grass"), Vector3.ZERO)
	mesh_fn.call(root, shell["rock"] as ArrayMesh, StylizedTypedAccess.material(mats, "stone_dark", "rock_dark"), Vector3.ZERO)
	PropKit.place_portal_endpoint(root, Vector3(0, 0.04, -1.2), mats, mesh_fn, transparent_fn, animated_nodes, 1.05)
	VegKit.place(root, VegKit.VegKind.TREE_SMALL, Vector3(-2.8, 0.0, 2.2), seed, mats, mesh_fn, 0.9)
	VegKit.place(root, VegKit.VegKind.FLOWER, Vector3(2.4, 0.0, 1.8), seed + 3, mats, mesh_fn)


static func compose_background_islands(
	world: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	seed: int
) -> void:
	var vistas: Array = [
		{"center": Vector3(-28.0, 18.0, -42.0), "radius": 5.8, "thickness": 0.9, "index": 81},
		{"center": Vector3(32.0, 24.0, -58.0), "radius": 6.4, "thickness": 1.0, "index": 82, "landmark": true},
		{"center": Vector3(-18.0, 32.0, -88.0), "radius": 4.8, "thickness": 0.85, "index": 83},
		{"center": Vector3(24.0, 14.0, -28.0), "radius": 4.2, "thickness": 0.75, "index": 84},
		{"center": Vector3(-36.0, 28.0, -72.0), "radius": 5.2, "thickness": 0.88, "index": 85},
	]
	for vista in vistas:
		var island_root := Node3D.new()
		island_root.name = "V41Vista_%02d" % int(vista["index"])
		island_root.position = vista["center"]
		world.add_child(island_root)
		var shell: Dictionary = CliffBuilder.build_island_shell(
			float(vista["radius"]), 8, float(vista["thickness"]) * 4.2, seed + int(vista["index"]) * 17,
			[CliffBuilder.CliffKind.STRAIGHT_B, CliffBuilder.CliffKind.OUTCROP_A, CliffBuilder.CliffKind.SLOPE_A]
		)
		var distant_grass: Material = StylizedTypedAccess.material(mats, "distant_grass", "grass_blue")
		var distant_rock: Material = StylizedTypedAccess.material(mats, "distant_rock", "rock_mid")
		mesh_fn.call(island_root, shell["grass"] as ArrayMesh, distant_grass, Vector3.ZERO)
		mesh_fn.call(island_root, shell["rock"] as ArrayMesh, distant_rock, Vector3.ZERO)
		if vista.get("landmark", false):
			_place_vista_castle(island_root, mats, mesh_fn, seed + 200)


static func build_collision(body: StaticBody3D, radius: float, thickness: float) -> void:
	var main := CollisionShape3D.new()
	var main_shape := CylinderShape3D.new()
	main_shape.radius = radius * 0.88
	main_shape.height = thickness
	main.shape = main_shape
	main.position.y = -thickness * 0.5
	body.add_child(main)
	var upper := CollisionShape3D.new()
	var upper_shape := BoxShape3D.new()
	upper_shape.size = Vector3(8.5, 0.45, 10.5)
	upper.shape = upper_shape
	upper.position = Vector3(0.5, UPPER_PLATEAU_Y, -7.5)
	body.add_child(upper)
	var stair := CollisionShape3D.new()
	var stair_shape := BoxShape3D.new()
	stair_shape.size = Vector3(2.2, 0.35, 4.8)
	stair.shape = stair_shape
	stair.position = Vector3(0.2, UPPER_PLATEAU_Y * 0.5, -4.8)
	body.add_child(stair)


static func validate() -> Array[String]:
	var errors: Array[String] = []
	if CliffBuilder.all_kinds().size() < 10:
		errors.append("Cliff module count below minimum")
	if PathKit.all_kinds().size() < 5:
		errors.append("Path stone count below minimum")
	if RuinKit.all_kinds().size() < 8:
		errors.append("Ruin kit count below minimum")
	return errors


static func _register_modules(category: String, kinds: Array) -> void:
	var names: Array[String] = []
	for k in kinds:
		if category == "cliff":
			names.append(CliffBuilder.kind_name(k))
	_module_registry[category] = names


static func _build_upper_plateau(root: Node3D, mats: Dictionary, mesh_fn: Callable, seed: int) -> void:
	var grass_mat: Material = StylizedTypedAccess.material(mats, "grass_light", "grass_light")
	var rock_mat: Material = StylizedTypedAccess.material(mats, "stone_main", "stone_main")
	var top_mesh := Toolkit.beveled_box(Vector3(7.8, 0.38, 9.2), 0.12, seed + 50, 0.9, 0.02, 0.0, 0.04, 1, 1)
	mesh_fn.call(root, top_mesh, grass_mat, Vector3(0.6, UPPER_PLATEAU_Y, -7.8))
	var lip := Toolkit.beveled_box(Vector3(8.1, 0.22, 9.5), 0.08, seed + 51, 0.82, 0.0, 0.06, 0.05, 1, 1)
	mesh_fn.call(root, lip, rock_mat, Vector3(0.6, UPPER_PLATEAU_Y - 0.28, -7.8))


static func _build_stairs(parent: Node3D, mats: Dictionary, mesh_fn: Callable, seed: int) -> void:
	_register_modules("stairs", ["StoneSteps"])
	var stone_mat: Material = StylizedTypedAccess.material(mats, "path_stone", "stone_light")
	var wall_mat: Material = StylizedTypedAccess.material(mats, "ruin_stone", "stone_main")
	for i in range(5):
		var t: float = float(i) / 4.0
		var y: float = lerpf(0.06, UPPER_PLATEAU_Y - 0.12, t)
		var z: float = lerpf(-3.2, -6.4, t)
		var step := Toolkit.beveled_box(Vector3(2.4 - t * 0.3, 0.22, 0.82), 0.05, seed + i * 3, 0.86, 0.0, 0.04, 0.06, 1, 1)
		mesh_fn.call(parent, step, stone_mat, Vector3(0.15, y, z), Vector3.ONE, Vector3(0, float(i) * 3.0, 0))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.WALL_SHORT, seed + 60), wall_mat, Vector3(-1.35, 0.04, -4.2), Vector3.ONE, Vector3(0, 18, 0))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.WALL_BROKEN, seed + 61), wall_mat, Vector3(1.55, 0.04, -4.5), Vector3.ONE, Vector3(0, -12, 0))


static func _place_path(parent: Node3D, mats: Dictionary, mesh_fn: Callable, seed: int) -> void:
	_register_modules("path", PathKit.all_kinds().map(func(k): return PathKit.kind_name(k)))
	var waypoints: Array = [
		{"pos": Vector3(-1.4, 0.04, 1.6), "kind": PathKit.PathStoneKind.A, "rot_y": -8.0},
		{"pos": Vector3(-0.7, 0.04, 0.55), "kind": PathKit.PathStoneKind.B, "rot_y": 14.0, "scale": 1.05},
		{"pos": Vector3(0.05, 0.04, -0.35), "kind": PathKit.PathStoneKind.C, "rot_y": -5.0},
		{"pos": Vector3(0.55, 0.04, -1.45), "kind": PathKit.PathStoneKind.D, "rot_y": 22.0},
		{"pos": Vector3(0.25, 0.04, -2.55), "kind": PathKit.PathStoneKind.E, "rot_y": -16.0, "scale": 0.96},
		{"pos": Vector3(-0.15, UPPER_PLATEAU_Y + 0.04, -7.0), "kind": PathKit.PathStoneKind.A, "rot_y": 6.0},
		{"pos": Vector3(0.45, UPPER_PLATEAU_Y + 0.04, -8.2), "kind": PathKit.PathStoneKind.C, "rot_y": -11.0},
		{"pos": Vector3(1.05, UPPER_PLATEAU_Y + 0.04, -9.5), "kind": PathKit.PathStoneKind.B, "rot_y": 18.0},
	]
	PathKit.place_path(parent, waypoints, mats, mesh_fn, seed + 100)


static func _place_ruins(parent: Node3D, mats: Dictionary, mesh_fn: Callable, seed: int) -> void:
	_register_modules("ruin", RuinKit.all_kinds().map(func(k): return RuinKit.kind_name(k)))
	var ruin_mat: Material = StylizedTypedAccess.material(mats, "ruin_stone", "stone_main")
	var center := Vector3(0.2, 0.04, -2.8)
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.PILLAR_SHORT, seed), ruin_mat, center + Vector3(-1.1, 0, 0))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.PILLAR_BROKEN, seed + 1), ruin_mat, center + Vector3(0.9, 0, -0.2), Vector3.ONE, Vector3(0, 24, 0))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.ARCH_SMALL, seed + 2), ruin_mat, center + Vector3(0.1, 0, -0.85), Vector3(0.92, 1.0, 0.92))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.RUBBLE_A, seed + 3), ruin_mat, center + Vector3(-0.4, 0, 0.65))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.STONE_BLOCK_A, seed + 4), ruin_mat, center + Vector3(1.35, 0, 0.45), Vector3.ONE, Vector3(0, -18, 4))


static func _place_rocks(parent: Node3D, mats: Dictionary, mesh_fn: Callable, seed: int) -> void:
	_register_modules("rock", ["Small", "Medium", "Large", "Rubble", "Landmark"])
	var rock_mat: Material = StylizedTypedAccess.material(mats, "stone_dark", "rock_dark")
	var placements: Array = [
		{"kind": RockKit.RockKind.SMALL, "pos": Vector3(-3.8, 0.02, 1.2), "rot": 22.0},
		{"kind": RockKit.RockKind.SMALL, "pos": Vector3(3.5, 0.02, 2.8), "rot": -14.0},
		{"kind": RockKit.RockKind.MEDIUM, "pos": Vector3(-4.2, 0.02, -1.5), "rot": 8.0},
		{"kind": RockKit.RockKind.RUBBLE, "pos": Vector3(2.8, 0.02, -1.2), "rot": 0.0},
		{"kind": RockKit.RockKind.LANDMARK, "pos": Vector3(-5.5, 0.02, 3.8), "rot": 12.0, "scale": 0.85},
	]
	for i in range(placements.size()):
		var p: Dictionary = placements[i]
		var mesh: ArrayMesh = RockKit.build(p["kind"], seed + i * 11)
		mesh_fn.call(parent, mesh, rock_mat, p["pos"], Vector3.ONE * float(p.get("scale", 1.0)), Vector3(0, float(p["rot"]), 0))


static func _place_vegetation(parent: Node3D, mats: Dictionary, mesh_fn: Callable, seed: int) -> void:
	_register_modules("vegetation", [
		"GrassSmall", "GrassMedium", "BroadLeaf", "Flower", "Bush", "TreeSmall", "TreeMedium", "HeroTree",
	])
	VegKit.place(parent, VegKit.VegKind.GRASS_SMALL, Vector3(-2.8, 0.0, 0.5), seed, mats, mesh_fn)
	VegKit.place(parent, VegKit.VegKind.GRASS_MEDIUM, Vector3(2.2, 0.0, 1.8), seed + 1, mats, mesh_fn)
	VegKit.place(parent, VegKit.VegKind.FLOWER, Vector3(-0.8, 0.0, 2.2), seed + 2, mats, mesh_fn)
	VegKit.place(parent, VegKit.VegKind.BROAD_LEAF, Vector3(3.2, 0.0, -0.4), seed + 3, mats, mesh_fn, 0.9)
	VegKit.place(parent, VegKit.VegKind.BUSH, Vector3(-3.2, 0.0, 2.8), seed + 4, mats, mesh_fn, 0.85)
	VegKit.place(parent, VegKit.VegKind.TREE_SMALL, Vector3(4.8, 0.0, 3.5), seed + 5, mats, mesh_fn, 0.88)
	VegKit.place(parent, VegKit.VegKind.TREE_MEDIUM, Vector3(-5.2, 0.0, -2.5), seed + 6, mats, mesh_fn, 1.0)
	VegKit.place(parent, VegKit.VegKind.HERO_TREE, Vector3(-4.5, 0.0, 4.2), seed + 7, mats, mesh_fn, 1.15)
	VegKit.place(parent, VegKit.VegKind.FLOWER, Vector3(0.6, UPPER_PLATEAU_Y, -6.8), seed + 8, mats, mesh_fn)


static func _place_vista_castle(parent: Node3D, mats: Dictionary, mesh_fn: Callable, seed: int) -> void:
	var ruin_mat: Material = StylizedTypedAccess.material(mats, "ruin_stone", "stone_main")
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.PILLAR_SHORT, seed), ruin_mat, Vector3(-0.8, 0.04, 0.2), Vector3(0.7, 1.1, 0.7))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.WALL_SHORT, seed + 1), ruin_mat, Vector3(0.5, 0.04, -0.3), Vector3(0.65, 0.9, 0.65))
	mesh_fn.call(parent, RuinKit.build(RuinKit.RuinKind.ARCH_SMALL, seed + 2), ruin_mat, Vector3(0.0, 0.04, 0.6), Vector3(0.55, 0.8, 0.55))


static func _add_debug_markers(parent: Node3D, shell: Dictionary) -> void:
	var ring: PackedVector3Array = shell.get("top_ring", PackedVector3Array())
	for i in range(ring.size()):
		var marker := MeshInstance3D.new()
		marker.name = "DebugCliff_%02d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		marker.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.2, 0.8, 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override = mat
		marker.position = ring[i] + Vector3(0, 0.2, 0)
		parent.add_child(marker)
