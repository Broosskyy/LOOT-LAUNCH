extends RefCounted
class_name StylizedVegetationGenerator

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const StylizedStartComposition = preload("res://scripts/environment/stylized/stylized_start_composition.gd")

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
	var trunk_top: float = 0.11 if variant == TreeVariant.TREE_C else 0.14
	var trunk_bot: float = 0.18 if variant == TreeVariant.TREE_C else 0.22
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = trunk_top
	trunk.bottom_radius = trunk_bot
	trunk.height = trunk_h
	trunk.radial_segments = 7
	var lean := Vector3(rng.randf_range(-4.0, 4.0), 0.0, rng.randf_range(-3.0, 3.0))
	mesh_fn.call(tree, trunk, _mat(mats, "trunk", "wood"), Vector3(0, trunk_h * 0.5, 0), Vector3.ONE, lean)
	if variant == TreeVariant.TREE_C:
		var branch: CylinderMesh = CylinderMesh.new()
		branch.top_radius = 0.07
		branch.bottom_radius = 0.09
		branch.height = 0.42
		branch.radial_segments = 6
		mesh_fn.call(tree, branch, _mat(mats, "trunk", "wood"), Vector3(0.12, trunk_h * 0.72, 0.04), Vector3.ONE, Vector3(-24, 18, 8))
	var crown_defs: Array[Dictionary] = []
	match variant:
		TreeVariant.TREE_A:
			crown_defs = [
				{"pos": Vector3(-0.38, trunk_h + 0.18, 0.1), "r": 0.52, "sq": 0.72, "mat": "leaf_dark"},
				{"pos": Vector3(0.34, trunk_h + 0.32, -0.14), "r": 0.48, "sq": 0.68, "mat": "leaf_light"},
				{"pos": Vector3(0.02, trunk_h + 0.52, 0.16), "r": 0.42, "sq": 0.75, "mat": "leaf_green"},
			]
		TreeVariant.TREE_B:
			crown_defs = [
				{"pos": Vector3(-0.28, trunk_h + 0.12, -0.08), "r": 0.58, "sq": 0.65, "mat": "leaf_light"},
				{"pos": Vector3(0.3, trunk_h + 0.28, 0.12), "r": 0.54, "sq": 0.7, "mat": "leaf_dark"},
				{"pos": Vector3(-0.08, trunk_h + 0.46, 0.0), "r": 0.46, "sq": 0.78, "mat": "grass_light"},
				{"pos": Vector3(0.18, trunk_h + 0.58, -0.06), "r": 0.34, "sq": 0.8, "mat": "leaf_green"},
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


static func dress_start_island(parent: Node3D, mats: Dictionary, mesh_fn: Callable) -> void:
	# Zone A — spawn: very low density, away from player footprint.
	create_grass_clump(parent, Vector3(2.8, 0.0, 2.6), GrassVariant.SHORT, 0.85, 101, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(3.4, 0.0, 1.2), FlowerPreset.WHITE_CLUSTER, 102, mats, mesh_fn)
	# Zone B — path accents (alternating grass / flower / gap rhythm).
	var path_accents: Array[Dictionary] = [
		{"pos": Vector3(-1.35, 0.0, 1.85), "grass": GrassVariant.SHORT, "flower": FlowerPreset.PINK_CLUSTER},
		{"pos": Vector3(-0.05, 0.0, 0.35), "grass": GrassVariant.MEDIUM},
		{"pos": Vector3(0.95, 0.0, -0.55), "flower": FlowerPreset.MIXED_SOFT_CLUSTER},
		{"pos": Vector3(0.45, 0.0, -1.55), "grass": GrassVariant.SHORT},
		{"pos": Vector3(-0.55, 0.0, -2.45), "flower": FlowerPreset.WHITE_CLUSTER},
		{"pos": Vector3(0.35, 0.0, -3.25), "grass": GrassVariant.EDGE},
	]
	for i in range(path_accents.size()):
		var accent: Dictionary = path_accents[i]
		if accent.has("grass"):
			create_grass_clump(parent, accent["pos"], accent["grass"], 0.92, 200 + i, mats, mesh_fn)
		if accent.has("flower"):
			create_flower_cluster(parent, accent["pos"] + Vector3(0.18, 0, 0.14), accent["flower"], 220 + i, mats, mesh_fn)
	# Zone C — chest garden.
	create_shrub(parent, StylizedStartComposition.CHEST_POS + Vector3(0.85, 0.0, 0.45), 0.95, 301, mats, mesh_fn)
	create_flower_cluster(parent, StylizedStartComposition.CHEST_POS + Vector3(-0.75, 0.0, 0.35), FlowerPreset.PINK_CLUSTER, 302, mats, mesh_fn)
	create_flower_cluster(parent, StylizedStartComposition.CHEST_POS + Vector3(0.4, 0.0, -0.65), FlowerPreset.MIXED_SOFT_CLUSTER, 303, mats, mesh_fn)
	create_grass_clump(parent, StylizedStartComposition.CHEST_POS + Vector3(-0.35, 0.0, -0.45), GrassVariant.SHORT, 0.88, 304, mats, mesh_fn)
	create_grass_clump(parent, StylizedStartComposition.CHEST_POS + Vector3(0.55, 0.0, 0.55), GrassVariant.MEDIUM, 0.82, 305, mats, mesh_fn)
	# Zone D — sign / ruin.
	create_grass_clump(parent, StylizedStartComposition.SIGN_POS + Vector3(-0.55, 0.0, -0.35), GrassVariant.EDGE, 0.9, 401, mats, mesh_fn)
	create_flower_cluster(parent, StylizedStartComposition.SIGN_POS + Vector3(0.45, 0.0, -0.25), FlowerPreset.WHITE_CLUSTER, 402, mats, mesh_fn)
	create_shrub(parent, StylizedStartComposition.CORNER_RUIN_POS + Vector3(0.7, 0.0, -0.5), 0.88, 403, mats, mesh_fn)
	create_vine_cluster(parent, StylizedStartComposition.CORNER_RUIN_POS + Vector3(-0.35, 0.55, 0.2), -18.0, 1.0, 404, mats, mesh_fn)
	# Zone E — cannon approach: sparse ground accents only.
	create_grass_clump(parent, Vector3(0.85, 0.0, -3.15), GrassVariant.SHORT, 0.8, 501, mats, mesh_fn)
	create_grass_clump(parent, Vector3(-0.45, 0.0, -3.55), GrassVariant.SHORT, 0.78, 502, mats, mesh_fn)
	# Zone F — pad / portal energy accents.
	create_flower_cluster(parent, StylizedStartComposition.PAD_POS + Vector3(-0.55, 0.0, 0.55), FlowerPreset.VIOLET_CLUSTER, 601, mats, mesh_fn)
	create_flower_cluster(parent, StylizedStartComposition.PAD_POS + Vector3(0.6, 0.0, -0.45), FlowerPreset.PINK_CLUSTER, 602, mats, mesh_fn)
	create_grass_clump(parent, StylizedStartComposition.PAD_POS + Vector3(0.45, 0.0, 0.65), GrassVariant.MEDIUM, 0.86, 603, mats, mesh_fn)
	# Landmark anchors.
	create_tree(parent, StylizedStartComposition.TREE_POS, TreeVariant.TREE_A, 1.05, 701, mats, mesh_fn)
	create_tree(parent, Vector3(5.2, 0.0, -0.8), TreeVariant.TREE_B, 0.82, 702, mats, mesh_fn)
	create_shrub(parent, StylizedStartComposition.CRYSTAL_POS + Vector3(0.55, 0.0, 0.35), 0.9, 703, mats, mesh_fn)
	create_flower_cluster(parent, StylizedStartComposition.CRYSTAL_POS + Vector3(-0.45, 0.0, 0.25), FlowerPreset.VIOLET_CLUSTER, 704, mats, mesh_fn)
	# Edge silhouettes.
	var edge_points: Array = [
		{"pos": Vector3(-4.2, 0.0, 2.8), "scale": 0.95, "flower": true},
		{"pos": Vector3(3.8, 0.0, 2.2), "scale": 0.9},
		{"pos": Vector3(-1.8, 0.0, -3.9), "scale": 1.0, "flower": true},
		{"pos": Vector3(-5.5, 0.0, -0.5), "scale": 0.88},
		{"pos": Vector3(4.8, 0.0, -2.2), "scale": 0.86},
	]
	create_edge_growth(parent, edge_points, mats, mesh_fn, 800)
	# Residual soft clusters from composition anchors.
	for i in range(StylizedStartComposition.FLOWER_CLUSTERS.size()):
		var preset: FlowerPreset = [FlowerPreset.PINK_CLUSTER, FlowerPreset.MIXED_SOFT_CLUSTER, FlowerPreset.WHITE_CLUSTER][i % 3]
		create_flower_cluster(parent, StylizedStartComposition.FLOWER_CLUSTERS[i], preset, 900 + i, mats, mesh_fn)
	for i in range(StylizedStartComposition.GRASS_CLUSTERS.size()):
		create_grass_clump(parent, StylizedStartComposition.GRASS_CLUSTERS[i], GrassVariant.MEDIUM, 0.94, 910 + i, mats, mesh_fn)


static func dress_hero_midground(parent: Node3D, mats: Dictionary, mesh_fn: Callable) -> void:
	create_tree(parent, Vector3(5.8, 0.0, 2.4), TreeVariant.TREE_B, 0.95, 1001, mats, mesh_fn)
	create_tree(parent, Vector3(-4.6, 0.0, 3.2), TreeVariant.TREE_C, 0.78, 1002, mats, mesh_fn)
	create_shrub(parent, Vector3(-0.5, 0.0, 5.2), 1.0, 1003, mats, mesh_fn)
	create_shrub(parent, Vector3(1.2, 0.0, 5.5), 0.92, 1004, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(-1.1, 0.0, 5.0), FlowerPreset.VIOLET_CLUSTER, 1005, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(3.8, 0.0, 4.3), FlowerPreset.PINK_CLUSTER, 1006, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(4.5, 0.0, 4.9), FlowerPreset.MIXED_SOFT_CLUSTER, 1007, mats, mesh_fn)
	create_vine_cluster(parent, Vector3(3.2, 0.65, 4.5), -12.0, 1.05, 1008, mats, mesh_fn)
	for i in range(4):
		var pos: Vector3 = [Vector3(2.2, 0.0, 3.4), Vector3(-3.8, 0.0, 3.0), Vector3(1.0, 0.0, 4.8), Vector3(-2.4, 0.0, 4.2)][i]
		create_grass_clump(parent, pos, GrassVariant.MEDIUM if i % 2 == 0 else GrassVariant.SHORT, 0.9, 1010 + i, mats, mesh_fn)


static func dress_playable_island(
	parent: Node3D,
	island_index: int,
	radius: float,
	mats: Dictionary,
	mesh_fn: Callable
) -> void:
	if island_index == 1:
		return
	var spread: float = radius * 0.42
	var tree_variant: TreeVariant = [TreeVariant.TREE_A, TreeVariant.TREE_B, TreeVariant.TREE_C][island_index % 3]
	create_tree(parent, Vector3(-spread, 0.0, 0.8), tree_variant, 0.82, 2000 + island_index, mats, mesh_fn)
	create_grass_clump(parent, Vector3(spread * 0.35, 0.0, 1.4), GrassVariant.MEDIUM, 0.85, 2010 + island_index, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(-spread * 0.4, 0.0, 1.8), FlowerPreset.MIXED_SOFT_CLUSTER, 2020 + island_index, mats, mesh_fn)
	if island_index >= 3:
		create_shrub(parent, Vector3(spread * 0.2, 0.0, 0.5), 0.8, 2030 + island_index, mats, mesh_fn)


static func dress_target_island(
	parent: Node3D,
	radius: float,
	island_index: int,
	mats: Dictionary,
	mesh_fn: Callable
) -> void:
	create_grass_clump(parent, Vector3(-radius * 0.2, 0.0, 1.6), GrassVariant.EDGE, 0.8, 3000 + island_index, mats, mesh_fn)
	create_flower_cluster(parent, Vector3(radius * 0.15, 0.0, 1.2), FlowerPreset.WHITE_CLUSTER, 3010 + island_index, mats, mesh_fn)
	if island_index % 2 == 0:
		create_shrub(parent, Vector3(-radius * 0.28, 0.0, 0.6), 0.75, 3020 + island_index, mats, mesh_fn)


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
