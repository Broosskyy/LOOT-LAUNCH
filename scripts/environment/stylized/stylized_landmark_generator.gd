extends RefCounted
class_name StylizedLandmarkGenerator

## V35 — Landmark compositions (towers, portal monuments, hero silhouettes, ruin courtyards).

const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const ArchGen = preload("res://scripts/environment/stylized/stylized_architecture_generator.gd")
const RuinsKit = preload("res://scripts/environment/stylized/stylized_ground_ruins_kit.gd")
const TypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")
const HeroModels = preload("res://scripts/environment/stylized/stylized_hero_models.gd")
const MegaTypes = preload("res://scripts/environment/stylized/mega_island_types.gd")

enum TowerKind { SMALL_TOWER, BROKEN_TOWER, HERO_TOWER, WATCHTOWER }


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 35107 + seed * 613
	return rng


static func _stone(mats: Dictionary, tone: String = "ruin") -> Material:
	return RuinsKit._stone_material(mats, tone)


static func _detail(quality: int) -> int:
	return 2 if quality >= 2 else 1


static func build_tower(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	kind: int,
	damage: int,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "Tower"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	var detail: int = _detail(quality)
	var rng := _rng(seed)
	var broken: bool = kind == TowerKind.BROKEN_TOWER or damage >= ArchGen.DamageLevel.BROKEN
	var base_r: float = 0.52
	var top_r: float = 0.34
	var height: float = 2.8
	match kind:
		TowerKind.SMALL_TOWER:
			height = 2.2
			base_r = 0.42
			top_r = 0.3
		TowerKind.WATCHTOWER:
			height = 3.1
			base_r = 0.48
			top_r = 0.32
		TowerKind.HERO_TOWER:
			height = 4.2
			base_r = 0.62
			top_r = 0.28
	if broken:
		height *= 0.78
	# Base plinth.
	var plinth := Toolkit.octagonal_plinth(base_r * 1.15, base_r * 0.82, 0.38, seed, detail)
	mesh_fn.call(root, plinth, _stone(mats, "dark"))
	# Main shaft — tapered sections.
	var lower := Toolkit.tapered_pillar(Toolkit.PillarKind.FULL_PILLAR, base_r, base_r * 0.82, height * 0.45, 6, seed + 1, false, detail)
	mesh_fn.call(root, lower, _stone(mats, "main"), Vector3(0.0, 0.38, 0.0))
	var upper := Toolkit.tapered_pillar(
		Toolkit.PillarKind.BROKEN_PILLAR if broken else Toolkit.PillarKind.FULL_PILLAR,
		base_r * 0.78, top_r, height * 0.42, 6, seed + 2, broken, detail
	)
	mesh_fn.call(root, upper, _stone(mats, "warm"), Vector3(rng.randf_range(-0.04, 0.04), 0.38 + height * 0.45, rng.randf_range(-0.03, 0.03)))
	# Mid band ledge.
	var band := Toolkit.beveled_box(Vector3(base_r * 1.7, 0.16, base_r * 1.5), 0.05, seed + 3, 0.84, 0.04, 0.0, 0.05, 1, detail)
	mesh_fn.call(root, band, _stone(mats, "light"), Vector3(0.0, 0.38 + height * 0.42, 0.0))
	if not broken:
		var cap_kind: int = Toolkit.RoofKind.TAPERED_TOWER_CAP if kind == TowerKind.HERO_TOWER else Toolkit.RoofKind.PYRAMIDAL_CAP
		var cap := Toolkit.roof_cap(cap_kind, top_r * 1.8, top_r * 1.6, 0.42, 0.06, seed + 4, 0.06, detail)
		mesh_fn.call(root, cap, _stone(mats, "dark"), Vector3(0.0, 0.38 + height * 0.88, 0.0))
	# Banner mast hook on hero/watchtower.
	if kind in [TowerKind.HERO_TOWER, TowerKind.WATCHTOWER]:
		mesh_fn.call(root, MeshLib.tapered_trunk(1.2, 0.035, 0.025, seed + 5, 5), TypedAccess.material(mats, "wood_dark", "wood_dark"), Vector3(base_r * 0.35, 0.38 + height * 0.82, -0.15), Vector3.ONE, Vector3(0, 12, 0))
		mesh_fn.call(root, MeshLib.beveled_box(Vector3(0.38, 0.22, 0.04), 0.02, seed + 6, 0.7), TypedAccess.material(mats, "flower_violet", "flower_violet"), Vector3(base_r * 0.35, 0.38 + height * 0.95, -0.15), Vector3.ONE, Vector3(0, 12, -8))
	# Side buttress.
	if kind == TowerKind.HERO_TOWER:
		var buttress := Toolkit.beveled_box(Vector3(0.35, height * 0.55, 0.42), 0.05, seed + 7, 0.8, 0.0, 0.0, 0.06, 1, detail)
		mesh_fn.call(root, buttress, _stone(mats, "dark"), Vector3(base_r * 0.72, 0.38, 0.18), Vector3.ONE, Vector3(0, -18, 0))
	if broken:
		RuinsKit.add_rubble_cluster(root, Vector3(0.4, 0.0, 0.5), mats, mesh_fn, seed + 8, 3)
	ArchGen._set_veg_hook(root, Vector3(-0.5, 0.2, 0.6))
	return root


static func build_lookout_ruin(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "LookoutRuin"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	build_tower(root, Vector3.ZERO, 0.0, TowerKind.BROKEN_TOWER, ArchGen.DamageLevel.BROKEN, seed, mats, mesh_fn, quality)
	ArchGen.build_archway(root, Vector3(0.8, 0.0, 0.6), -12.0, 1.8, 1.2, true, seed + 10, mats, mesh_fn, quality)
	ArchGen.build_stair_run(root, Vector3(-0.6, 0.0, -0.4), 8.0, 3, true, seed + 11, mats, mesh_fn, quality)
	ArchGen.build_wall(root, Vector3(-1.2, 0.0, 0.8), 20.0, 2.0, 0.9, ArchGen.WallKind.BROKEN_WALL, ArchGen.DamageLevel.HEAVY_RUIN, seed + 12, mats, mesh_fn, quality)
	return root


static func build_ruin_courtyard(
	parent: Node3D,
	pos: Vector3,
	rot_y: float,
	seed: int,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "RuinCourtyard"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	# Stone floor plinth.
	var floor := Toolkit.octagonal_plinth(2.4, 1.6, 0.12, seed, _detail(quality))
	mesh_fn.call(root, floor, _stone(mats, "path"), Vector3.ZERO)
	ArchGen.build_wall(root, Vector3(-1.4, 0.0, 0.0), 90.0, 2.8, 1.15, ArchGen.WallKind.BROKEN_WALL, ArchGen.DamageLevel.BROKEN, seed + 20, mats, mesh_fn, quality)
	ArchGen.build_wall(root, Vector3(0.0, 0.0, 1.2), 0.0, 2.4, 1.0, ArchGen.WallKind.FULL_WALL, ArchGen.DamageLevel.LIGHT_RUIN, seed + 21, mats, mesh_fn, quality)
	ArchGen.build_archway(root, Vector3(1.1, 0.0, -0.2), -90.0, 2.0, 1.35, true, seed + 22, mats, mesh_fn, quality)
	ArchGen.build_pillar_cluster(root, Vector3(-0.5, 0.0, -0.8), 0.0, 2, true, seed + 23, mats, mesh_fn, quality)
	build_tower(root, Vector3(0.6, 0.0, 0.9), -24.0, TowerKind.WATCHTOWER, ArchGen.DamageLevel.LIGHT_RUIN, seed + 24, mats, mesh_fn, quality)
	RuinsKit.add_rubble_cluster(root, Vector3(0.0, 0.0, 0.4), mats, mesh_fn, seed + 25, 5)
	return root


static func build_portal_monument_site(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array,
	scale_value: float,
	seed: int,
	quality: int = 2
) -> Node3D:
	var root := Node3D.new()
	root.name = "PortalMonument"
	parent.add_child(root)
	var sv: float = scale_value
	var detail: int = _detail(quality)
	# Raised platform with stairs.
	for layer in range(4):
		var shrink: float = 1.0 - float(layer) * 0.12
		var step := Toolkit.beveled_box(Vector3(2.6 * sv * shrink, 0.14 * sv, 2.6 * sv * shrink), 0.07 * sv, seed + layer, 0.72 + float(layer) * 0.04, 0.0, 0.0, 0.04, 1, detail)
		mesh_fn.call(root, step, _stone(mats, "portal_stone" if layer < 2 else "ruin"), Vector3(0.0, float(layer) * 0.14 * sv, 0.0))
	ArchGen.build_stair_run(root, Vector3(0.0, 0.0, 1.35 * sv), 180.0, 3, false, seed + 10, mats, mesh_fn, quality)
	# Vertical supports + segmented frame.
	for side in [-1.0, 1.0]:
		var pillar := Toolkit.tapered_pillar(Toolkit.PillarKind.FULL_PILLAR, 0.18 * sv, 0.24 * sv, 1.55 * sv, 8, seed + int(side * 30), false, detail)
		mesh_fn.call(root, pillar, _stone(mats, "portal_stone"), Vector3(side * 1.12 * sv, 0.56 * sv, 0.0))
		var capital := Toolkit.beveled_box(Vector3(0.52 * sv, 0.2 * sv, 0.44 * sv), 0.05 * sv, seed + int(side * 31), 0.82, 0.05, 0.0, 0.05, 1, detail)
		mesh_fn.call(root, capital, _stone(mats, "warm"), Vector3(side * 1.12 * sv, 1.72 * sv, 0.0))
	var frame := Toolkit.segmented_ring(0.88 * sv, 1.12 * sv, 0.28 * sv, 12, seed + 40, 0.05, detail)
	mesh_fn.call(root, frame, _stone(mats, "ruin"), Vector3(0.0, 1.72 * sv, -0.04))
	# Side broken wall accents.
	ArchGen.build_wall(root, Vector3(-1.5 * sv, 0.0, -0.6 * sv), 24.0, 1.6 * sv, 0.85 * sv, ArchGen.WallKind.BROKEN_WALL, ArchGen.DamageLevel.BROKEN, seed + 50, mats, mesh_fn, quality)
	ArchGen.build_wall(root, Vector3(1.5 * sv, 0.0, -0.6 * sv), -24.0, 1.4 * sv, 0.75 * sv, ArchGen.WallKind.LOW_WALL, ArchGen.DamageLevel.LIGHT_RUIN, seed + 51, mats, mesh_fn, quality)
	# Portal energy (gameplay hooks preserved via HeroModels).
	var energy_root := Node3D.new()
	energy_root.position = Vector3(0.0, 1.72 * sv, 0.0)
	root.add_child(energy_root)
	_add_portal_energy(energy_root, sv, mats, mesh_fn, transparent_fn, animated_nodes)
	HeroModels.build_crystal_cluster(root, Vector3(-1.0 * sv, 0.42 * sv, 0.45 * sv), 0.42 * sv, mats, mesh_fn, false, "small")
	HeroModels.build_crystal_cluster(root, Vector3(0.95 * sv, 0.38 * sv, -0.4 * sv), 0.38 * sv, mats, mesh_fn, true, "small")
	return root


static func _add_portal_energy(
	parent: Node3D,
	sv: float,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array
) -> void:
	var inner: TorusMesh = TorusMesh.new()
	inner.inner_radius = 0.68 * sv
	inner.outer_radius = 0.82 * sv
	inner.rings = 16
	inner.ring_segments = 8
	var inner_ring: MeshInstance3D = mesh_fn.call(
		parent, inner, TypedAccess.material(mats, "portal_energy", "portal"), Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0)
	) as MeshInstance3D
	inner_ring.set_meta("animate_portal", true)
	inner_ring.set_meta("portal_counter", true)
	inner_ring.set_meta("pulse_phase", 0.0)
	animated_nodes.append(inner_ring)
	var energy: TorusMesh = TorusMesh.new()
	energy.inner_radius = 0.52 * sv
	energy.outer_radius = 0.62 * sv
	var energy_ring: MeshInstance3D = mesh_fn.call(
		parent, energy, TypedAccess.material(mats, "crystal_violet", "crystal"), Vector3(0.0, 0.0, 0.02), Vector3.ONE, Vector3(90, 0, 0)
	) as MeshInstance3D
	energy_ring.set_meta("animate_portal", true)
	energy_ring.set_meta("pulse_phase", 1.7)
	animated_nodes.append(energy_ring)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.66 * sv
	disc.bottom_radius = 0.66 * sv
	disc.height = 0.05
	disc.radial_segments = 18
	var portal_disc_mat: Material
	if transparent_fn.is_valid():
		portal_disc_mat = TypedAccess.transparent_material(transparent_fn, Color(0.55, 0.28, 0.95, 0.28))
	else:
		portal_disc_mat = TypedAccess.material(mats, "portal_energy", "portal")
	mesh_fn.call(parent, disc, portal_disc_mat, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))


static func build_hero_landmark(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	quality: int = 2,
	seed: int = 8800
) -> Node3D:
	var root := Node3D.new()
	root.name = "HeroLandmark"
	parent.add_child(root)
	var detail: int = _detail(quality)
	# Elevated base platform.
	var base := Toolkit.beveled_box(Vector3(4.2, 0.35, 3.6), 0.08, seed, 0.76, 0.0, 0.0, 0.05, 1, detail)
	mesh_fn.call(root, base, _stone(mats, "dark"), Vector3(-0.2, 0.0, 0.1))
	# Main hero tower.
	build_tower(root, Vector3(-0.5, 0.35, 0.0), 0.0, TowerKind.HERO_TOWER, ArchGen.DamageLevel.LIGHT_RUIN, seed + 1, mats, mesh_fn, quality)
	# Secondary broken side tower.
	build_tower(root, Vector3(1.35, 0.35, -0.45), -28.0, TowerKind.BROKEN_TOWER, ArchGen.DamageLevel.HEAVY_RUIN, seed + 2, mats, mesh_fn, quality)
	# Gate arch approach.
	ArchGen.build_gate(root, Vector3(-0.3, 0.35, 1.1), 180.0, seed + 3, mats, mesh_fn, quality)
	# Ruin wall mass.
	ArchGen.build_wall(root, Vector3(-1.8, 0.35, 0.4), 70.0, 2.6, 1.2, ArchGen.WallKind.BROKEN_WALL, ArchGen.DamageLevel.HEAVY_RUIN, seed + 4, mats, mesh_fn, quality)
	ArchGen.build_archway(root, Vector3(0.9, 0.35, -0.5), -8.0, 1.6, 1.1, true, seed + 5, mats, mesh_fn, quality)
	RuinsKit.add_rubble_cluster(root, Vector3(0.2, 0.35, 0.8), mats, mesh_fn, seed + 6, 4)
	return root


static func build_mega_architecture_cluster(
	parent: Node3D,
	recipe: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array,
	quality: int,
	seed: int
) -> Dictionary:
	var built: Dictionary = {"gate": false, "courtyard": false, "portal": false, "tower": false}
	for zone in recipe.get("zones", []):
		var ztype: int = int(zone.get("type", -1))
		var center: Vector3 = zone.get("center", Vector3.ZERO)
		match ztype:
			MegaTypes.ZoneType.LANDMARK_ZONE:
				build_ruin_courtyard(parent, center, -18.0, seed + 100, mats, mesh_fn, quality)
				build_tower(parent, center + Vector3(1.2, 0.0, -1.0), 14.0, TowerKind.WATCHTOWER, ArchGen.DamageLevel.LIGHT_RUIN, seed + 101, mats, mesh_fn, quality)
				built.courtyard = true
				built.tower = true
			MegaTypes.ZoneType.PORTAL_ZONE:
				var portal_root := Node3D.new()
				portal_root.position = center
				portal_root.rotation_degrees.y = 12.0
				parent.add_child(portal_root)
				build_portal_monument_site(portal_root, mats, mesh_fn, transparent_fn, animated_nodes, 0.95, seed + 200, quality)
				built.portal = true
	# Gate near bridge approach.
	var bridge: Dictionary = recipe.get("bridge", {})
	if bridge.has("start"):
		var gate_pos: Vector3 = bridge["start"] + Vector3(0.0, 0.0, 1.8)
		ArchGen.build_gate(parent, gate_pos, 8.0, seed + 300, mats, mesh_fn, quality)
		built.gate = true
	return built
