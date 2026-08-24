extends RefCounted
class_name StylizedHeroModels

const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")

## V21 — Stylized hero gameplay models (Godot-native ArrayMesh / primitives).


static func _mat(mats: Dictionary, key: String, fallback: String) -> Material:
	return StylizedTypedAccess.material(mats, key, fallback)


static func _face_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var n := (b - a).cross(c - a)
	return Vector3.UP if n.length_squared() < 0.000001 else n.normalized()


static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n := _face_normal(a, b, c)
	for v in [a, b, c]:
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(v)


static func _faceted_box(size: Vector3, shade: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var hx: float = size.x * 0.5
	var hy: float = size.y
	var hz: float = size.z * 0.5
	var j := func(v: Vector3) -> Vector3:
		return v + Vector3(rng.randf_range(-0.03, 0.03), rng.randf_range(0.0, 0.02), rng.randf_range(-0.03, 0.03))
	var top := [j.call(Vector3(-hx, hy, -hz)), j.call(Vector3(hx, hy, -hz)), j.call(Vector3(hx, hy, hz)), j.call(Vector3(-hx, hy, hz))]
	var bot := [j.call(Vector3(-hx, 0, -hz)), j.call(Vector3(hx, 0, -hz)), j.call(Vector3(hx, 0, hz)), j.call(Vector3(-hx, 0, hz))]
	var col := Color(shade, shade * 0.97, shade * 0.93, 1.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_tri(st, top[0], top[1], top[2], col * Color(1.04, 1.04, 1.02, 1.0))
	_add_tri(st, top[0], top[2], top[3], col * Color(1.04, 1.04, 1.02, 1.0))
	_add_tri(st, bot[2], bot[1], bot[0], col * Color(0.78, 0.76, 0.74, 1.0))
	_add_tri(st, bot[3], bot[2], bot[0], col * Color(0.78, 0.76, 0.74, 1.0))
	_add_tri(st, top[0], top[1], bot[1], col * Color(0.9, 0.88, 0.86, 1.0))
	_add_tri(st, top[0], bot[1], bot[0], col * Color(0.9, 0.88, 0.86, 1.0))
	_add_tri(st, top[1], top[2], bot[2], col * Color(0.84, 0.82, 0.8, 1.0))
	_add_tri(st, top[1], bot[2], bot[1], col * Color(0.84, 0.82, 0.8, 1.0))
	_add_tri(st, top[2], top[3], bot[3], col * Color(0.88, 0.86, 0.84, 1.0))
	_add_tri(st, top[2], bot[3], bot[2], col * Color(0.88, 0.86, 0.84, 1.0))
	_add_tri(st, top[3], top[0], bot[0], col * Color(0.82, 0.8, 0.78, 1.0))
	_add_tri(st, top[3], bot[0], bot[3], col * Color(0.82, 0.8, 0.78, 1.0))
	return st.commit()


static func _crystal_shard_mesh(scale: float, seed: int, blue: bool) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + seed
	var h: float = 0.9 * scale
	var w: float = 0.28 * scale
	var d: float = 0.22 * scale
	var tip := Vector3(rng.randf_range(-0.04, 0.04), h, rng.randf_range(-0.03, 0.03))
	var a := Vector3(-w, 0, -d)
	var b := Vector3(w * 0.8, 0, d * 0.6)
	var c := Vector3(-w * 0.4, 0, d)
	var shade: float = 0.92 if blue else 0.88
	var col := Color(shade * 0.7, shade * 0.65, shade, 1.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_tri(st, a, b, tip, col)
	_add_tri(st, b, c, tip, col)
	_add_tri(st, c, a, tip, col)
	_add_tri(st, a, c, b, col * Color(0.55, 0.52, 0.62, 1.0))
	return st.commit()


static func build_cannon_visual(
	root: Node3D,
	pivot: Node3D,
	mesh_fn: Callable,
	mats: Dictionary,
	_cannon_key: String
) -> MeshInstance3D:
	mesh_fn.call(root, _faceted_box(Vector3(2.05, 0.2, 2.05), 0.72, 101), _mat(mats, "portal_stone", "stone_dark"), Vector3(0, 0, 0))
	mesh_fn.call(root, _faceted_box(Vector3(1.55, 0.16, 1.55), 0.78, 102), _mat(mats, "portal_stone", "stone_main"), Vector3(0, 0.2, 0))
	var brass_plate: CylinderMesh = CylinderMesh.new()
	brass_plate.top_radius = 0.92
	brass_plate.bottom_radius = 1.02
	brass_plate.height = 0.12
	brass_plate.radial_segments = 10
	mesh_fn.call(root, brass_plate, _mat(mats, "brass_gold", "brass"), Vector3(0, 0.34, 0))
	for side in [-1.0, 1.0]:
		mesh_fn.call(
			root, _faceted_box(Vector3(0.22, 0.52, 0.38), 0.82, 110 + int(side)),
			_mat(mats, "brass_gold", "brass"), Vector3(side * 0.62, 0.48, -0.15), Vector3.ONE, Vector3(0, 0, side * 12.0)
		)
	var barrel: CylinderMesh = CylinderMesh.new()
	barrel.top_radius = 0.44
	barrel.bottom_radius = 0.62
	barrel.height = 2.85
	barrel.radial_segments = 14
	mesh_fn.call(pivot, barrel, _mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(0, 0, -1.35), Vector3.ONE, Vector3(90, 0, 0))
	var muzzle: CylinderMesh = CylinderMesh.new()
	muzzle.top_radius = 0.5
	muzzle.bottom_radius = 0.44
	muzzle.height = 0.28
	muzzle.radial_segments = 14
	mesh_fn.call(pivot, muzzle, _mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(0, 0, -2.78), Vector3.ONE, Vector3(90, 0, 0))
	var breech: CylinderMesh = CylinderMesh.new()
	breech.top_radius = 0.68
	breech.bottom_radius = 0.72
	breech.height = 0.42
	breech.radial_segments = 12
	mesh_fn.call(pivot, breech, _mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(0, 0, -0.18), Vector3.ONE, Vector3(90, 0, 0))
	for side in [-1.0, 1.0]:
		mesh_fn.call(
			pivot, _faceted_box(Vector3(0.26, 0.24, 0.34), 0.52, 116 + int(side)),
			_mat(mats, "cannon_dark_metal", "cannon_dark"), Vector3(side * 0.62, 0.06, -0.35)
		)
	for z in [-0.08, -1.05, -2.15]:
		var ring: TorusMesh = TorusMesh.new()
		ring.inner_radius = 0.54
		ring.outer_radius = 0.68
		ring.rings = 14
		ring.ring_segments = 8
		mesh_fn.call(pivot, ring, _mat(mats, "brass_gold", "brass"), Vector3(0, 0, z), Vector3.ONE, Vector3(90, 0, 0))
	var muzzle_ring: TorusMesh = TorusMesh.new()
	muzzle_ring.inner_radius = 0.5
	muzzle_ring.outer_radius = 0.7
	muzzle_ring.rings = 14
	muzzle_ring.ring_segments = 8
	mesh_fn.call(pivot, muzzle_ring, _mat(mats, "brass_gold", "brass"), Vector3(0, 0, -2.9), Vector3.ONE, Vector3(90, 0, 0))
	var emblem: BoxMesh = BoxMesh.new()
	emblem.size = Vector3(0.18, 0.22, 0.06)
	mesh_fn.call(pivot, emblem, _mat(mats, "brass_gold", "brass"), Vector3(0, 0.12, 0.52), Vector3.ONE, Vector3(-18, 0, 0))
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.32
	glow_mesh.height = 0.55
	glow_mesh.radial_segments = 12
	glow_mesh.rings = 6
	var glow: MeshInstance3D = mesh_fn.call(
		pivot, glow_mesh, _mat(mats, "portal_energy", "portal"), Vector3(0, 0, -2.88), Vector3(1.0, 0.24, 1.0)
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
	mesh_fn.call(chest, _faceted_box(Vector3(1.18, 0.58, 0.86), 0.68, 201), _mat(mats, "chest_wood", "wood"), Vector3(0, 0, 0))
	mesh_fn.call(chest, _faceted_box(Vector3(1.22, 0.24, 0.9), 0.72, 202), _mat(mats, "chest_wood", "wood_light"), Vector3(0, 0.62, -0.02), Vector3.ONE, Vector3(-14, 0, 0))
	for y in [0.22, 0.48, 0.66]:
		mesh_fn.call(chest, _faceted_box(Vector3(1.24, 0.1, 0.92), 0.95, 203 + int(y * 10)), _mat(mats, "chest_metal", "brass"), Vector3(0, y, 0))
	var lock: CylinderMesh = CylinderMesh.new()
	lock.top_radius = 0.14
	lock.bottom_radius = 0.16
	lock.height = 0.08
	lock.radial_segments = 10
	mesh_fn.call(chest, lock, _mat(mats, "chest_metal", "brass"), Vector3(0, 0.48, 0.48), Vector3.ONE, Vector3(90, 0, 0))
	return chest


static func build_gameplay_chest(root: Node3D, mesh_fn: Callable, mats: Dictionary) -> void:
	mesh_fn.call(root, _faceted_box(Vector3(1.42, 0.62, 1.02), 0.66, 211), _mat(mats, "chest_wood", "wood"), Vector3(0, 0, 0))
	for y in [0.18, 0.42]:
		mesh_fn.call(root, _faceted_box(Vector3(1.46, 0.1, 1.06), 0.94, 212 + int(y * 10)), _mat(mats, "chest_metal", "brass"), Vector3(0, y, 0))
	var lock: CylinderMesh = CylinderMesh.new()
	lock.top_radius = 0.16
	lock.bottom_radius = 0.18
	lock.height = 0.1
	lock.radial_segments = 10
	mesh_fn.call(root, lock, _mat(mats, "chest_metal", "brass"), Vector3(0, 0.42, 0.54), Vector3.ONE, Vector3(90, 0, 0))
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.62, 0.48)
	root.add_child(lid)
	mesh_fn.call(lid, _faceted_box(Vector3(1.44, 0.28, 1.04), 0.72, 213), _mat(mats, "chest_wood", "wood_light"), Vector3(0, 0.08, -0.02), Vector3.ONE, Vector3(-16, 0, 0))
	mesh_fn.call(lid, _faceted_box(Vector3(1.48, 0.1, 1.06), 0.95, 214), _mat(mats, "chest_metal", "brass"), Vector3(0, 0.2, 0))


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
	mesh_fn.call(root, _faceted_box(Vector3(2.35 * sv, 0.22 * sv, 2.35 * sv), 0.7, 501), _mat(mats, "portal_stone", "stone_dark"), Vector3(0, 0, 0))
	mesh_fn.call(root, _faceted_box(Vector3(1.85 * sv, 0.18 * sv, 1.85 * sv), 0.76, 502), _mat(mats, "portal_stone", "stone_main"), Vector3(0, 0.22 * sv, 0))
	for side in [-1.0, 1.0]:
		mesh_fn.call(
			root, _faceted_box(Vector3(0.42 * sv, 1.35 * sv, 0.38 * sv), 0.74, 510 + int(side)),
			_mat(mats, "portal_stone", "stone_dark"), Vector3(side * 1.05 * sv, 0.88 * sv, 0)
		)
	var frame: TorusMesh = TorusMesh.new()
	frame.inner_radius = 0.88 * sv
	frame.outer_radius = 1.18 * sv
	frame.rings = 18
	frame.ring_segments = 10
	mesh_fn.call(root, frame, _mat(mats, "portal_stone", "stone_warm"), Vector3(0, 1.72 * sv, 0), Vector3.ONE, Vector3(90, 0, 0))
	for i in range(8):
		var angle: float = float(i) * TAU / 8.0
		var seg_pos := Vector3(cos(angle) * 1.02 * sv, 1.72 * sv, sin(angle) * 1.02 * sv)
		mesh_fn.call(root, _faceted_box(Vector3(0.22 * sv, 0.28 * sv, 0.18 * sv), 0.8, 520 + i), _mat(mats, "portal_stone", "stone_main"), seg_pos, Vector3.ONE, Vector3(0, -rad_to_deg(angle), 0))
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
	build_crystal_cluster(root, Vector3(-0.95, 0.38, 0.42) * sv, 0.4 * sv, mats, mesh_fn, false, "small")
	build_crystal_cluster(root, Vector3(0.92, 0.34, -0.38) * sv, 0.36 * sv, mats, mesh_fn, true, "small")
	return root


static func build_pad(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, transparent_fn: Callable) -> void:
	mesh_fn.call(parent, _faceted_box(Vector3(1.65, 0.18, 1.65), 0.7, 301), _mat(mats, "pad_stone", "stone_dark"), pos + Vector3(0, 0, 0))
	mesh_fn.call(parent, _faceted_box(Vector3(1.42, 0.12, 1.42), 0.76, 302), _mat(mats, "pad_stone", "stone_main"), pos + Vector3(0, 0.18, 0))
	var rim: BoxMesh = BoxMesh.new()
	rim.size = Vector3(1.28, 0.08, 1.28)
	mesh_fn.call(parent, rim, _mat(mats, "portal_stone", "stone_dark"), pos + Vector3(0, 0.26, 0))
	var energy: CylinderMesh = CylinderMesh.new()
	energy.top_radius = 0.48
	energy.bottom_radius = 0.48
	energy.height = 0.05
	energy.radial_segments = 14
	mesh_fn.call(parent, energy, _mat(mats, "pad_energy", "portal"), pos + Vector3(0, 0.3, 0), Vector3.ONE, Vector3(90, 0, 0))
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var stud: CylinderMesh = CylinderMesh.new()
			stud.top_radius = 0.06
			stud.bottom_radius = 0.07
			stud.height = 0.08
			stud.radial_segments = 8
			mesh_fn.call(parent, stud, _mat(mats, "brass_gold", "brass"), pos + Vector3(x * 0.68, 0.32, z * 0.68))


static func build_signpost(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable) -> void:
	var sign := Node3D.new()
	sign.position = pos
	parent.add_child(sign)
	var post: CylinderMesh = CylinderMesh.new()
	post.top_radius = 0.07
	post.bottom_radius = 0.09
	post.height = 1.28
	post.radial_segments = 8
	mesh_fn.call(sign, post, _mat(mats, "sign_wood", "wood"), Vector3(0, 0.64, 0))
	mesh_fn.call(sign, _faceted_box(Vector3(0.95, 0.48, 0.1), 0.8, 401), _mat(mats, "sign_frame", "leaf_green"), Vector3(0.12, 1.12, 0), Vector3.ONE, Vector3(0, -18, 6))
	mesh_fn.call(sign, _faceted_box(Vector3(0.82, 0.36, 0.06), 0.85, 402), _mat(mats, "sign_wood", "wood_light"), Vector3(0.14, 1.14, 0.02), Vector3.ONE, Vector3(0, -18, 6))
	var arrow: PrismMesh = PrismMesh.new()
	arrow.size = Vector3(0.28, 0.2, 0.14)
	mesh_fn.call(sign, arrow, _mat(mats, "grass_light", "grass_light"), Vector3(0.46, 1.14, 0.06), Vector3.ONE, Vector3(0, 0, 90))


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
	for i in range(mini(count, offsets.size())):
		var mesh: ArrayMesh = _crystal_shard_mesh(scale_value * scales[i], i + (10 if blue else 0), blue)
		mesh_fn.call(
			parent, mesh, _mat(mats, mat_key, "crystal"),
			pos + offsets[i], Vector3.ONE,
			Vector3(rad_to_deg(0.12), float(i * 19), rad_to_deg(0.08 * float(i)))
		)


static func validate_mesh(mesh: ArrayMesh) -> bool:
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertex in vertices:
		if not vertex.is_finite():
			return false
	return true
