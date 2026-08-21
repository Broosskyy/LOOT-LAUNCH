extends Node3D

## Preview-only Wolkengarten dressing — no gameplay coupling.

const SOURCE_RADIUS := 12.8
const FLOOR_OFFSET := 0.84

var _mats: Dictionary = {}
var _atmosphere_root: Node3D
var _dressing_root: Node3D
var _markers_root: Node3D


func build_for_island(island_root: Node3D, island_bounds: AABB) -> void:
	_build_materials()
	_atmosphere_root = Node3D.new()
	_atmosphere_root.name = "PreviewAtmosphere"
	add_child(_atmosphere_root)
	_build_atmosphere()
	_dressing_root = Node3D.new()
	_dressing_root.name = "PreviewDressing"
	island_root.add_child(_dressing_root)
	_build_surface_dressing(island_bounds)
	_markers_root = Node3D.new()
	_markers_root.name = "IntegrationMarkers"
	add_child(_markers_root)
	_build_integration_markers()


func tame_production_materials(visual_root: Node) -> void:
	if visual_root == null:
		return
	_tame_materials_recursive(visual_root)


func set_debug_visible(visible: bool) -> void:
	if _markers_root:
		_markers_root.visible = visible


func _tame_materials_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh:
			for surface_idx in mesh.get_surface_count():
				var material: Material = mesh_instance.get_surface_override_material(surface_idx)
				if material == null:
					material = mesh.surface_get_material(surface_idx)
				if material is StandardMaterial3D:
					var tuned: StandardMaterial3D = (material as StandardMaterial3D).duplicate() as StandardMaterial3D
					tuned.emission_energy_multiplier = minf(tuned.emission_energy_multiplier, 0.26)
					tuned.emission = tuned.emission.lerp(Color("35d6ff"), 0.35)
					mesh_instance.set_surface_override_material(surface_idx, tuned)
	for child in node.get_children():
		_tame_materials_recursive(child)


func _build_materials() -> void:
	_mats = {
		"rock": _mat(Color("4c5372"), 0.90, 0.0),
		"rock_dark": _mat(Color("20253f"), 0.97, 0.0),
		"grass": _mat(Color("43a968"), 0.84, 0.0),
		"grass_light": _mat(Color("88d46f"), 0.76, 0.0),
		"white": _mat(Color("fff5e1"), 0.72, 0.0),
		"brass": _mat(Color("dca64c"), 0.31, 0.75),
		"flower_pink": _mat(Color("ff8cca"), 0.43, 0.0, Color("e34d9c"), 0.22),
		"crystal": _mat(Color("7ef0ff"), 0.16, 0.22, Color("35d6ff"), 1.05),
		"crystal_soft": _mat(Color("8cecff"), 0.18, 0.18, Color("4de8ff"), 0.72),
		"cloud": _transparent_mat(Color(0.95, 0.98, 1.0, 0.58)),
		"marker_spawn": _mat(Color("45d8aa"), 0.35, 0.0, Color("45d8aa"), 0.35),
		"marker_cannon": _mat(Color("ffd77a"), 0.35, 0.55, Color("ffbd3f"), 0.25),
	}


func _mat(color: Color, roughness: float, metallic: float, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material


func _transparent_mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	return material


func _build_atmosphere() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(210.0, 340.0)
	var sky_mat := StandardMaterial3D.new()
	sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_mat.albedo_texture = load("res://art/generated/sky_route_backdrop_v10.png")
	sky_mat.albedo_color = Color(0.92, 0.96, 1.0, 1.0)
	sky_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	quad.material = sky_mat
	var backdrop := MeshInstance3D.new()
	backdrop.mesh = quad
	backdrop.position = Vector3(0.0, 78.0, -290.0)
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_atmosphere_root.add_child(backdrop)
	var distant_layout := [
		[Vector3(-95.0, 18.0, -210.0), 0.55],
		[Vector3(88.0, 24.0, -248.0), 0.62],
		[Vector3(-42.0, 12.0, -320.0), 0.48],
	]
	for entry in distant_layout:
		_add_distant_silhouette(entry[0], entry[1])
	var cloud_layout := [
		[Vector3(-18.0, 8.0, -36.0), Vector3(6.2, 1.5, 2.6)],
		[Vector3(22.0, 14.0, -58.0), Vector3(5.4, 1.3, 2.2)],
		[Vector3(-8.0, 22.0, -92.0), Vector3(7.0, 1.7, 2.8)],
		[Vector3(14.0, 30.0, -138.0), Vector3(7.8, 1.9, 3.0)],
		[Vector3(-24.0, 38.0, -182.0), Vector3(8.4, 2.0, 3.2)],
	]
	for entry in cloud_layout:
		_add_cloud(entry[0], entry[1])


func _add_distant_silhouette(pos: Vector3, scale_factor: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_factor
	_atmosphere_root.add_child(root)
	_add_mesh(root, _cylinder(5.5, 1.2, 14), _mats.rock_dark, Vector3(0.0, 0.6, 0.0))
	_add_mesh(root, _cylinder(3.8, 2.4, 12), _mats.rock, Vector3(-1.8, 2.2, 0.4))
	_add_mesh(root, _cylinder(3.2, 1.8, 10), _mats.grass, Vector3(2.1, 1.8, -0.3))


func _add_cloud(pos: Vector3, cloud_scale: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	_atmosphere_root.add_child(root)
	for offset in [Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.3, -0.1), Vector3(1.0, -0.05, 0.1)]:
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		_add_mesh(root, sphere, _mats.cloud, offset, cloud_scale)


func _build_surface_dressing(bounds: AABB) -> void:
	var surface_y: float = bounds.position.y + bounds.size.y * 0.92
	_add_path_edge_stones(surface_y)
	var grass_spots: Array = [
		Vector3(-7.2, surface_y, 2.4), Vector3(-5.4, surface_y, 4.8), Vector3(-3.2, surface_y, 6.1),
		Vector3(4.6, surface_y, 5.2), Vector3(7.0, surface_y, 3.0), Vector3(8.4, surface_y, -1.2),
		Vector3(-8.0, surface_y, -2.5), Vector3(6.2, surface_y, -4.4),
	]
	for pos in grass_spots:
		_add_grass_tuft(pos)
	var flower_spots: Array = [
		[Vector3(-4.8, surface_y, 5.6), 0], [Vector3(5.2, surface_y, 4.4), 1], [Vector3(-6.8, surface_y, -1.8), 2],
	]
	for entry in flower_spots:
		_add_flower(entry[0], entry[1])
	var rock_spots: Array = [
		Vector3(-9.2, surface_y, 0.5), Vector3(9.0, surface_y, 1.2), Vector3(-2.0, surface_y, -6.0),
		Vector3(3.4, surface_y, -5.5), Vector3(0.8, surface_y, 7.0),
	]
	for pos in rock_spots:
		_add_rock_pebble(pos)
	_add_crystal_accent(Vector3(-5.6, surface_y, -3.8), 0.72)
	_add_crystal_accent(Vector3(6.4, surface_y, -2.6), 0.84)
	_add_crystal_accent(Vector3(1.2, surface_y, 6.8), 0.58)
	_add_crystal_shards(Vector3(-5.6, surface_y, -3.8), 0.34)
	_add_crystal_shards(Vector3(6.4, surface_y, -2.6), 0.28)
	_add_crystal_shards(Vector3(1.2, surface_y, 6.8), 0.22)


func _add_path_edge_stones(surface_y: float) -> void:
	for i in range(8):
		var z: float = 2.8 - i * 0.78
		var center := Vector3(sin(i * 0.85) * 0.18, surface_y + 0.04, z)
		var stone := CylinderMesh.new()
		stone.top_radius = 0.46
		stone.bottom_radius = 0.40
		stone.height = 0.08
		stone.radial_segments = 8
		_add_mesh(_dressing_root, stone, _mats.white if i % 2 == 0 else _mats.rock, center, Vector3(1.0, 1.0, 0.74), Vector3(0.0, i * 17.0, 0.0))
		for side in [-1.0, 1.0]:
			var edge := Vector3(center.x + side * 0.72, surface_y + 0.02, center.z)
			_add_grass_tuft(edge)


func _add_grass_tuft(pos: Vector3) -> void:
	var tuft := Node3D.new()
	tuft.position = pos
	_dressing_root.add_child(tuft)
	for i in range(3):
		var blade := PrismMesh.new()
		blade.size = Vector3(0.13, 0.48 + i * 0.07, 0.09)
		_add_mesh(tuft, blade, _mats.grass_light, Vector3((i - 1) * 0.14, 0.22, 0.0), Vector3.ONE, Vector3(0.0, 0.0, -16.0 + i * 16.0))


func _add_flower(pos: Vector3, variant: int) -> void:
	var flower := Node3D.new()
	flower.position = pos
	_dressing_root.add_child(flower)
	_add_mesh(flower, _cylinder(0.035, 0.32, 6), _mats.grass, Vector3(0.0, 0.16, 0.0))
	var petal_material: Material = _mats.flower_pink if variant == 0 else _mats.crystal_soft if variant == 1 else _mats.grass_light
	for angle in [0.0, 90.0, 180.0, 270.0]:
		var petal := SphereMesh.new()
		petal.radius = 0.085
		petal.height = 0.14
		var offset := Vector3(cos(deg_to_rad(angle)) * 0.08, 0.34, sin(deg_to_rad(angle)) * 0.08)
		_add_mesh(flower, petal, petal_material, offset, Vector3(1.1, 0.58, 0.86))


func _add_rock_pebble(pos: Vector3) -> void:
	var pebble := SphereMesh.new()
	pebble.radius = 0.22
	pebble.height = 0.16
	_add_mesh(_dressing_root, pebble, _mats.rock, pos + Vector3(0.0, 0.08, 0.0), Vector3(1.1, 0.55, 0.95))


func _add_crystal_accent(pos: Vector3, scale_value: float) -> void:
	_add_mesh(_dressing_root, _cylinder(scale_value * 0.9, 0.12, 10), _mats.rock_dark, pos + Vector3(0.0, 0.04, 0.0))
	var prism := PrismMesh.new()
	prism.size = Vector3(0.42, 1.05, 0.36)
	_add_mesh(_dressing_root, prism, _mats.crystal_soft, pos + Vector3(0.0, 0.55 * scale_value, 0.0), Vector3.ONE * scale_value, Vector3(0.0, 0.0, 12.0))


func _add_crystal_shards(pos: Vector3, scale_value: float) -> void:
	for offset in [Vector3(-0.18, 0.0, 0.05), Vector3(0.14, 0.0, -0.08), Vector3(0.02, 0.0, 0.16)]:
		var shard := PrismMesh.new()
		shard.size = Vector3(0.14, 0.34, 0.12)
		_add_mesh(_dressing_root, shard, _mats.crystal_soft, pos + offset + Vector3(0.0, 0.08, 0.0), Vector3.ONE * scale_value, Vector3(0.0, 0.0, randf_range(-18.0, 18.0)))


func _build_integration_markers() -> void:
	var spawn := CylinderMesh.new()
	spawn.top_radius = 0.55
	spawn.bottom_radius = 0.55
	spawn.height = 0.05
	spawn.radial_segments = 16
	_add_mesh(_markers_root, spawn, _mats.marker_spawn, Vector3(0.0, FLOOR_OFFSET, 1.0))
	var cannon_pad := CylinderMesh.new()
	cannon_pad.top_radius = 1.35
	cannon_pad.bottom_radius = 1.35
	cannon_pad.height = 0.04
	cannon_pad.radial_segments = 18
	_add_mesh(_markers_root, cannon_pad, _mats.marker_cannon, Vector3(0.0, FLOOR_OFFSET, -1.2))
	var walk_ring := TorusMesh.new()
	walk_ring.inner_radius = SOURCE_RADIUS * 0.91 - 0.2
	walk_ring.outer_radius = SOURCE_RADIUS * 0.91
	walk_ring.rings = 24
	walk_ring.ring_segments = 6
	_add_mesh(_markers_root, walk_ring, _mats.marker_spawn, Vector3(0.0, FLOOR_OFFSET + 0.02, 0.0), Vector3.ONE, Vector3(90.0, 0.0, 0.0))


func _add_mesh(
	parent: Node,
	mesh: Mesh,
	material: Material,
	pos: Vector3 = Vector3.ZERO,
	scale_value: Vector3 = Vector3.ONE,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.scale = scale_value
	instance.rotation_degrees = rotation_degrees
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if mesh.get_aabb().size.length() < 8.0:
		instance.visibility_range_end = 120.0
		instance.visibility_range_end_margin = 16.0
	parent.add_child(instance)
	return instance


func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh
