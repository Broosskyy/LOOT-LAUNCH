extends RefCounted
class_name StylizedVegetationGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const StylizedStartComposition = preload("res://scripts/environment/stylized/stylized_start_composition.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const Density = preload("res://scripts/environment/stylized/stylized_vegetation_density.gd")

const StylizedWorldComposition = preload("res://scripts/environment/stylized/stylized_world_composition.gd")

enum FlowerPreset { PINK_CLUSTER, VIOLET_CLUSTER, WHITE_CLUSTER, MIXED_SOFT_CLUSTER }
enum GrassVariant { SHORT, MEDIUM, EDGE }
enum TreeVariant { TREE_A, TREE_B, TREE_C }

static var _blade_mesh_short: ArrayMesh
static var _blade_mesh_medium: ArrayMesh
static var _crown_mesh_cache: Dictionary = {}


static func _mat(mats: Dictionary, key: String, fallback: String) -> Material:
	return StylizedTypedAccess.material(mats, key, fallback)


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


static func _face_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var n := (b - a).cross(c - a)
	return Vector3.UP if n.length_squared() < 0.000001 else n.normalized()


static func _blade_mesh(height: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw: float = width * 0.5
	var col := Color(0.92, 0.98, 0.9, 1.0)
	var a := Vector3(-hw, 0.0, 0.02)
	var b := Vector3(hw, 0.0, -0.02)
	var c := Vector3(0.0, height, 0.0)
	var n := _face_normal(a, b, c)
	for v in [a, b, c]:
		st.set_normal(n)
		st.set_color(col)
		st.add_vertex(v)
	n = _face_normal(a, c, b)
	for v in [a, c, b]:
		st.set_normal(n)
		st.set_color(col * Color(0.82, 0.86, 0.8, 1.0))
		st.add_vertex(v)
	return st.commit()


static func _get_blade_mesh(variant: GrassVariant) -> ArrayMesh:
	match variant:
		GrassVariant.SHORT:
			if _blade_mesh_short == null:
				_blade_mesh_short = _blade_mesh(0.22, 0.09)
			return _blade_mesh_short
		GrassVariant.EDGE:
			if _blade_mesh_medium == null:
				_blade_mesh_medium = _blade_mesh(0.34, 0.11)
			return _blade_mesh_medium
		_:
			if _blade_mesh_medium == null:
				_blade_mesh_medium = _blade_mesh(0.34, 0.11)
			return _blade_mesh_medium


static func _crown_blob_mesh(seed: int, radius: float, squash: float) -> ArrayMesh:
	var key := "%d_%.2f_%.2f" % [seed, radius, squash]
	if _crown_mesh_cache.has(key):
		return _crown_mesh_cache[key] as ArrayMesh
	var rng := _rng(8800 + seed)
	var segments: int = 7
	var rings: int = 4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(rng.randf_range(-0.06, 0.06), radius * squash, rng.randf_range(-0.06, 0.06))
	for ring in range(rings):
		var phi0: float = float(ring) / float(rings) * PI * 0.5
		var phi1: float = float(ring + 1) / float(rings) * PI * 0.5
		for seg in range(segments):
			var t0: float = float(seg) / float(segments) * TAU
			var t1: float = float(seg + 1) / float(segments) * TAU
			var p00 := Vector3(cos(t0) * sin(phi0), cos(phi0), sin(t0) * sin(phi0)) * radius
			var p10 := Vector3(cos(t1) * sin(phi0), cos(phi0), sin(t1) * sin(phi0)) * radius
			var p01 := Vector3(cos(t0) * sin(phi1), cos(phi1), sin(t0) * sin(phi1)) * radius
			var p11 := Vector3(cos(t1) * sin(phi1), cos(phi1), sin(t1) * sin(phi1)) * radius
			p00.y *= squash
			p10.y *= squash
			p01.y *= squash
			p11.y *= squash
			var col := Color(0.86, 0.96, 0.84, 1.0)
			st.set_normal(_face_normal(p00, p10, p11))
			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p11)
			st.set_normal(_face_normal(p00, p11, p01))
			st.add_vertex(p00)
			st.add_vertex(p11)
			st.add_vertex(p01)
	var mesh: ArrayMesh = st.commit()
	_crown_mesh_cache[key] = mesh
	return mesh


static func create_grass_clump(
	parent: Node3D,
	pos: Vector3,
	variant: GrassVariant,
	scale_value: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable
) -> Node3D:
	var clump := Node3D.new()
	clump.name = "GrassClump"
	clump.set_meta("vegetation_kind", "grass")
	clump.position = pos
	parent.add_child(clump)
	var rng := _rng(1200 + seed)
	var blade_count: int = 4 if variant == GrassVariant.SHORT else 6 if variant == GrassVariant.MEDIUM else 5
	var mat_key: String = "grass_dark" if variant == GrassVariant.EDGE else "grass_main" if variant == GrassVariant.MEDIUM else "grass_light"
	var height_scale: float = 0.85 if variant == GrassVariant.SHORT else 1.0 if variant == GrassVariant.MEDIUM else 0.95
	for i in range(blade_count):
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(0.0, 0.14 * scale_value)
		var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var rot := Vector3(rng.randf_range(-8.0, 8.0), rad_to_deg(angle), rng.randf_range(-16.0, 16.0))
		var blade_mesh: ArrayMesh = _get_blade_mesh(variant)
		mesh_fn.call(
			clump, blade_mesh, _mat(mats, mat_key, "grass_main"),
			offset, Vector3.ONE * scale_value * height_scale * rng.randf_range(0.88, 1.08), rot
		)
	return clump


static func create_flower_cluster(
	parent: Node3D,
	pos: Vector3,
	preset: FlowerPreset,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable
) -> Node3D:
	var cluster := Node3D.new()
	cluster.name = "FlowerCluster"
	cluster.set_meta("vegetation_kind", "flower")
	cluster.position = pos
	parent.add_child(cluster)
	var rng := _rng(2400 + seed)
	var count: int = rng.randi_range(2, 5)
	for i in range(count):
		var offset := Vector3(rng.randf_range(-0.22, 0.22), 0.0, rng.randf_range(-0.22, 0.22))
		_add_single_flower(cluster, offset, preset, seed + i * 17, mats, mesh_fn, rng.randf_range(0.9, 1.12))
	return cluster


static func _add_single_flower(
	parent: Node3D,
	pos: Vector3,
	preset: FlowerPreset,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	scale_value: float
) -> void:
	var flower := Node3D.new()
	flower.position = pos
	flower.scale = Vector3.ONE * scale_value
	parent.add_child(flower)
	var stem: CylinderMesh = CylinderMesh.new()
	stem.top_radius = 0.018
	stem.bottom_radius = 0.024
	stem.height = 0.18 * scale_value
	stem.radial_segments = 5
	mesh_fn.call(flower, stem, _mat(mats, "trunk", "wood"), Vector3(0, 0.09, 0))
	var petal_mat: Material
	match preset:
		FlowerPreset.VIOLET_CLUSTER:
			petal_mat = _mat(mats, "flower_violet", "flower_pink")
		FlowerPreset.WHITE_CLUSTER:
			petal_mat = _mat(mats, "flower_white", "flower_white")
		FlowerPreset.MIXED_SOFT_CLUSTER:
			petal_mat = _mat(mats, "flower_pink" if seed % 2 == 0 else "flower_white", "flower_pink")
		_:
			petal_mat = _mat(mats, "flower_pink", "flower_pink")
	var center: SphereMesh = SphereMesh.new()
	center.radius = 0.035
	center.height = 0.05
	center.radial_segments = 6
	mesh_fn.call(flower, center, _mat(mats, "flower_center", "coin"), Vector3(0, 0.2, 0))
	for angle_i in range(5):
		var angle: float = float(angle_i) * 72.0 + float(seed % 20)
		var petal: PrismMesh = PrismMesh.new()
		petal.size = Vector3(0.1, 0.05, 0.08)
		var offset: Vector3 = Vector3(cos(deg_to_rad(angle)) * 0.06, 0.2, sin(deg_to_rad(angle)) * 0.06)
		mesh_fn.call(flower, petal, petal_mat, offset, Vector3.ONE, Vector3(0, angle, 12))


static func create_tree(
	parent: Node3D,
	pos: Vector3,
	variant: TreeVariant,
	scale_value: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable
) -> Node3D:
	var tree := Node3D.new()
	tree.name = "StylizedTree"
	tree.set_meta("vegetation_kind", "tree")
	tree.position = pos
	tree.scale = Vector3.ONE * scale_value
	parent.add_child(tree)
	var rng := _rng(3600 + seed + int(variant))
	var trunk_h: float = 0.82 if variant == TreeVariant.TREE_B else 0.95 if variant == TreeVariant.TREE_A else 0.74
	var trunk_top: float = 0.1 if variant == TreeVariant.TREE_C else 0.13
	var trunk_bot: float = 0.17 if variant == TreeVariant.TREE_C else 0.2
	var lean := Vector3(rng.randf_range(-5.0, 5.0), 0.0, rng.randf_range(-4.0, 4.0))
	mesh_fn.call(tree, MeshLib.tapered_trunk(trunk_h, trunk_bot, trunk_top, seed + int(variant), 7), _mat(mats, "trunk", "wood"), Vector3(0, 0, 0), Vector3.ONE, lean)
	if variant == TreeVariant.TREE_C:
		mesh_fn.call(tree, MeshLib.tapered_trunk(0.38, 0.08, 0.06, seed + 99, 5), _mat(mats, "trunk", "wood"), Vector3(0.14, trunk_h * 0.68, 0.05), Vector3.ONE, Vector3(-28, 22, 10))
	var crown_defs: Array[Dictionary] = []
	match variant:
		TreeVariant.TREE_A:
			crown_defs = [
				{"pos": Vector3(-0.38, trunk_h + 0.12, 0.1), "r": 0.52, "sq": 0.72, "mat": "leaf_dark"},
				{"pos": Vector3(0.34, trunk_h + 0.28, -0.14), "r": 0.48, "sq": 0.68, "mat": "leaf_light"},
				{"pos": Vector3(0.02, trunk_h + 0.48, 0.16), "r": 0.42, "sq": 0.75, "mat": "leaf_green"},
				{"pos": Vector3(-0.18, trunk_h + 0.58, -0.06), "r": 0.28, "sq": 0.8, "mat": "leaf_light"},
			]
		TreeVariant.TREE_B:
			crown_defs = [
				{"pos": Vector3(-0.28, trunk_h + 0.08, -0.08), "r": 0.58, "sq": 0.65, "mat": "leaf_light"},
				{"pos": Vector3(0.3, trunk_h + 0.24, 0.12), "r": 0.54, "sq": 0.7, "mat": "leaf_dark"},
				{"pos": Vector3(-0.08, trunk_h + 0.42, 0.0), "r": 0.46, "sq": 0.78, "mat": "grass_light"},
				{"pos": Vector3(0.18, trunk_h + 0.54, -0.06), "r": 0.34, "sq": 0.8, "mat": "leaf_green"},
				{"pos": Vector3(-0.22, trunk_h + 0.36, 0.14), "r": 0.3, "sq": 0.72, "mat": "leaf_dark"},
			]
		_:
			crown_defs = [
				{"pos": Vector3(0.22, trunk_h + 0.2, 0.08), "r": 0.5, "sq": 0.7, "mat": "leaf_green"},
				{"pos": Vector3(-0.3, trunk_h + 0.34, -0.1), "r": 0.44, "sq": 0.66, "mat": "leaf_dark"},
			]
	for i in range(crown_defs.size()):
		var def: Dictionary = crown_defs[i]
		var blob: ArrayMesh = _crown_blob_mesh(seed + i * 31, def["r"] as float, def["sq"] as float)
		mesh_fn.call(
			tree, blob, _mat(mats, def["mat"] as String, "leaf_green"),
			def["pos"] as Vector3, Vector3.ONE, Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(0.0, 360.0), rng.randf_range(-5.0, 5.0))
		)
	return tree


static func create_shrub(
	parent: Node3D,
	pos: Vector3,
	scale_value: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable
) -> Node3D:
	var shrub := Node3D.new()
	shrub.name = "Shrub"
	shrub.set_meta("vegetation_kind", "shrub")
	shrub.position = pos
	shrub.scale = Vector3.ONE * scale_value
	parent.add_child(shrub)
	var rng := _rng(4800 + seed)
	var blobs: int = rng.randi_range(2, 4)
	for i in range(blobs):
		var offset := Vector3(rng.randf_range(-0.18, 0.18), 0.0, rng.randf_range(-0.18, 0.18))
		var radius: float = rng.randf_range(0.22, 0.34)
		var mat_key: String = "leaf_dark" if i % 2 == 0 else "leaf_light"
		var blob: ArrayMesh = _crown_blob_mesh(seed + i * 9, radius, 0.55)
		mesh_fn.call(shrub, blob, _mat(mats, mat_key, "leaf_green"), offset + Vector3(0, radius * 0.45, 0))
	return shrub


static func create_tree_cluster(
	parent: Node3D,
	center: Vector3,
	main_variant: TreeVariant,
	support_variant: TreeVariant,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	main_scale: float = 1.0,
	support_scale: float = 0.82
) -> void:
	create_tree(parent, center + Vector3(-0.35, 0.0, 0.18), main_variant, main_scale, seed, mats, mesh_fn)
	create_tree(parent, center + Vector3(0.42, 0.0, -0.12), support_variant, support_scale, seed + 17, mats, mesh_fn)


static func create_grass_multimesh_patch(
	parent: Node3D,
	center: Vector3,
	radius: float,
	instance_count: int,
	seed: int,
	mats: Dictionary,
	variant: GrassVariant = GrassVariant.SHORT
) -> void:
	if instance_count <= 0:
		return
	var patch := Node3D.new()
	patch.name = "GrassPatch"
	patch.set_meta("vegetation_kind", "grass")
	patch.position = center
	parent.add_child(patch)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _get_blade_mesh(variant)
	mm.instance_count = instance_count
	var rng := _rng(6400 + seed)
	var mat_key: String = "grass_dark" if variant == GrassVariant.EDGE else "grass_main"
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat(mats, mat_key, "grass_main")
	patch.add_child(mmi)
	for i in range(instance_count):
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(0.0, radius)
		var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var rot_y: float = rad_to_deg(angle)
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.12, 0.12), rot_y, rng.randf_range(-0.18, 0.18)))
		var scale_v: float = rng.randf_range(0.82, 1.08)
		mm.set_instance_transform(i, Transform3D(basis.scaled(Vector3.ONE * scale_v), offset))


static func _place_start_grass(
	parent: Node3D,
	pos: Vector3,
	variant: GrassVariant,
	scale_value: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	exclusions: Array,
	quality_level: int,
	allow_path_edge: bool = false
) -> void:
	if not Density.can_place_start(pos, exclusions, allow_path_edge):
		return
	if not Density.should_place(seed, 0.92, quality_level):
		return
	create_grass_clump(parent, pos, variant, scale_value, seed, mats, mesh_fn)


static func _place_start_flower(
	parent: Node3D,
	pos: Vector3,
	preset: FlowerPreset,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	exclusions: Array,
	quality_level: int,
	allow_path_edge: bool = false
) -> void:
	if not Density.can_place_start(pos, exclusions, allow_path_edge):
		return
	if not Density.should_place(seed, 0.88, quality_level):
		return
	create_flower_cluster(parent, pos, preset, seed, mats, mesh_fn)


static func dress_start_island(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int = 2,
	island_radius: float = 9.0
) -> void:
	var exclusions: Array = Density.start_island_exclusions()
	# Zone B — path edges (medium, never center).
	var path_accents: Array[Dictionary] = [
		{"pos": Vector3(-1.85, 0.0, 2.15), "grass": GrassVariant.SHORT},
		{"pos": Vector3(1.45, 0.0, 1.75), "grass": GrassVariant.MEDIUM},
		{"pos": Vector3(-1.55, 0.0, 1.95), "grass": GrassVariant.SHORT, "flower": FlowerPreset.PINK_CLUSTER},
		{"pos": Vector3(1.25, 0.0, 1.55), "grass": GrassVariant.MEDIUM},
		{"pos": Vector3(-1.35, 0.0, 1.85), "grass": GrassVariant.SHORT},
		{"pos": Vector3(-0.05, 0.0, 0.35), "grass": GrassVariant.MEDIUM},
		{"pos": Vector3(1.35, 0.0, -0.05), "flower": FlowerPreset.MIXED_SOFT_CLUSTER},
		{"pos": Vector3(0.95, 0.0, -0.55), "grass": GrassVariant.SHORT},
		{"pos": Vector3(-0.85, 0.0, -0.35), "grass": GrassVariant.EDGE},
		{"pos": Vector3(0.45, 0.0, -1.55), "grass": GrassVariant.SHORT},
		{"pos": Vector3(-0.95, 0.0, -1.85), "flower": FlowerPreset.WHITE_CLUSTER},
		{"pos": Vector3(0.85, 0.0, -2.05), "grass": GrassVariant.MEDIUM},
		{"pos": Vector3(0.35, 0.0, -3.25), "grass": GrassVariant.EDGE},
		{"pos": Vector3(-1.05, 0.0, -1.15), "flower": FlowerPreset.PINK_CLUSTER},
		{"pos": Vector3(1.55, 0.0, 0.15), "grass": GrassVariant.SHORT},
		{"pos": Vector3(-1.65, 0.0, 0.55), "grass": GrassVariant.MEDIUM},
	]
	for i in range(path_accents.size()):
		if quality_level < 2 and i % Density.tier_skip_every_nth(2, quality_level) != 0:
			continue
		var accent: Dictionary = path_accents[i]
		var pos: Vector3 = accent["pos"]
		if accent.has("grass"):
			create_grass_clump(parent, pos, accent["grass"], 0.9, 200 + i, mats, mesh_fn)
		if accent.has("flower"):
			create_flower_cluster(parent, pos + Vector3(0.2, 0, 0.14), accent["flower"], 220 + i, mats, mesh_fn)
	# Zone C — chest (medium).
	create_shrub(parent, StylizedStartComposition.CHEST_POS + Vector3(0.9, 0.0, 0.48), 0.95, 301, mats, mesh_fn)
	create_shrub(parent, StylizedStartComposition.CHEST_POS + Vector3(-0.95, 0.0, -0.35), 0.82, 302, mats, mesh_fn)
	_place_start_flower(parent, StylizedStartComposition.CHEST_POS + Vector3(-0.75, 0.0, 0.35), FlowerPreset.PINK_CLUSTER, 303, mats, mesh_fn, exclusions, quality_level)
	_place_start_flower(parent, StylizedStartComposition.CHEST_POS + Vector3(0.4, 0.0, -0.65), FlowerPreset.MIXED_SOFT_CLUSTER, 304, mats, mesh_fn, exclusions, quality_level)
	_place_start_grass(parent, StylizedStartComposition.CHEST_POS + Vector3(-0.35, 0.0, -0.45), GrassVariant.SHORT, 0.88, 305, mats, mesh_fn, exclusions, quality_level)
	_place_start_grass(parent, StylizedStartComposition.CHEST_POS + Vector3(0.55, 0.0, 0.55), GrassVariant.MEDIUM, 0.82, 306, mats, mesh_fn, exclusions, quality_level)
	# Zone D — cannon (low).
	_place_start_grass(parent, Vector3(2.15, 0.0, -2.55), GrassVariant.SHORT, 0.78, 501, mats, mesh_fn, exclusions, quality_level)
	_place_start_grass(parent, Vector3(0.85, 0.0, -3.15), GrassVariant.SHORT, 0.8, 502, mats, mesh_fn, exclusions, quality_level)
	_place_start_grass(parent, Vector3(-0.45, 0.0, -3.55), GrassVariant.SHORT, 0.78, 503, mats, mesh_fn, exclusions, quality_level)
	_place_start_flower(parent, Vector3(2.35, 0.0, -1.45), FlowerPreset.WHITE_CLUSTER, 504, mats, mesh_fn, exclusions, quality_level)
	# Zone E — pad (low).
	_place_start_flower(parent, StylizedStartComposition.PAD_POS + Vector3(-0.55, 0.0, 0.55), FlowerPreset.VIOLET_CLUSTER, 601, mats, mesh_fn, exclusions, quality_level)
	_place_start_flower(parent, StylizedStartComposition.PAD_POS + Vector3(0.6, 0.0, -0.45), FlowerPreset.PINK_CLUSTER, 602, mats, mesh_fn, exclusions, quality_level)
	_place_start_grass(parent, StylizedStartComposition.PAD_POS + Vector3(0.45, 0.0, 0.65), GrassVariant.MEDIUM, 0.86, 603, mats, mesh_fn, exclusions, quality_level)
	# Zone F — ruin / sign (medium-high).
	_place_start_grass(parent, StylizedStartComposition.SIGN_POS + Vector3(-0.55, 0.0, -0.35), GrassVariant.EDGE, 0.9, 401, mats, mesh_fn, exclusions, quality_level)
	_place_start_flower(parent, StylizedStartComposition.SIGN_POS + Vector3(0.45, 0.0, -0.25), FlowerPreset.WHITE_CLUSTER, 402, mats, mesh_fn, exclusions, quality_level)
	create_shrub(parent, StylizedStartComposition.CORNER_RUIN_POS + Vector3(0.75, 0.0, -0.55), 0.92, 403, mats, mesh_fn)
	create_shrub(parent, StylizedStartComposition.CORNER_RUIN_POS + Vector3(-0.85, 0.0, 0.35), 0.85, 404, mats, mesh_fn)
	create_vine_cluster(parent, StylizedStartComposition.CORNER_RUIN_POS + Vector3(-0.35, 0.55, 0.2), -18.0, 1.0, 405, mats, mesh_fn)
	create_vine_cluster(parent, StylizedStartComposition.PILLAR_POS + Vector3(-0.25, 0.35, 0.15), 12.0, 0.95, 406, mats, mesh_fn)
	_place_start_grass(parent, StylizedStartComposition.RUIN_POS + Vector3(0.55, 0.0, -0.45), GrassVariant.MEDIUM, 0.88, 407, mats, mesh_fn, exclusions, quality_level)
	_place_start_flower(parent, StylizedStartComposition.RUIN_POS + Vector3(-0.35, 0.0, 0.25), FlowerPreset.VIOLET_CLUSTER, 408, mats, mesh_fn, exclusions, quality_level)
	create_flower_cluster(parent, StylizedStartComposition.SIGN_POS + Vector3(0.65, 0.0, 0.35), FlowerPreset.PINK_CLUSTER, 409, mats, mesh_fn)
	create_flower_cluster(parent, StylizedStartComposition.PLINTH_POS + Vector3(0.45, 0.0, 0.25), FlowerPreset.WHITE_CLUSTER, 410, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(4.5, 0.0, 1.8), FlowerPreset.MIXED_SOFT_CLUSTER, 411, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(-3.2, 0.0, 2.8), FlowerPreset.PINK_CLUSTER, 412, mats, mesh_fn)
	# Trees — silhouette anchors (clustered).
	create_tree_cluster(parent, StylizedStartComposition.TREE_POS, TreeVariant.TREE_A, TreeVariant.TREE_C, 701, mats, mesh_fn, 1.05, 0.78)
	create_tree(parent, Vector3(5.4, 0.0, -1.1), TreeVariant.TREE_B, 0.82, 702, mats, mesh_fn)
	create_tree(parent, Vector3(-4.8, 0.0, -2.2), TreeVariant.TREE_C, 0.75, 703, mats, mesh_fn)
	# Crystal garden accents.
	create_shrub(parent, StylizedStartComposition.CRYSTAL_POS + Vector3(0.55, 0.0, 0.35), 0.9, 710, mats, mesh_fn)
	_place_start_flower(parent, StylizedStartComposition.CRYSTAL_POS + Vector3(-0.45, 0.0, 0.25), FlowerPreset.VIOLET_CLUSTER, 711, mats, mesh_fn, exclusions, quality_level)
	_place_start_grass(parent, StylizedStartComposition.CRYSTAL_POS + Vector3(0.25, 0.0, -0.35), GrassVariant.SHORT, 0.86, 712, mats, mesh_fn, exclusions, quality_level)
	# Zone G — cliff edge clusters (~35% coverage).
	var edge_positions: Array[Vector3] = Density.edge_ring_positions(island_radius, 16, 0.34, 800)
	for i in range(edge_positions.size()):
		if quality_level < 2 and i % Density.tier_skip_every_nth(2, quality_level) != 0:
			continue
		var pos: Vector3 = edge_positions[i]
		if not Density.can_place_start(pos, exclusions):
			continue
		match i % 4:
			0:
				create_grass_multimesh_patch(parent, pos, 0.45, 6 if quality_level >= 2 else 4, 810 + i, mats, GrassVariant.SHORT)
			1:
				create_grass_clump(parent, pos, GrassVariant.EDGE, 0.92, 820 + i, mats, mesh_fn)
			2:
				create_flower_cluster(parent, pos + Vector3(0.12, 0, 0.08), FlowerPreset.MIXED_SOFT_CLUSTER, 830 + i, mats, mesh_fn)
			_:
				create_grass_clump(parent, pos + Vector3(0.08, 0, -0.06), GrassVariant.SHORT, 0.86, 840 + i, mats, mesh_fn)
	# Composition anchor clusters.
	for i in range(StylizedStartComposition.FLOWER_CLUSTERS.size()):
		if not Density.should_place(900 + i, 0.95, quality_level):
			continue
		var preset: FlowerPreset = [FlowerPreset.PINK_CLUSTER, FlowerPreset.MIXED_SOFT_CLUSTER, FlowerPreset.WHITE_CLUSTER][i % 3]
		var fpos: Vector3 = StylizedStartComposition.FLOWER_CLUSTERS[i]
		if Density.can_place_start(fpos, exclusions):
			create_flower_cluster(parent, fpos, preset, 900 + i, mats, mesh_fn)
	for i in range(StylizedStartComposition.GRASS_CLUSTERS.size()):
		if quality_level < 2 and i % Density.tier_skip_every_nth(2, quality_level) != 0:
			continue
		var gpos: Vector3 = StylizedStartComposition.GRASS_CLUSTERS[i]
		if Density.can_place_start(gpos, exclusions):
			create_grass_clump(parent, gpos, GrassVariant.MEDIUM, 0.94, 910 + i, mats, mesh_fn)


static func create_vine_cluster(
	parent: Node3D,
	pos: Vector3,
	rotation_y: float,
	scale_value: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable
) -> void:
	var vine := Node3D.new()
	vine.name = "VineCluster"
	vine.set_meta("vegetation_kind", "vine")
	vine.position = pos
	vine.rotation_degrees.y = rotation_y
	vine.scale = Vector3.ONE * scale_value
	parent.add_child(vine)
	var rng := _rng(5900 + seed)
	for i in range(rng.randi_range(2, 4)):
		var stem: CylinderMesh = CylinderMesh.new()
		stem.top_radius = 0.02
		stem.bottom_radius = 0.03
		stem.height = rng.randf_range(0.35, 0.62)
		stem.radial_segments = 5
		var x: float = float(i - 1) * 0.12
		mesh_fn.call(
			vine, stem, _mat(mats, "leaf_dark", "grass_dark"),
			Vector3(x, stem.height * 0.5, 0), Vector3.ONE, Vector3(rng.randf_range(8.0, 22.0), 0, rng.randf_range(-8.0, 8.0))
		)
		var leaf: PrismMesh = PrismMesh.new()
		leaf.size = Vector3(0.1, 0.06, 0.08)
		mesh_fn.call(vine, leaf, _mat(mats, "leaf_light", "grass_light"), Vector3(x, stem.height * 0.7, 0.04), Vector3.ONE, Vector3(-30, 20, 0))


static func create_edge_growth(
	parent: Node3D,
	positions: Array,
	mats: Dictionary,
	mesh_fn: Callable,
	base_seed: int
) -> void:
	for i in range(positions.size()):
		var entry = positions[i]
		var pos: Vector3 = entry["pos"] if entry is Dictionary else entry as Vector3
		var variant: GrassVariant = entry.get("variant", GrassVariant.EDGE) if entry is Dictionary else GrassVariant.EDGE
		create_grass_clump(parent, pos, variant, entry.get("scale", 0.9) if entry is Dictionary else 0.9, base_seed + i, mats, mesh_fn)
		if i % 3 == 1 and entry is Dictionary and entry.get("flower", false):
			create_flower_cluster(parent, pos + Vector3(0.15, 0, 0.12), FlowerPreset.MIXED_SOFT_CLUSTER, base_seed + i + 50, mats, mesh_fn)


static func dress_hero_midground(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int = 2,
	island_radius: float = 9.6
) -> void:
	create_tree_cluster(parent, Vector3(5.4, 0.0, 2.1), TreeVariant.TREE_B, TreeVariant.TREE_C, 1001, mats, mesh_fn, 0.98, 0.78)
	create_tree(parent, Vector3(-5.2, 0.0, 3.0), TreeVariant.TREE_A, 0.88, 1002, mats, mesh_fn)
	create_tree(parent, Vector3(2.8, 0.0, 5.8), TreeVariant.TREE_C, 0.82, 1003, mats, mesh_fn)
	create_tree(parent, Vector3(-2.2, 0.0, 5.4), TreeVariant.TREE_B, 0.76, 1004, mats, mesh_fn)
	create_shrub(parent, Vector3(-0.5, 0.0, 5.2), 1.0, 1005, mats, mesh_fn)
	create_shrub(parent, Vector3(1.2, 0.0, 5.5), 0.92, 1006, mats, mesh_fn)
	create_shrub(parent, Vector3(4.2, 0.0, 3.8), 0.88, 1007, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(-1.1, 0.0, 5.0), FlowerPreset.VIOLET_CLUSTER, 1008, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(3.8, 0.0, 4.3), FlowerPreset.PINK_CLUSTER, 1009, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(4.5, 0.0, 4.9), FlowerPreset.MIXED_SOFT_CLUSTER, 1010, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(0.4, 0.0, 3.6), FlowerPreset.WHITE_CLUSTER, 1011, mats, mesh_fn)
	create_vine_cluster(parent, Vector3(3.2, 0.65, 4.5), -12.0, 1.05, 1012, mats, mesh_fn)
	create_vine_cluster(parent, Vector3(-3.5, 0.45, 4.2), 18.0, 0.95, 1013, mats, mesh_fn)
	var grass_spots: Array[Vector3] = [
		Vector3(2.2, 0.0, 3.4), Vector3(-3.8, 0.0, 3.0), Vector3(1.0, 0.0, 4.8),
		Vector3(-2.4, 0.0, 4.2), Vector3(5.1, 0.0, 1.8), Vector3(-4.8, 0.0, 1.5),
	]
	for i in range(grass_spots.size()):
		if i % Density.tier_skip_every_nth(2, quality_level) != 0:
			continue
		create_grass_clump(parent, grass_spots[i], GrassVariant.MEDIUM if i % 2 == 0 else GrassVariant.SHORT, 0.9, 1020 + i, mats, mesh_fn)
	var edge_positions: Array[Vector3] = Density.edge_ring_positions(island_radius, 12, 0.32, 1030)
	for i in range(edge_positions.size()):
		if i % Density.tier_skip_every_nth(2, quality_level) != 0:
			continue
		if i % 2 == 0:
			create_grass_multimesh_patch(parent, edge_positions[i], 0.38, 4, 1040 + i, mats, GrassVariant.SHORT)
		else:
			create_flower_cluster(parent, edge_positions[i], FlowerPreset.VIOLET_CLUSTER, 1050 + i, mats, mesh_fn)


static func dress_playable_island(
	parent: Node3D,
	island_index: int,
	radius: float,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int = 2
) -> void:
	if island_index == 1:
		return
	var spread: float = radius * 0.42
	match island_index % 4:
		2:
			create_tree_cluster(parent, Vector3(-spread * 0.85, 0.0, 0.6), TreeVariant.TREE_A, TreeVariant.TREE_B, 2000 + island_index, mats, mesh_fn, 0.88, 0.72)
			create_tree(parent, Vector3(spread * 0.55, 0.0, 1.4), TreeVariant.TREE_C, 0.78, 2010 + island_index, mats, mesh_fn)
		3:
			create_tree(parent, Vector3(-spread, 0.0, 0.8), TreeVariant.TREE_B, 0.82, 2000 + island_index, mats, mesh_fn)
			create_shrub(parent, Vector3(spread * 0.35, 0.0, 1.2), 0.88, 2011 + island_index, mats, mesh_fn)
			create_shrub(parent, Vector3(-spread * 0.2, 0.0, 1.6), 0.8, 2012 + island_index, mats, mesh_fn)
		0:
			create_flower_cluster(parent, Vector3(spread * 0.25, 0.0, 1.5), FlowerPreset.PINK_CLUSTER, 2020 + island_index, mats, mesh_fn)
			create_flower_cluster(parent, Vector3(-spread * 0.35, 0.0, 1.9), FlowerPreset.WHITE_CLUSTER, 2021 + island_index, mats, mesh_fn)
			create_tree(parent, Vector3(-spread * 0.7, 0.0, 0.5), TreeVariant.TREE_C, 0.8, 2000 + island_index, mats, mesh_fn)
		_:
			create_tree(parent, Vector3(-spread, 0.0, 0.8), TreeVariant.TREE_A, 0.82, 2000 + island_index, mats, mesh_fn)
			create_shrub(parent, Vector3(spread * 0.2, 0.0, 0.5), 0.8, 2030 + island_index, mats, mesh_fn)
	for i in range(4):
		if i % Density.tier_skip_every_nth(2, quality_level) != 0:
			continue
		var angle: float = float(i) * TAU / 4.0 + float(island_index) * 0.4
		var pos := Vector3(cos(angle) * spread * 0.65, 0.0, sin(angle) * spread * 0.55)
		create_grass_clump(parent, pos, GrassVariant.MEDIUM if i % 2 == 0 else GrassVariant.SHORT, 0.86, 2040 + island_index * 10 + i, mats, mesh_fn)


static func dress_target_island(
	parent: Node3D,
	radius: float,
	island_index: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int = 2
) -> void:
	create_grass_clump(parent, Vector3(-radius * 0.2, 0.0, 1.6), GrassVariant.EDGE, 0.8, 3000 + island_index, mats, mesh_fn)
	create_grass_clump(parent, Vector3(radius * 0.32, 0.0, 0.8), GrassVariant.MEDIUM, 0.85, 3001 + island_index, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(radius * 0.15, 0.0, 1.2), FlowerPreset.WHITE_CLUSTER, 3010 + island_index, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(-radius * 0.12, 0.0, 0.5), FlowerPreset.VIOLET_CLUSTER, 3011 + island_index, mats, mesh_fn)
	if island_index % 2 == 0:
		create_shrub(parent, Vector3(-radius * 0.28, 0.0, 0.6), 0.75, 3020 + island_index, mats, mesh_fn)
		create_shrub(parent, Vector3(radius * 0.22, 0.0, 1.8), 0.7, 3021 + island_index, mats, mesh_fn)
	if quality_level >= 2:
		create_tree(parent, Vector3(-radius * 0.45, 0.0, 1.0), TreeVariant.TREE_B, 0.72, 3030 + island_index, mats, mesh_fn)


static func dress_vista_island(
	parent: Node3D,
	vista_index: int,
	radius: float,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int = 2
) -> void:
	if quality_level <= 0:
		return
	if vista_index % 2 == 0:
		create_tree(parent, Vector3(radius * 0.25, 0.0, 0.0), TreeVariant.TREE_C, 0.62, 4000 + vista_index, mats, mesh_fn)
	if vista_index % 3 == 1 and quality_level >= 2:
		create_tree(parent, Vector3(-radius * 0.2, 0.0, 0.35), TreeVariant.TREE_A, 0.55, 4010 + vista_index, mats, mesh_fn)


static func dress_hero_landmark_vegetation(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int = 2
) -> void:
	create_tree_cluster(parent, Vector3(1.6, 0.0, -0.8), TreeVariant.TREE_B, TreeVariant.TREE_C, 8809, mats, mesh_fn, 0.72, 0.58)
	create_tree(parent, Vector3(-1.4, 0.0, 0.6), TreeVariant.TREE_A, 0.65, 8811, mats, mesh_fn)
	create_shrub(parent, Vector3(-1.0, 0.0, -0.5), 0.85, 8810, mats, mesh_fn)
	if quality_level >= 2:
		create_shrub(parent, Vector3(0.8, 0.0, 0.4), 0.72, 8812, mats, mesh_fn)
		create_vine_cluster(parent, Vector3(-0.4, 0.5, 0.25), -10.0, 0.9, 8813, mats, mesh_fn)


static func count_vegetation_nodes(root: Node) -> Dictionary:
	var counts := {"grass": 0, "flower": 0, "tree": 0, "shrub": 0, "vine": 0, "total": 0}
	for child in root.get_children():
		var kind: String = str(child.get_meta("vegetation_kind", ""))
		if counts.has(kind):
			counts[kind] += 1
			counts["total"] += 1
	return counts


static func validate_placement(pos: Vector3, scale_value: float) -> bool:
	return pos.is_finite() and scale_value > 0.05 and scale_value < 3.0


# Legacy API — kept for compatibility.
static func add_grass_tuft(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, scale_value: float = 1.0) -> void:
	create_grass_clump(parent, pos, GrassVariant.MEDIUM, scale_value, int(pos.x * 17.0 + pos.z * 31.0), mats, mesh_fn)


static func add_flower(parent: Node3D, pos: Vector3, variant: int, mats: Dictionary, mesh_fn: Callable) -> void:
	var preset: FlowerPreset = FlowerPreset.PINK_CLUSTER if variant == 0 else FlowerPreset.WHITE_CLUSTER
	create_flower_cluster(parent, pos, preset, int(pos.x * 13.0 + pos.z * 19.0), mats, mesh_fn)


static func add_tree(parent: Node3D, pos: Vector3, scale_value: float, mats: Dictionary, mesh_fn: Callable) -> void:
	create_tree(parent, pos, TreeVariant.TREE_A, scale_value, int(pos.x * 11.0 + pos.z * 23.0), mats, mesh_fn)
