extends RefCounted
class_name StylizedMotionController

## V29 — Reusable procedural motion helpers (visual-only, mobile-safe).

const WIND_MATERIAL_KEYS: Array[String] = [
	"grass_main", "grass_light", "grass_dark", "distant_grass",
	"leaf_green", "leaf_light", "leaf_dark",
]
const TREE_WIND_SCALE := 0.42


static func wind_strength_for_quality(quality_level: int) -> float:
	match clampi(quality_level, 0, 2):
		0: return 0.0
		1: return 0.028
		_: return 0.038


static func wind_speed_for_quality(quality_level: int) -> float:
	match clampi(quality_level, 0, 2):
		0: return 0.0
		1: return 0.88
		_: return 1.05


static func configure_wind_materials(mats: Dictionary, quality_level: int) -> void:
	var strength := wind_strength_for_quality(quality_level)
	var speed := wind_speed_for_quality(quality_level)
	var phase := 0.0
	for key in WIND_MATERIAL_KEYS:
		if not mats.has(key):
			continue
		var material: Material = mats[key]
		if material is ShaderMaterial:
			var shader_mat := material as ShaderMaterial
			var local_strength := strength
			if key.begins_with("leaf"):
				local_strength *= TREE_WIND_SCALE
			shader_mat.set_shader_parameter("wind_strength", local_strength)
			shader_mat.set_shader_parameter("wind_speed", speed)
			shader_mat.set_shader_parameter("wind_phase", phase)
			phase += 23.7 + float(key.hash() % 17) * 0.31


static func cloud_drift_speed(depth_layer: int) -> float:
	match clampi(depth_layer, 0, 2):
		0: return 0.05
		1: return 0.09
		_: return 0.13


static func update_clouds(clouds: Array, idle_time: float) -> void:
	for cloud in clouds:
		if not is_instance_valid(cloud):
			continue
		var origin: Vector3 = cloud.get_meta("origin", cloud.position)
		var phase: float = float(cloud.get_meta("phase", 0.0))
		var depth: int = int(cloud.get_meta("drift_depth", 1))
		var speed: float = float(cloud.get_meta("drift_speed", cloud_drift_speed(depth)))
		var amp_x: float = 0.74 + float(depth) * 0.36
		var amp_z: float = 0.08 + float(depth) * 0.06
		var amp_y: float = 0.04 + float(depth) * 0.02
		cloud.position.x = origin.x + sin(idle_time * speed + phase) * amp_x
		cloud.position.z = origin.z + cos(idle_time * speed * 0.78 + phase * 0.71) * amp_z
		cloud.position.y = origin.y + sin(idle_time * speed * 0.42 + phase * 1.2) * amp_y


static func update_animated_nodes(nodes: Array, delta: float, idle_time: float) -> void:
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if node.has_meta("animate_rotor"):
			node.rotation.z += delta * 0.65
		elif node.has_meta("animate_portal"):
			var dir: float = -1.0 if node.has_meta("portal_counter") else 1.0
			node.rotation.y += delta * 0.55 * dir
			_pulse_emission(node, idle_time)
		elif node.has_meta("animate_pad"):
			node.rotation.y += delta * 0.42
			_pulse_emission(node, idle_time, 0.42, 0.10)
		elif node.has_meta("animate_pad_ring"):
			node.rotation.y -= delta * 0.28
			var pulse: float = 1.0 + sin(idle_time * 2.4 + float(node.get_meta("pulse_phase", 0.0))) * 0.04
			node.scale = Vector3.ONE * pulse
		elif node.has_meta("hero_crystal"):
			node.rotation.y += delta * 0.35
			var hover: float = sin(idle_time * 2.1 + float(node.get_meta("pulse_phase", 0.0))) * 0.045
			var origin_y: float = float(node.get_meta("hover_origin_y", node.position.y))
			node.position.y = origin_y + hover
			_pulse_emission(node, idle_time, 0.40, 0.12)


static func update_pickup_motion(items: Array, delta: float, idle_time: float) -> void:
	for item in items:
		if bool(item.get("taken", false)) or not is_instance_valid(item.get("node")):
			continue
		var node: Node3D = item.node
		var phase: float = float(item.get("phase", 0.0))
		var origin: Vector3 = item.get("origin", node.position)
		node.rotation.y += delta * 1.55
		node.rotation.x = sin(idle_time * 1.2 + phase) * 0.045
		var bob: float = 0.04 + sin(idle_time * 1.85 + phase) * 0.018
		if bool(item.get("objective", false)):
			bob += 0.035
		node.position.y = float(origin.y) + bob


static func update_flower_sway(nodes: Array, idle_time: float) -> void:
	for node in nodes:
		if not is_instance_valid(node):
			continue
		var phase: float = float(node.get_meta("sway_phase", 0.0))
		node.rotation.z = sin(idle_time * 1.25 + phase) * 0.08
		node.rotation.x = sin(idle_time * 0.92 + phase * 1.3) * 0.05


static func update_lootling_visual(
	visual: Node3D,
	sprout: Node3D,
	idle_time: float,
	moving: bool,
	delta: float,
	target_scale: Vector3
) -> void:
	if visual == null:
		return
	if moving:
		visual.position.y = lerpf(visual.position.y, sin(idle_time * 10.5) * 0.06, minf(1.0, delta * 14.0))
		visual.scale = visual.scale.lerp(target_scale, minf(1.0, delta * 10.0))
	else:
		var breath: float = sin(idle_time * 2.6) * 0.028
		visual.position.y = lerpf(visual.position.y, breath, minf(1.0, delta * 6.0))
		var squash: float = 1.0 + sin(idle_time * 2.6) * 0.025
		visual.scale = visual.scale.lerp(Vector3(squash, 1.0 - (squash - 1.0) * 0.6, squash), minf(1.0, delta * 5.0))
	if sprout != null:
		var leaf_strength: float = 0.14 if moving else 0.08
		sprout.rotation.z = sin(idle_time * 2.2) * leaf_strength
		sprout.rotation.x = sin(idle_time * 1.7 + 0.4) * leaf_strength * 0.55


static func apply_jump_stretch(visual: Node3D) -> void:
	if visual == null:
		return
	visual.scale = Vector3(0.86, 1.16, 0.86)


static func apply_land_squash(visual: Node3D) -> void:
	if visual == null:
		return
	visual.scale = Vector3(1.18, 0.78, 1.18)
	var tween := visual.create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC)


static func play_collect_pop(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", node.scale * 1.22, 0.08).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector3.ZERO, 0.16).set_delay(0.06).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(Callable(node, "hide"))


static func play_cannon_recoil(pivot: Node3D, aim_direction: Vector3, on_burst: Callable) -> Vector3:
	if pivot == null:
		return Vector3.ZERO
	var origin: Vector3 = pivot.get_meta("recoil_origin", pivot.position)
	pivot.position = origin
	var kick: Vector3 = origin
	if aim_direction.length_squared() > 0.01:
		var local_back: Vector3 = pivot.global_transform.basis.inverse() * (-aim_direction.normalized())
		kick += local_back * 0.26
	else:
		kick.z += 0.26
	var tween := pivot.create_tween()
	tween.tween_property(pivot, "position", kick, 0.07).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(pivot, "position", origin, 0.24).set_trans(Tween.TRANS_BACK)
	if on_burst.is_valid():
		on_burst.call()
	return origin


static func register_cannon_recoil_origin(pivot: Node3D) -> void:
	if pivot == null:
		return
	if not pivot.has_meta("recoil_origin"):
		pivot.set_meta("recoil_origin", pivot.position)


static func collect_sway_nodes(root: Node) -> Array:
	var found: Array = []
	_collect_sway_nodes_recursive(root, found)
	return found


static func collect_motion_nodes(root: Node) -> Array:
	var found: Array = []
	_collect_motion_nodes_recursive(root, found)
	return found


static func is_transform_finite(node: Node3D) -> bool:
	if node == null:
		return true
	var origin: Vector3 = node.global_transform.origin
	return is_finite(origin.x) and is_finite(origin.y) and is_finite(origin.z)


static func _pulse_emission(node: Node, idle_time: float, base_energy: float = 0.48, amp: float = 0.12) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var material: Material = mesh.material_override
		if material is StandardMaterial3D:
			var std := material as StandardMaterial3D
			if std.emission_enabled:
				var phase: float = float(node.get_meta("pulse_phase", 0.0))
				std.emission_energy_multiplier = base_energy + sin(idle_time * 2.35 + phase) * amp


static func _collect_sway_nodes_recursive(node: Node, found: Array) -> void:
	if node is Node3D and node.has_meta("vegetation_kind"):
		if str(node.get_meta("vegetation_kind")) == "flower":
			if not node.has_meta("sway_phase"):
				node.set_meta("sway_phase", float(node.get_index()) * 0.73)
			found.append(node)
	for child in node.get_children():
		_collect_sway_nodes_recursive(child, found)


static func _collect_motion_nodes_recursive(node: Node, found: Array) -> void:
	if node is Node3D:
		if node.has_meta("hero_crystal") or node.has_meta("animate_pad") or node.has_meta("animate_pad_ring"):
			found.append(node)
	for child in node.get_children():
		_collect_motion_nodes_recursive(child, found)
