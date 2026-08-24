extends RefCounted
class_name StylizedHeroModels

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")
const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")

## V27 — Stylized hero gameplay models (Godot-native ArrayMesh, improved silhouettes).


static func _mat(mats: Dictionary, key: String, fallback: String) -> Material:
	return StylizedTypedAccess.material(mats, key, fallback)


static func _faceted_box(size: Vector3, shade: float, seed: int) -> ArrayMesh:
	return MeshLib.beveled_box(size, minf(size.x, size.z) * 0.08, seed, shade)


static func _crystal_shard_mesh(scale: float, seed: int, _blue: bool) -> ArrayMesh:
	var tier_scale: float = scale
	var height: float = [0.55, 0.85, 1.15][mini(seed % 3, 2)] * tier_scale
	var base_r: float = [0.14, 0.2, 0.26][mini(seed % 3, 2)] * tier_scale
	return MeshLib.faceted_crystal(height, base_r, seed)


static func build_cannon_visual(
	root: Node3D,
	pivot: Node3D,
	mesh_fn: Callable,
	mats: Dictionary,
	_cannon_key: String
) -> MeshInstance3D:
	# Layered octagonal base + stone plinth.
	mesh_fn.call(root, MeshLib.octagonal_plinth(1.18, 0.88, 0.36, 101), _mat(mats, "portal_stone", "stone_dark"), Vector3(0, 0, 0))
	mesh_fn.call(root, MeshLib.beveled_box(Vector3(1.72, 0.14, 1.72), 0.1, 102, 0.76), _mat(mats, "portal_stone", "stone_main"), Vector3(0, 0.36, 0))
	mesh_fn.call(root, MeshLib.ring_band(0.72, 0.98, 0.1, 10, 103), _mat(mats, "brass_gold", "brass"), Vector3(0, 0.42, 0))
	# Cradle supports with pivot hubs.
	for side in [-1.0, 1.0]:
		mesh_fn.call(
			root, MeshLib.beveled_box(Vector3(0.18, 0.58, 0.42), 0.04, 110 + int(side), 0.84),
			_mat(mats, "brass_gold", "brass"), Vector3(side * 0.68, 0.52, -0.12), Vector3.ONE, Vector3(0, 0, side * 14.0)
		)
		mesh_fn.call(
			root, MeshLib.tapered_cylinder(0.1, 0.12, 0.14, 8, 112 + int(side)),
			_mat(mats, "brass_gold", "brass"), Vector3(side * 0.68, 0.52, -0.12)
		)
	# Barrel assembly on AimPivot (tapered faceted barrel + chamber + muzzle flare).
	var barrel_mesh: ArrayMesh = MeshLib.tapered_cylinder(0.42, 0.58, 2.65, 12, 120)
	mesh_fn.call(pivot, barrel_mesh, _mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(0, 0, -1.42), Vector3.ONE, Vector3(90, 0, 0))
	mesh_fn.call(pivot, MeshLib.tapered_cylinder(0.48, 0.42, 0.32, 10, 121), _mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(0, 0, -2.82), Vector3.ONE, Vector3(90, 0, 0))
	mesh_fn.call(pivot, MeshLib.tapered_cylinder(0.62, 0.68, 0.38, 10, 122), _mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(0, 0, -0.12), Vector3.ONE, Vector3(90, 0, 0))
	for side in [-1.0, 1.0]:
		mesh_fn.call(
			pivot, MeshLib.beveled_box(Vector3(0.22, 0.22, 0.36), 0.03, 126 + int(side), 0.54),
			_mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(side * 0.58, 0.04, -0.42)
		)
	# Brass reinforcement rings (combined faceted bands).
	for z in [-0.05, -1.08, -2.18]:
		mesh_fn.call(pivot, MeshLib.ring_band(0.5, 0.66, 0.12, 12, int(z * -100.0)), _mat(mats, "brass_gold", "brass"), Vector3(0, 0, z), Vector3.ONE, Vector3(90, 0, 0))
	mesh_fn.call(pivot, MeshLib.ring_band(0.46, 0.68, 0.14, 12, 130), _mat(mats, "brass_gold", "brass"), Vector3(0, 0, -2.88), Vector3.ONE, Vector3(90, 0, 0))
	# Bolts + emblem plate.
	for i in range(6):
		var angle: float = float(i) * TAU / 6.0
		mesh_fn.call(
			pivot, MeshLib.tapered_cylinder(0.04, 0.05, 0.06, 6, 140 + i),
			_mat(mats, "brass_gold", "brass"), Vector3(cos(angle) * 0.58, sin(angle) * 0.12, 0.38)
		)
	mesh_fn.call(pivot, MeshLib.beveled_box(Vector3(0.2, 0.24, 0.05), 0.02, 148, 0.92), _mat(mats, "brass_gold", "brass"), Vector3(0, 0.1, 0.5), Vector3.ONE, Vector3(-16, 0, 0))
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.3
	glow_mesh.height = 0.5
	glow_mesh.radial_segments = 10
	glow_mesh.rings = 5
	var glow: MeshInstance3D = mesh_fn.call(
		pivot, glow_mesh, _mat(mats, "portal_energy", "portal"), Vector3(0, 0, -2.86), Vector3(1.0, 0.22, 1.0)
	) as MeshInstance3D
	glow.name = "MuzzleGlow"
	return glow


static func add_cannon_collision(root: Node3D) -> void:
	if root.get_node_or_null("CannonCollider") != null:
		return
	var body := StaticBody3D.new()
	body.name = "CannonCollider"
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.05
	shape.height = 0.55
	col.shape = shape
	col.position = Vector3(0, 0.28, 0)
	body.add_child(col)
	root.add_child(body)


static func build_chest(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> Node3D:
	var chest := Node3D.new()
	chest.position = pos
	parent.add_child(chest)
	mesh_fn.call(chest, MeshLib.beveled_box(Vector3(1.22, 0.52, 0.88), 0.08, 201, 0.68), _mat(mats, "chest_wood", "wood"), Vector3(0, 0, 0))
	for y in [0.08, 0.28]:
		mesh_fn.call(chest, MeshLib.beveled_box(Vector3(1.26, 0.08, 0.92), 0.03, 203 + int(y * 10), 0.94), _mat(mats, "chest_metal", "brass"), Vector3(0, y, 0))
	mesh_fn.call(chest, MeshLib.beveled_box(Vector3(0.28, 0.22, 0.06), 0.02, 205, 0.9), _mat(mats, "chest_metal", "brass"), Vector3(0, 0.38, 0.46))
	for side in [-1.0, 1.0]:
		mesh_fn.call(chest, MeshLib.beveled_box(Vector3(0.08, 0.12, 0.22), 0.02, 206 + int(side), 0.88), _mat(mats, "chest_metal", "brass"), Vector3(side * 0.58, 0.22, 0))
	mesh_fn.call(chest, MeshLib.curved_lid(1.2, 0.86, 0.32, 207), _mat(mats, "chest_wood", "wood_light"), Vector3(0, 0.52, -0.02), Vector3.ONE, Vector3(-12, 0, 0))
	mesh_fn.call(chest, MeshLib.beveled_box(Vector3(1.24, 0.08, 0.9), 0.03, 208, 0.95), _mat(mats, "chest_metal", "brass"), Vector3(0, 0.62, 0))
	for x in [-0.42, 0.42]:
		mesh_fn.call(chest, MeshLib.beveled_box(Vector3(0.1, 0.08, 0.12), 0.02, 209 + int(x * 10), 0.72), _mat(mats, "chest_wood", "wood_dark"), Vector3(x, 0.04, 0.38))
	return chest


static func build_gameplay_chest(root: Node3D, mesh_fn: Callable, mats: Dictionary) -> void:
	mesh_fn.call(root, MeshLib.beveled_box(Vector3(1.42, 0.58, 1.02), 0.09, 211, 0.66), _mat(mats, "chest_wood", "wood"), Vector3(0, 0, 0))
	for y in [0.16, 0.38]:
		mesh_fn.call(root, MeshLib.beveled_box(Vector3(1.46, 0.1, 1.06), 0.03, 212 + int(y * 10), 0.94), _mat(mats, "chest_metal", "brass"), Vector3(0, y, 0))
	mesh_fn.call(root, MeshLib.beveled_box(Vector3(0.32, 0.24, 0.07), 0.02, 215, 0.9), _mat(mats, "chest_metal", "brass"), Vector3(0, 0.4, 0.54))
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.58, 0.48)
	root.add_child(lid)
	mesh_fn.call(lid, MeshLib.curved_lid(1.4, 1.0, 0.34, 213), _mat(mats, "chest_wood", "wood_light"), Vector3(0, 0.06, -0.02), Vector3.ONE, Vector3(-14, 0, 0))
	mesh_fn.call(lid, MeshLib.beveled_box(Vector3(1.48, 0.1, 1.06), 0.03, 214, 0.95), _mat(mats, "chest_metal", "brass"), Vector3(0, 0.18, 0))


static func build_portal_monument(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array,
	scale_value: float
) -> Node3D:
	var root: Node3D = Node3D.new()
	parent.add_child(root)
	var sv: float = scale_value
	# Layered stone steps.
	for layer in range(3):
		var shrink: float = 1.0 - float(layer) * 0.14
		mesh_fn.call(
			root, MeshLib.beveled_box(Vector3(2.4 * sv * shrink, 0.16 * sv, 2.4 * sv * shrink), 0.08 * sv, 501 + layer, 0.72 + float(layer) * 0.04),
			_mat(mats, "portal_stone", "stone_dark" if layer == 0 else "stone_main"), Vector3(0, float(layer) * 0.16 * sv, 0)
		)
	# Side pillars with segmented capitals.
	for side in [-1.0, 1.0]:
		mesh_fn.call(
			root, MeshLib.tapered_cylinder(0.16 * sv, 0.22 * sv, 1.42 * sv, 8, 510 + int(side)),
			_mat(mats, "portal_stone", "stone_dark"), Vector3(side * 1.08 * sv, 0.48 * sv, 0)
		)
		mesh_fn.call(
			root, MeshLib.beveled_box(Vector3(0.48 * sv, 0.22 * sv, 0.42 * sv), 0.05 * sv, 512 + int(side), 0.8),
			_mat(mats, "portal_stone", "stone_warm"), Vector3(side * 1.08 * sv, 1.62 * sv, 0)
		)
	# Segmented stone arch ring (faceted torus segments).
	var segments: int = 10
	for i in range(segments):
		var angle: float = float(i) * TAU / float(segments)
		var next_angle: float = float(i + 1) * TAU / float(segments)
		var mid_angle: float = (angle + next_angle) * 0.5
		var seg_pos := Vector3(cos(mid_angle) * 1.05 * sv, 1.72 * sv, sin(mid_angle) * 1.05 * sv)
		mesh_fn.call(
			root, MeshLib.beveled_box(Vector3(0.28 * sv, 0.32 * sv, 0.22 * sv), 0.04 * sv, 520 + i, 0.82),
			_mat(mats, "portal_stone", "stone_main"), seg_pos, Vector3.ONE, Vector3(0, -rad_to_deg(mid_angle), 0)
		)
	# Inner energy rings (gameplay hooks preserved).
	var inner: TorusMesh = TorusMesh.new()
	inner.inner_radius = 0.68 * sv
	inner.outer_radius = 0.82 * sv
	inner.rings = 16
	inner.ring_segments = 8
	var inner_ring: MeshInstance3D = mesh_fn.call(
		root, inner, _mat(mats, "portal_energy", "portal"), Vector3(0, 1.72 * sv, -0.04), Vector3.ONE, Vector3(90, 0, 0)
	) as MeshInstance3D
	inner_ring.set_meta("animate_portal", true)
	animated_nodes.append(inner_ring)
	var energy: TorusMesh = TorusMesh.new()
	energy.inner_radius = 0.52 * sv
	energy.outer_radius = 0.62 * sv
	energy.rings = 14
	energy.ring_segments = 8
	var energy_ring: MeshInstance3D = mesh_fn.call(
		root, energy, _mat(mats, "crystal_violet", "crystal"), Vector3(0, 1.72 * sv, 0.02), Vector3.ONE, Vector3(90, 0, 0)
	) as MeshInstance3D
	energy_ring.set_meta("animate_portal", true)
	animated_nodes.append(energy_ring)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.66 * sv
	disc.bottom_radius = 0.66 * sv
	disc.height = 0.05
	disc.radial_segments = 18
	var portal_disc_mat: Material = StylizedTypedAccess.transparent_material(transparent_fn, Color(0.55, 0.28, 0.95, 0.28))
	mesh_fn.call(root, disc, portal_disc_mat, Vector3(0, 1.72 * sv, 0), Vector3.ONE, Vector3(90, 0, 0))
	# Accent crystals + braces.
	build_crystal_cluster(root, Vector3(-0.95, 0.38, 0.42) * sv, 0.42 * sv, mats, mesh_fn, false, "small")
	build_crystal_cluster(root, Vector3(0.92, 0.34, -0.38) * sv, 0.38 * sv, mats, mesh_fn, true, "small")
	for i in range(4):
		var a: float = float(i) * TAU / 4.0 + 0.4
		mesh_fn.call(
			root, MeshLib.beveled_box(Vector3(0.14 * sv, 0.08 * sv, 0.1 * sv), 0.02 * sv, 540 + i, 0.78),
			_mat(mats, "brass_gold", "brass"), Vector3(cos(a) * 0.82 * sv, 1.1 * sv, sin(a) * 0.82 * sv), Vector3.ONE, Vector3(0, -rad_to_deg(a), 18)
		)
	return root


static func build_pad(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, _transparent_fn: Callable) -> void:
	mesh_fn.call(parent, MeshLib.beveled_box(Vector3(1.75, 0.16, 1.75), 0.1, 301, 0.7), _mat(mats, "pad_stone", "stone_dark"), pos)
	mesh_fn.call(parent, MeshLib.beveled_box(Vector3(1.48, 0.1, 1.48), 0.08, 302, 0.76), _mat(mats, "pad_stone", "stone_main"), pos + Vector3(0, 0.16, 0))
	mesh_fn.call(parent, MeshLib.beveled_box(Vector3(1.22, 0.08, 1.22), 0.06, 303, 0.72), _mat(mats, "portal_stone", "stone_dark"), pos + Vector3(0, 0.24, 0))
	mesh_fn.call(parent, MeshLib.ring_band(0.38, 0.54, 0.06, 12, 304), _mat(mats, "brass_gold", "brass"), pos + Vector3(0, 0.3, 0))
	var energy: CylinderMesh = CylinderMesh.new()
	energy.top_radius = 0.34
	energy.bottom_radius = 0.38
	energy.height = 0.06
	energy.radial_segments = 12
	mesh_fn.call(parent, energy, _mat(mats, "pad_energy", "portal"), pos + Vector3(0, 0.32, 0), Vector3.ONE, Vector3(90, 0, 0))
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			mesh_fn.call(
				parent, MeshLib.beveled_box(Vector3(0.14, 0.1, 0.14), 0.02, 310 + int(x * 10 + z), 0.8),
				_mat(mats, "portal_stone", "stone_warm"), pos + Vector3(x * 0.72, 0.08, z * 0.72)
			)


static func build_signpost(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> void:
	var sign := Node3D.new()
	sign.position = pos
	parent.add_child(sign)
	mesh_fn.call(sign, MeshLib.tapered_trunk(1.32, 0.1, 0.07, 401, 7), _mat(mats, "sign_wood", "wood"), Vector3(0, 0, 0))
	mesh_fn.call(sign, MeshLib.beveled_box(Vector3(0.12, 0.14, 0.12), 0.02, 402, 0.74), _mat(mats, "sign_wood", "wood_dark"), Vector3(0.08, 0.92, 0.04), Vector3.ONE, Vector3(-12, 18, 0))
	mesh_fn.call(sign, MeshLib.beveled_box(Vector3(1.02, 0.52, 0.1), 0.05, 403), _mat(mats, "sign_frame", "wood_dark"), Vector3(0.14, 1.18, 0), Vector3.ONE, Vector3(0, -16, 5))
	mesh_fn.call(sign, MeshLib.beveled_box(Vector3(0.88, 0.38, 0.06), 0.04, 404, 0.86), _mat(mats, "sign_wood", "wood_light"), Vector3(0.16, 1.2, 0.03), Vector3.ONE, Vector3(0, -16, 5))
	var arrow: PrismMesh = PrismMesh.new()
	arrow.size = Vector3(0.32, 0.22, 0.16)
	mesh_fn.call(sign, arrow, _mat(mats, "grass_light", "grass_light"), Vector3(0.5, 1.2, 0.07), Vector3.ONE, Vector3(0, 0, 90))


static func build_crystal_cluster(
	parent: Node3D,
	pos: Vector3,
	scale_value: float,
	mats: Dictionary,
	mesh_fn: Callable,
	blue: bool = false,
	size_tier: String = "medium"
) -> void:
	var count: int = 3 if size_tier == "small" else 5 if size_tier == "medium" else 6
	var mat_key: String = "crystal_blue" if blue else "crystal_violet"
	var offsets: Array[Vector3] = [
		Vector3(-0.24, 0, 0), Vector3(0.2, 0.06, 0.05), Vector3(0, -0.02, 0.22),
		Vector3(-0.1, 0.04, -0.14), Vector3(0.12, 0.02, -0.08), Vector3(-0.05, 0.08, 0.1),
	]
	var scales: Array[float] = [1.0, 0.82, 0.68, 0.9, 0.74, 0.58]
	var heights: Array[float] = [0.55, 0.85, 0.7, 1.0, 0.62, 0.48]
	for i in range(mini(count, offsets.size())):
		var mesh: ArrayMesh = MeshLib.faceted_crystal(heights[i] * scale_value * scales[i], 0.18 * scale_value, i + (10 if blue else 0))
		mesh_fn.call(
			parent, mesh, _mat(mats, mat_key, "crystal"),
			pos + offsets[i], Vector3.ONE,
			Vector3(rad_to_deg(0.12), float(i * 19), rad_to_deg(0.08 * float(i)))
		)


static func validate_mesh(mesh: ArrayMesh) -> bool:
	return MeshLib.validate_mesh(mesh).errors.is_empty()
