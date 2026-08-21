extends Node3D

## 3D vertical slice. Economy and final rewards remain backend-authoritative.
signal finished(submission: Dictionary)
signal combo_changed(value: int)
signal launched
signal aim_changed(angle: float, power: float)
signal loot_collected(kind: String, value: int, screen_position: Vector2)
signal state_changed(label: String)

enum LaunchState { READY, AIMING, FIRED, SPECIAL_AVAILABLE, RESULT }

const MIN_ANGLE := 18.0
const MAX_ANGLE := 82.0
const DEADZONE_PX := 48.0
const MAX_DRAG_PX := 390.0
const GRAVITY := 8.6
const MAX_DURATION := 11.8
const CANNON_POSITION := Vector3(-4.25, -6.65, 0.65)
const MUZZLE_LENGTH := 1.55

var session: Dictionary = {}
var lootling := "bouncer"
var cannon := "standard"
var is_pvp := false
var shot_number := 0
var launch_state: LaunchState = LaunchState.READY
var fired := false
var ability_used := false
var angle := 48.0
var power := 0.72
var target_angle := 48.0
var target_power := 0.72
var elapsed := 0.0
var ability_time := -1.0
var events: Array = []
var combo := 0
var sequence := 0
var active_pointer_id := -999
var gesture_start := Vector2.ZERO
var gesture_distance := 0.0
var random := RandomNumberGenerator.new()
var projectile: CharacterBody3D
var projectile_visual: Node3D
var cannon_root: Node3D
var cannon_pivot: Node3D
var cannon_barrel: Node3D
var cannon_crystal: MeshInstance3D
var camera: Camera3D
var camera_base := Vector3(0.0, 0.0, 25.0)
var trajectory_root: Node3D
var impact_marker: MeshInstance3D
var collectibles: Array = []
var portal_pairs: Array = []
var boosters: Array = []
var moving_obstacles: Array = []
var slow_motion := 1.0
var slow_motion_left := 0.0
var hit_stop_left := 0.0
var camera_shake := 0.0
var portal_cooldown := 0.0
var still_time := 0.0
var last_trail_position := Vector3(999.0, 999.0, 999.0)
var result_sent := false
var idle_phase := 0.0
var mats: Dictionary = {}
var effect_pool: Array[MeshInstance3D] = []


func begin(value: Dictionary, selected_lootling: String, selected_cannon: String, pvp := false, number := 0) -> void:
	session = value.duplicate(true)
	lootling = selected_lootling
	cannon = selected_cannon
	is_pvp = pvp
	shot_number = number
	random.seed = int(value.get("seed", 7331)) + number
	_build_materials()
	_prewarm_effect_pool()
	_build_camera_and_light()
	_build_background()
	_build_floating_islands()
	_build_level()
	_build_cannon()
	_build_trajectory_preview()
	_set_state(LaunchState.READY)
	_update_aim_visuals(true)


func _build_materials() -> void:
	mats = {
		"stone": _material(Color("665a7b"), 0.82, 0.05),
		"stone_dark": _material(Color("342c52"), 0.9, 0.02),
		"grass": _material(Color("55a85f"), 0.88, 0.0),
		"grass_light": _material(Color("8bd36d"), 0.8, 0.0),
		"brass": _material(Color("d5a447"), 0.34, 0.72),
		"bronze": _material(Color("8b522f"), 0.45, 0.65),
		"cannon": _material(Color("37345f"), 0.28, 0.72),
		"violet": _material(Color("734be8"), 0.38, 0.28, Color("3d1ba4"), 1.6),
		"crystal": _material(Color("75eaff"), 0.2, 0.2, Color("45cfff"), 2.5),
		"crystal_violet": _material(Color("b56cff"), 0.2, 0.2, Color("8a3fff"), 2.2),
		"coin": _material(Color("ffd04b"), 0.22, 0.65, Color("ffb51e"), 1.15),
		"wood": _material(Color("8b4d30"), 0.78, 0.05),
		"mushroom": _material(Color("f04e6f"), 0.64, 0.02),
		"white": _material(Color("fff8e6"), 0.72, 0.0),
		"ink": _material(Color("17203d"), 0.7, 0.0),
		"bouncer": _material(Color("63e5aa"), 0.5, 0.05, Color("27a878"), 0.35),
		"booster": _material(Color("46d9ff"), 0.25, 0.1, Color("22aeea"), 2.4),
		"danger": _material(Color("ef5d73"), 0.45, 0.18, Color("ae254c"), 0.45),
	}


func _material(color: Color, roughness: float, metallic: float, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material


func _build_camera_and_light() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("55b9ef")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bde8ff")
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	camera = Camera3D.new()
	camera.position = camera_base
	camera.fov = 42.0
	camera.near = 0.1
	camera.far = 80.0
	camera.current = true
	add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28.0, -24.0, -18.0)
	sun.light_color = Color("fff0cf")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 35.0
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.7, -5.9, 4.0)
	fill.light_color = Color("b66cff")
	fill.light_energy = 2.0
	fill.omni_range = 8.0
	add_child(fill)


func _build_background() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(12.6, 22.4)
	var sky_material := StandardMaterial3D.new()
	sky_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_material.albedo_texture = load("res://art/generated/magical_sky_backdrop.png")
	sky_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	quad.material = sky_material
	var sky := MeshInstance3D.new()
	sky.name = "GeneratedMagicalSky"
	sky.mesh = quad
	sky.position = Vector3(0.0, 0.0, -7.5)
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sky)
	for cloud_data in [
		[Vector3(-5.0, 4.8, -4.8), Vector3(2.5, 0.8, 0.6)],
		[Vector3(4.6, 2.0, -4.2), Vector3(2.8, 0.9, 0.7)],
		[Vector3(-4.7, -1.1, -3.8), Vector3(2.2, 0.7, 0.6)],
		[Vector3(4.4, -5.2, -3.6), Vector3(2.6, 0.7, 0.6)],
	]:
		_add_cloud(cloud_data[0], cloud_data[1])


func _add_cloud(pos: Vector3, cloud_scale: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var cloud_mat := _material(Color(0.93, 0.97, 1.0, 0.7), 1.0, 0.0)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for offset in [Vector3(-0.7, 0, 0), Vector3(0, 0.18, 0.08), Vector3(0.75, -0.05, 0)]:
		var sphere := SphereMesh.new()
		sphere.radius = 0.7
		sphere.height = 1.4
		_mesh(root, sphere, cloud_mat, offset, cloud_scale)


func _build_floating_islands() -> void:
	_add_island(Vector3(-3.8, -7.45, -0.2), Vector3(3.1, 0.75, 2.8), true)
	_add_island(Vector3(3.9, 6.7, -2.1), Vector3(2.0, 0.55, 1.7), false)
	_add_island(Vector3(-4.3, 5.8, -3.1), Vector3(1.2, 0.4, 1.1), false)


func _add_island(pos: Vector3, island_scale: Vector3, playable: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var top := _cylinder_mesh(island_scale.x, island_scale.y, 12)
	top.bottom_radius = island_scale.x * 0.88
	_mesh(root, top, mats.grass, Vector3.ZERO, Vector3(1, 1, island_scale.z / island_scale.x))
	for i in range(5 if playable else 3):
		var radius := island_scale.x * (0.78 - i * 0.1)
		var rock := _cylinder_mesh(radius, island_scale.y * 0.8, 9)
		rock.bottom_radius = radius * 0.72
		_mesh(root, rock, mats.stone_dark, Vector3(0, -0.55 - i * 0.48, 0), Vector3(1, 1, island_scale.z / island_scale.x))
	if playable:
		for crystal_pos in [Vector3(-2.2, 0.65, 0.5), Vector3(1.8, 0.6, -0.4), Vector3(-1.7, 0.55, -0.9)]:
			_add_crystal_cluster(root, crystal_pos, 0.45)


func _build_level() -> void:
	_add_aether_boundaries()
	_add_platform(Vector3(1.25, -3.35, 0.0), Vector3(3.5, 0.35, 1.25), 6.0)
	_add_platform(Vector3(2.55, 0.65, -0.15), Vector3(3.0, 0.35, 1.15), -8.0)
	_add_platform(Vector3(-1.25, 3.05, 0.1), Vector3(3.15, 0.35, 1.3), 9.0)
	_add_platform(Vector3(2.45, 5.55, -0.05), Vector3(3.15, 0.35, 1.2), -6.0)
	_add_mushroom(Vector3(0.35, -2.68, 0.05))
	_add_mushroom(Vector3(2.85, 1.37, -0.1))
	_add_portal_pair(Vector3(3.75, -2.55, 0.0), Vector3(-3.55, 1.25, 0.0))
	_add_booster(Vector3(0.5, -1.92, 0.15), Vector3(0.8, 0.6, 0.0))
	_add_moving_obstacle(Vector3(0.1, 3.75, 0.15))
	_add_destructible(Vector3(1.7, -2.7, 0.1))
	_add_destructible(Vector3(-0.55, 3.72, 0.1))
	for position in [
		Vector3(-2.35, -4.35, 0.25), Vector3(-1.55, -3.55, 0.1), Vector3(-0.75, -2.72, 0.0),
		Vector3(0.05, -1.92, 0.2), Vector3(0.9, -1.12, -0.1), Vector3(1.75, -0.35, 0.1),
		Vector3(2.6, 0.42, 0.0), Vector3(3.45, 1.2, 0.2), Vector3(2.0, 1.8, -0.1),
		Vector3(0.65, 1.9, 0.2), Vector3(-0.55, 2.65, 0.0), Vector3(-1.85, 3.1, 0.1),
		Vector3(-1.0, 4.0, -0.1), Vector3(0.25, 4.45, 0.2), Vector3(1.5, 4.8, 0.0)
	]:
		_add_collectible(position, "coin", 25)
	_add_collectible(Vector3(3.25, 1.8, 0.0), "crystal", 1)
	_add_collectible(Vector3(-2.85, 4.4, 0.05), "crystal", 1)
	_add_collectible(Vector3(2.55, 5.95, 0.1), "treasure", 0)


func _build_cannon() -> void:
	cannon_root = Node3D.new()
	cannon_root.name = "ArcaneCannon3D"
	cannon_root.position = CANNON_POSITION
	add_child(cannon_root)
	var base := _cylinder_mesh(0.9, 0.55, 16)
	base.top_radius = 0.83
	_mesh(cannon_root, base, mats.bronze, Vector3(0, -0.45, 0), Vector3(1, 1, 0.8))
	_mesh(cannon_root, _cylinder_mesh(0.74, 0.18, 18), mats.brass, Vector3(0, -0.1, 0), Vector3(1, 1, 0.8))
	var crystal := SphereMesh.new()
	crystal.radius = 0.42
	crystal.height = 0.85
	cannon_crystal = _mesh(cannon_root, crystal, mats.crystal_violet, Vector3(0, 0.05, 0.1), Vector3(0.72, 1, 0.7))
	cannon_pivot = Node3D.new()
	cannon_pivot.name = "AimPivot"
	cannon_pivot.position = Vector3(0, 0.15, 0)
	cannon_root.add_child(cannon_pivot)
	cannon_barrel = Node3D.new()
	cannon_barrel.name = "MovingBarrel"
	cannon_pivot.add_child(cannon_barrel)
	var tube := _cylinder_mesh(0.5, 1.95, 16)
	tube.top_radius = 0.42
	_mesh(cannon_barrel, tube, mats.cannon, Vector3(0.95, 0, 0), Vector3.ONE, Vector3(0, 0, -90))
	for x in [0.28, 1.58]:
		_mesh(cannon_barrel, _cylinder_mesh(0.62, 0.2, 16), mats.brass, Vector3(x, 0, 0), Vector3.ONE, Vector3(0, 0, -90))
	var loaded_bouncer := _create_bouncer()
	loaded_bouncer.name = "LoadedBouncer"
	loaded_bouncer.position = Vector3(1.02, 0, 0)
	loaded_bouncer.scale = Vector3.ONE * 0.55
	loaded_bouncer.set_meta("loaded", true)
	cannon_barrel.add_child(loaded_bouncer)
	var tween := loaded_bouncer.create_tween().set_loops()
	tween.tween_property(loaded_bouncer, "scale", Vector3(0.58, 0.52, 0.58), 0.42).set_trans(Tween.TRANS_SINE)
	tween.tween_property(loaded_bouncer, "scale", Vector3.ONE * 0.55, 0.42).set_trans(Tween.TRANS_SINE)


func _build_trajectory_preview() -> void:
	trajectory_root = Node3D.new()
	trajectory_root.name = "ShortBallisticPreview"
	add_child(trajectory_root)
	for i in range(13):
		var dot_mesh := SphereMesh.new()
		dot_mesh.radius = 0.065 + i * 0.002
		dot_mesh.height = dot_mesh.radius * 2.0
		var dot := _mesh(trajectory_root, dot_mesh, mats.coin)
		dot.name = "PreviewDot%02d" % i
	impact_marker = _mesh(self, _cylinder_mesh(0.42, 0.04, 24), mats.danger)
	impact_marker.name = "ProbableFirstImpact"
	impact_marker.rotation_degrees.x = 90.0


func _input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pointer_id := -1
	var is_press := false
	var is_release := false
	var is_motion := false
	if event is InputEventScreenTouch:
		pos = event.position; pointer_id = event.index; is_press = event.pressed; is_release = not event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position; pointer_id = event.index; is_motion = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position; pointer_id = -1; is_press = event.pressed; is_release = not event.pressed
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pos = event.position; pointer_id = -1; is_motion = true
	else:
		return
	if is_press:
		if launch_state == LaunchState.READY and _is_on_cannon(pos) and not _is_ui_zone(pos):
			active_pointer_id = pointer_id
			gesture_start = pos
			gesture_distance = 0.0
			_set_state(LaunchState.AIMING)
		elif launch_state == LaunchState.SPECIAL_AVAILABLE and not _is_ui_zone(pos):
			activate_special()
		return
	if active_pointer_id != pointer_id:
		return
	if is_motion and launch_state == LaunchState.AIMING:
		_update_gesture(pos)
	elif is_release and launch_state == LaunchState.AIMING:
		active_pointer_id = -999
		if gesture_distance < DEADZONE_PX: _cancel_aim()
		else: _fire()


func _is_on_cannon(screen_position: Vector2) -> bool:
	if camera == null or cannon_root == null: return false
	var center := camera.unproject_position(cannon_root.global_position + Vector3(0.5, 0.05, 0))
	return screen_position.distance_to(center) <= 150.0


func _is_ui_zone(pos: Vector2) -> bool:
	return pos.y < 165.0 or (pos.x >= 275.0 and pos.x <= 805.0 and pos.y >= 1535.0 and pos.y <= 1695.0)


func _update_gesture(pos: Vector2) -> void:
	var drag := pos - gesture_start
	gesture_distance = minf(drag.length(), MAX_DRAG_PX)
	if gesture_distance < DEADZONE_PX: return
	var launch_screen := -drag.normalized()
	target_angle = clampf(rad_to_deg(atan2(-launch_screen.y, launch_screen.x)), MIN_ANGLE, MAX_ANGLE)
	var normalized := clampf((gesture_distance - DEADZONE_PX) / (MAX_DRAG_PX - DEADZONE_PX), 0.0, 1.0)
	target_power = lerpf(0.22, 1.0, pow(normalized, 0.82))
	aim_changed.emit(target_angle, target_power)


func _cancel_aim() -> void:
	target_angle = 48.0; target_power = 0.72; gesture_distance = 0.0
	_set_state(LaunchState.READY)


func _set_state(next_state: LaunchState) -> void:
	launch_state = next_state
	state_changed.emit(LaunchState.keys()[next_state])


func _process(delta: float) -> void:
	idle_phase += delta
	if launch_state in [LaunchState.READY, LaunchState.AIMING]:
		angle = lerpf(angle, target_angle, minf(1.0, delta * 13.0))
		power = lerpf(power, target_power, minf(1.0, delta * 11.0))
		_update_aim_visuals(false)
		if cannon_crystal:
			var charge := power if launch_state == LaunchState.AIMING else 0.32 + sin(idle_phase * 2.2) * 0.06
			cannon_crystal.scale = Vector3.ONE * (0.72 + charge * 0.2)
	if projectile_visual and launch_state in [LaunchState.FIRED, LaunchState.SPECIAL_AVAILABLE]:
		projectile_visual.rotation.z -= delta * 5.0
		var stretch := 1.0 + sin(elapsed * 13.0) * 0.025
		projectile_visual.scale = Vector3(stretch, 2.0 - stretch, 1.0)
	for pair in portal_pairs:
		for portal in [pair.a, pair.b]:
			if is_instance_valid(portal):
				portal.rotation.z += delta * 1.3
				portal.scale = Vector3.ONE * (1.0 + sin(idle_phase * 3.0 + float(pair.phase)) * 0.06)
	for obstacle_data in moving_obstacles:
		var obstacle: AnimatableBody3D = obstacle_data.body
		if is_instance_valid(obstacle):
			obstacle.position.x = obstacle_data.origin.x + sin(idle_phase * 1.7 + obstacle_data.phase) * 1.05
			obstacle.rotation.z += delta * 1.35
	for item in collectibles:
		if not item.collected and is_instance_valid(item.node):
			item.node.rotation.y += delta * 2.2
			item.node.position.y = item.origin.y + sin(idle_phase * 3.0 + item.phase) * 0.08
	_update_camera(delta)


func _physics_process(delta: float) -> void:
	if launch_state not in [LaunchState.FIRED, LaunchState.SPECIAL_AVAILABLE] or projectile == null: return
	if hit_stop_left > 0.0:
		hit_stop_left -= delta
		return
	if slow_motion_left > 0.0:
		slow_motion_left -= delta; slow_motion = 0.34
	else:
		slow_motion = lerpf(slow_motion, 1.0, minf(1.0, delta * 8.0))
	var step := delta * slow_motion
	elapsed += delta
	portal_cooldown = maxf(0.0, portal_cooldown - delta)
	projectile.velocity.y -= GRAVITY * step
	var collision := projectile.move_and_collide(projectile.velocity * step)
	if collision: _handle_collision(collision)
	_enforce_aether_bounds()
	_check_interactions()
	_spawn_trail_segment()
	if projectile.velocity.length() < 0.6: still_time += delta
	else: still_time = 0.0
	if elapsed >= MAX_DURATION or (elapsed > 8.0 and still_time > 1.25):
		_finish()


func _enforce_aether_bounds() -> void:
	var bounced := false
	var normal := Vector3.ZERO
	if projectile.position.x > 5.1:
		projectile.position.x = 5.1; projectile.velocity.x = -absf(projectile.velocity.x) * 0.92; normal = Vector3.LEFT; bounced = true
	elif projectile.position.x < -5.1:
		projectile.position.x = -5.1; projectile.velocity.x = absf(projectile.velocity.x) * 0.92; normal = Vector3.RIGHT; bounced = true
	if projectile.position.y > 8.45:
		projectile.position.y = 8.45; projectile.velocity.y = -absf(projectile.velocity.y) * 0.9; normal = Vector3.DOWN; bounced = true
	elif projectile.position.y < -8.05:
		projectile.position.y = -8.05; projectile.velocity.y = absf(projectile.velocity.y) * 0.9; normal = Vector3.UP; bounced = true
	if bounced:
		_record("bounce", "aether_current", 0, projectile.position, projectile.velocity.length())
		_record("coin", "aether_risk_bonus", 5, projectile.position, projectile.velocity.length())
		loot_collected.emit("coin", 5, camera.unproject_position(projectile.global_position))
		_spawn_burst(projectile.position + normal * 0.08, mats.booster, 10, 0.52)
		_camera_kick(0.09)


func _update_aim_visuals(immediate: bool) -> void:
	if cannon_pivot == null: return
	cannon_pivot.rotation.z = deg_to_rad(angle)
	if trajectory_root: trajectory_root.visible = launch_state in [LaunchState.READY, LaunchState.AIMING]
	if impact_marker: impact_marker.visible = trajectory_root != null and trajectory_root.visible
	_update_trajectory_preview()
	if immediate: aim_changed.emit(angle, power)


func _update_trajectory_preview() -> void:
	if trajectory_root == null: return
	var start := _muzzle_position()
	var velocity := _launch_velocity()
	var predicted_impact := start
	for i in trajectory_root.get_child_count():
		var t := 0.075 * float(i + 1)
		var point := start + velocity * t + Vector3(0, -0.5 * GRAVITY * t * t, 0)
		trajectory_root.get_child(i).position = point
		predicted_impact = point
	impact_marker.position = predicted_impact + Vector3(0, -0.12, -0.08)


func _fire() -> void:
	if fired or launch_state != LaunchState.AIMING or gesture_distance < DEADZONE_PX: return
	angle = target_angle; power = target_power; fired = true; elapsed = 0.0
	_set_state(LaunchState.FIRED)
	trajectory_root.visible = false; impact_marker.visible = false
	for child in cannon_barrel.get_children():
		if child.has_meta("loaded"): child.queue_free()
	projectile = CharacterBody3D.new()
	projectile.name = "BouncerProjectile3D"
	projectile.position = _muzzle_position()
	projectile.collision_layer = 2
	projectile.collision_mask = 1
	var shape_node := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.35
	shape_node.shape = sphere_shape
	projectile.add_child(shape_node)
	projectile_visual = _create_bouncer()
	projectile.add_child(projectile_visual)
	add_child(projectile)
	projectile.velocity = _launch_velocity()
	last_trail_position = projectile.position
	_spawn_burst(projectile.position, mats.crystal_violet, 28, 1.15)
	_spawn_burst(projectile.position, mats.coin, 16, 0.75)
	_camera_kick(0.25)
	_recoil_cannon()
	AudioManager.play_launch()
	launched.emit()
	_set_state(LaunchState.SPECIAL_AVAILABLE)
	var squash := create_tween()
	projectile_visual.scale = Vector3(1.45, 0.64, 1)
	squash.tween_property(projectile_visual, "scale", Vector3(0.86, 1.18, 1), 0.1).set_trans(Tween.TRANS_BACK)
	squash.tween_property(projectile_visual, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC)


func _muzzle_position() -> Vector3:
	var direction := _direction()
	return CANNON_POSITION + Vector3(direction.x, direction.y, 0) * MUZZLE_LENGTH + Vector3(0, 0.15, 0)


func _direction() -> Vector2:
	return Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle)))


func _launch_velocity() -> Vector3:
	var max_speed := 18.6 if cannon == "thunder" else 15.0 if cannon == "portal" else 16.4
	var actual_angle := angle + random.randf_range(-2.8, 2.8) if cannon == "thunder" and fired else angle
	var direction := Vector2(cos(deg_to_rad(actual_angle)), sin(deg_to_rad(actual_angle)))
	var relic_multiplier := 1.05 if "wind_splinter" in GameState.relics else 1.0
	var workshop_multiplier := 1.0 + maxi(0, int(GameState.buildings.get("cannon_workshop", 1)) - 1) * 0.03
	return Vector3(direction.x, direction.y, 0) * lerpf(8.0, max_speed, power) * relic_multiplier * workshop_multiplier


func activate_special() -> void:
	if launch_state != LaunchState.SPECIAL_AVAILABLE or ability_used or projectile == null: return
	ability_used = true; ability_time = elapsed
	_record("ability", lootling, 0, projectile.position, projectile.velocity.length())
	projectile.velocity *= 1.34 if lootling == "bouncer" else 1.18
	if cannon == "portal": projectile.velocity *= 1.18
	_spawn_burst(projectile.position, mats.crystal, 24, 0.85)
	_camera_kick(0.16)
	_set_state(LaunchState.FIRED)


func _handle_collision(collision: KinematicCollision3D) -> void:
	var collider = collision.get_collider()
	var speed := projectile.velocity.length()
	var bounce := 1.03 if lootling == "bouncer" else 0.8
	if collider is Node and collider.has_meta("mushroom"):
		bounce = 1.22
		_animate_mushroom(collider)
	projectile.velocity = projectile.velocity.bounce(collision.get_normal()) * bounce
	projectile.position += collision.get_normal() * 0.04
	_record("bounce", collider.name if collider is Node else "platform", 0, projectile.position, speed)
	_spawn_burst(projectile.position, mats.coin if speed > 10.0 else mats.crystal, 12, 0.55)
	_camera_kick(clampf(speed / 65.0, 0.08, 0.24))
	if speed > 12.5:
		hit_stop_left = 0.045
		_deform_bouncer()
	if collider is Node and collider.has_meta("destructible") and speed > 8.5: _break_destructible(collider)
	var skill_bonuses := 0
	for event in events:
		if event.get("target", "") == "impact_bonus": skill_bonuses += 1
	if speed > 6.0 and skill_bonuses < 3: _record("coin", "impact_bonus", 10, projectile.position, speed)


func _check_interactions() -> void:
	if projectile == null: return
	for item in collectibles:
		if not item.collected and is_instance_valid(item.node) and projectile.position.distance_to(item.node.position) <= item.radius:
			_collect(item)
	for booster in boosters:
		if not booster.used and projectile.position.distance_to(booster.node.position) <= 0.75:
			booster.used = true
			projectile.velocity += booster.direction * 5.2
			_record("booster", "sky_booster", 0, booster.node.position, projectile.velocity.length())
			_spawn_burst(booster.node.position, mats.booster, 18, 0.75)
	for pair in portal_pairs:
		if portal_cooldown > 0.0: break
		if projectile.position.distance_to(pair.a.position) <= 0.67:
			_teleport_to(pair.b.position, "portal_a"); break
		if projectile.position.distance_to(pair.b.position) <= 0.67:
			_teleport_to(pair.a.position, "portal_b"); break


func _collect(item: Dictionary) -> void:
	item.collected = true
	var node: Node3D = item.node
	var screen_pos := camera.unproject_position(node.global_position)
	_record(item.kind, node.name, int(item.value), node.position, projectile.velocity.length())
	loot_collected.emit(item.kind, int(item.value), screen_pos)
	_spawn_burst(node.position, mats.coin if item.kind == "coin" else mats.crystal, 20 if item.kind == "coin" else 28, 0.8)
	if item.kind == "treasure": slow_motion_left = 0.55; _camera_kick(0.32)
	var tween := create_tween().set_parallel()
	tween.tween_property(node, "scale", Vector3.ONE * 1.8, 0.14).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "position", node.position + Vector3(0, 1, 0.8), 0.24)
	tween.tween_property(node, "scale", Vector3.ZERO, 0.26).set_delay(0.12)
	tween.chain().tween_callback(node.queue_free)


func _teleport_to(destination: Vector3, target: String) -> void:
	portal_cooldown = 0.65
	_spawn_burst(projectile.position, mats.crystal_violet, 22, 0.8)
	projectile.position = destination + projectile.velocity.normalized() * 0.75
	_spawn_burst(projectile.position, mats.booster, 22, 0.8)
	_record("portal", target, 0, projectile.position, projectile.velocity.length())
	_camera_kick(0.22)


func _record(kind: String, target: String, value: int, pos: Vector3, speed: float) -> void:
	events.append({"sequence": sequence, "type": kind, "target": target, "time": elapsed,
		"x": pos.x * 100.0 + 540.0, "y": 960.0 - pos.y * 100.0,
		"speed": minf(speed * 2.6, 60.0), "value": value})
	sequence += 1; combo += 1; combo_changed.emit(combo)
	if kind in ["coin", "crystal", "treasure"]: AudioManager.play_reward(kind != "coin")


func _finish() -> void:
	if result_sent or session.is_empty(): return
	result_sent = true
	_set_state(LaunchState.RESULT)
	if projectile: projectile.velocity = Vector3.ZERO; _animate_result_pose()
	var submission := {"session_id": session.get("session_id", "attack-%s-%d" % [session.get("id", "local"), shot_number]),
		"angle": angle, "power": power, "ability_time": ability_time,
		"events": events.duplicate(true), "checksum": str(hash(JSON.stringify(events)))}
	session = {}
	await get_tree().create_timer(0.55).timeout
	finished.emit(submission)


func _animate_result_pose() -> void:
	if projectile_visual == null: return
	var reward_count := 0
	for event in events:
		if event.get("type", "") in ["coin", "crystal", "treasure"]: reward_count += 1
	var tween := create_tween()
	if reward_count >= 3:
		tween.tween_property(projectile_visual, "scale", Vector3(1.25, 0.78, 1), 0.12)
		tween.tween_property(projectile_visual, "scale", Vector3(0.82, 1.35, 1), 0.18).set_trans(Tween.TRANS_BACK)
		tween.tween_property(projectile_visual, "rotation_degrees:z", 360.0, 0.45)
	else:
		tween.tween_property(projectile_visual, "rotation_degrees:z", -18.0, 0.18)
		tween.tween_property(projectile_visual, "position:y", -0.18, 0.25).set_trans(Tween.TRANS_BOUNCE)


func _recoil_cannon() -> void:
	var direction := Vector3(_direction().x, _direction().y, 0)
	var original := cannon_barrel.position
	var tween := create_tween()
	tween.tween_property(cannon_barrel, "position", original - direction * 0.32, 0.055)
	tween.tween_property(cannon_barrel, "position", original, 0.22).set_trans(Tween.TRANS_BACK)


func _camera_kick(amount: float) -> void: camera_shake = maxf(camera_shake, amount)


func _update_camera(delta: float) -> void:
	if camera == null: return
	if camera_shake > 0.002:
		camera.position = camera_base + Vector3(random.randf_range(-camera_shake, camera_shake), random.randf_range(-camera_shake, camera_shake), 0)
		camera_shake = lerpf(camera_shake, 0.0, minf(1.0, delta * 11.0))
	else: camera.position = camera.position.lerp(camera_base, minf(1.0, delta * 9.0))


func _deform_bouncer() -> void:
	if projectile_visual == null: return
	var tween := create_tween()
	tween.tween_property(projectile_visual, "scale", Vector3(1.42, 0.62, 1), 0.05)
	tween.tween_property(projectile_visual, "scale", Vector3(0.88, 1.18, 1), 0.09)
	tween.tween_property(projectile_visual, "scale", Vector3.ONE, 0.13).set_trans(Tween.TRANS_ELASTIC)


func _spawn_trail_segment() -> void:
	if projectile == null or projectile.position.distance_to(last_trail_position) < 0.23: return
	last_trail_position = projectile.position
	var segment := _take_effect(mats.crystal_violet, projectile.position, Vector3.ONE * 1.35)
	var tween := create_tween().set_parallel()
	tween.tween_property(segment, "scale", Vector3.ZERO, 0.52)
	tween.tween_property(segment, "position:z", -0.4, 0.52)
	tween.chain().tween_callback(_release_effect.bind(segment))


func _spawn_burst(pos: Vector3, material: Material, amount: int, radius: float) -> void:
	for i in range(mini(amount, 32)):
		var particle := _take_effect(material, pos, Vector3.ONE * random.randf_range(0.4, 0.75))
		var direction := Vector3(random.randf_range(-1, 1), random.randf_range(-0.4, 1), random.randf_range(-0.7, 0.7)).normalized()
		var tween := create_tween().set_parallel()
		tween.tween_property(particle, "position", pos + direction * random.randf_range(radius * 0.45, radius), random.randf_range(0.3, 0.62)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "scale", Vector3.ZERO, 0.58).set_delay(0.08)
		tween.chain().tween_callback(_release_effect.bind(particle))


func _prewarm_effect_pool() -> void:
	for i in range(64):
		var sphere := SphereMesh.new(); sphere.radius = 0.08; sphere.height = 0.16
		var particle := _mesh(self, sphere, mats.crystal_violet)
		particle.name = "PooledEffect%02d" % i
		particle.visible = false
		particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		effect_pool.append(particle)


func _take_effect(material: Material, pos: Vector3, effect_scale: Vector3) -> MeshInstance3D:
	for particle in effect_pool:
		if not particle.visible:
			particle.visible = true
			particle.position = pos
			particle.scale = effect_scale
			particle.mesh.material = material
			return particle
	var sphere := SphereMesh.new(); sphere.radius = 0.08; sphere.height = 0.16
	var fallback := _mesh(self, sphere, material, pos, effect_scale)
	fallback.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effect_pool.append(fallback)
	return fallback


func _release_effect(particle: MeshInstance3D) -> void:
	if is_instance_valid(particle):
		particle.visible = false
		particle.scale = Vector3.ONE


func _add_aether_boundaries() -> void:
	var barrier_mat := _material(Color(0.42, 0.9, 1.0, 0.14), 0.25, 0.0, Color("56dfff"), 1.2)
	barrier_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for data in [
		[Vector3(-5.38, 0.0, -0.2), Vector3(0.22, 18.0, 1.8), "LeftAetherCurrent"],
		[Vector3(5.38, 0.0, -0.2), Vector3(0.22, 18.0, 1.8), "RightAetherCurrent"],
		[Vector3(0.0, 8.75, -0.2), Vector3(10.8, 0.22, 1.8), "UpperAetherCurrent"],
		[Vector3(0.0, -8.35, -0.2), Vector3(10.8, 0.22, 1.8), "LowerAetherCurrent"],
	]:
		var body := StaticBody3D.new()
		body.name = data[2]
		body.position = data[0]
		body.collision_layer = 1
		add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = data[1]
		collision.shape = shape
		body.add_child(collision)
		_mesh(body, _box_mesh(data[1]), barrier_mat)


func _add_platform(pos: Vector3, size: Vector3, rotation_z: float) -> void:
	var body := StaticBody3D.new(); body.name = "RunePlatform"; body.position = pos; body.rotation_degrees.z = rotation_z
	body.collision_layer = 1; body.collision_mask = 2; add_child(body)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; collision.shape = shape; body.add_child(collision)
	_mesh(body, _box_mesh(size), mats.stone)
	_mesh(body, _box_mesh(Vector3(size.x * 1.03, 0.12, size.z * 1.04)), mats.grass_light, Vector3(0, size.y * 0.55, 0))
	for x in [-size.x * 0.33, size.x * 0.24]:
		_mesh(body, _box_mesh(Vector3(size.x * 0.18, 0.52, size.z * 0.78)), mats.stone_dark, Vector3(x, -0.38, 0), Vector3.ONE, Vector3(0, 0, random.randf_range(-12, 12)))


func _add_mushroom(pos: Vector3) -> void:
	var body := StaticBody3D.new(); body.name = "SpringMushroom"; body.position = pos; body.set_meta("mushroom", true); body.collision_layer = 1; add_child(body)
	var collision := CollisionShape3D.new(); var shape := SphereShape3D.new(); shape.radius = 0.5; collision.shape = shape; collision.position.y = 0.35; body.add_child(collision)
	var stem := _cylinder_mesh(0.22, 0.65, 10); stem.top_radius = 0.18
	_mesh(body, stem, mats.white)
	var cap := SphereMesh.new(); cap.radius = 0.58; cap.height = 1.0
	_mesh(body, cap, mats.mushroom, Vector3(0, 0.48, 0), Vector3(1, 0.48, 1))


func _animate_mushroom(body: Node3D) -> void:
	var tween := create_tween()
	tween.tween_property(body, "scale", Vector3(1.22, 0.55, 1.22), 0.07)
	tween.tween_property(body, "scale", Vector3(0.88, 1.28, 0.88), 0.11).set_trans(Tween.TRANS_BACK)
	tween.tween_property(body, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_ELASTIC)


func _add_portal_pair(a_pos: Vector3, b_pos: Vector3) -> void:
	var a := _create_portal(a_pos, Color("65e9ff")); var b := _create_portal(b_pos, Color("b76cff"))
	portal_pairs.append({"a": a, "b": b, "phase": random.randf_range(0, TAU)})


func _create_portal(pos: Vector3, color: Color) -> Node3D:
	var root := Node3D.new(); root.name = "ArcanePortal"; root.position = pos; add_child(root)
	var portal_mat := _material(color, 0.2, 0.35, color, 2.7)
	var ring := TorusMesh.new(); ring.inner_radius = 0.54; ring.outer_radius = 0.78; ring.rings = 16; ring.ring_segments = 12
	_mesh(root, ring, portal_mat, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
	var core_mat := _material(Color(color, 0.36), 0.2, 0, color, 1.8); core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh(root, _cylinder_mesh(0.5, 0.05, 24), core_mat, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
	return root


func _add_booster(pos: Vector3, direction: Vector3) -> void:
	var root := Node3D.new(); root.name = "SkyBooster"; root.position = pos; root.rotation.z = atan2(direction.y, direction.x); add_child(root)
	for x in [-0.35, 0.0, 0.35]:
		var prism := PrismMesh.new(); prism.size = Vector3(0.48, 0.12, 0.38)
		_mesh(root, prism, mats.booster, Vector3(x, 0, 0), Vector3.ONE, Vector3(0, 0, -90))
	boosters.append({"node": root, "direction": direction.normalized(), "used": false})


func _add_moving_obstacle(pos: Vector3) -> void:
	var body := AnimatableBody3D.new(); body.name = "ClockworkSpinner"; body.position = pos; body.collision_layer = 1; add_child(body)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = Vector3(2.55, 0.25, 0.45); collision.shape = shape; body.add_child(collision)
	_mesh(body, _box_mesh(shape.size), mats.danger)
	_mesh(body, _cylinder_mesh(0.38, 0.35, 16), mats.brass, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
	moving_obstacles.append({"body": body, "origin": pos, "phase": random.randf_range(0, TAU)})


func _add_destructible(pos: Vector3) -> void:
	var body := StaticBody3D.new(); body.name = "CrystalCargo"; body.position = pos; body.collision_layer = 1; body.set_meta("destructible", true); add_child(body)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = Vector3(0.82, 0.82, 0.82); collision.shape = shape; body.add_child(collision)
	_mesh(body, _box_mesh(shape.size), mats.wood)
	_mesh(body, _box_mesh(Vector3(0.9, 0.14, 0.9)), mats.brass)
	_mesh(body, _box_mesh(Vector3(0.14, 0.9, 0.9)), mats.brass)


func _break_destructible(body: Node3D) -> void:
	if not is_instance_valid(body) or body.get_meta("broken", false): return
	body.set_meta("broken", true)
	_record("destructible", body.name, 0, body.position, projectile.velocity.length())
	_spawn_burst(body.position, mats.wood, 24, 1.0); _spawn_burst(body.position, mats.brass, 12, 0.72)
	var tween := create_tween().set_parallel()
	tween.tween_property(body, "rotation_degrees:z", body.rotation_degrees.z + 145, 0.38).set_trans(Tween.TRANS_BACK)
	tween.tween_property(body, "position:y", body.position.y - 0.8, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(body, "scale", Vector3.ZERO, 0.34).set_delay(0.12)
	tween.chain().tween_callback(body.queue_free)


func _add_collectible(pos: Vector3, kind: String, value: int) -> void:
	var root := Node3D.new(); root.name = "%s_%02d" % [kind.capitalize(), collectibles.size()]; root.position = pos; add_child(root)
	if kind == "coin":
		_mesh(root, _cylinder_mesh(0.25, 0.08, 16), mats.coin, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
		_mesh(root, _cylinder_mesh(0.13, 0.1, 12), mats.white, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
	elif kind == "crystal": _add_crystal_cluster(root, Vector3.ZERO, 0.52)
	else: _create_chest(root)
	collectibles.append({"node": root, "origin": pos, "kind": kind, "value": value, "radius": 0.48 if kind == "coin" else 0.68, "collected": false, "phase": random.randf_range(0, TAU)})


func _create_chest(parent: Node3D) -> void:
	_mesh(parent, _box_mesh(Vector3(0.9, 0.55, 0.65)), mats.wood, Vector3(0, -0.08, 0))
	_mesh(parent, _box_mesh(Vector3(0.98, 0.12, 0.72)), mats.brass, Vector3(0, 0.08, 0))
	_mesh(parent, _box_mesh(Vector3(0.14, 0.62, 0.72)), mats.brass)
	_mesh(parent, _box_mesh(Vector3(0.18, 0.22, 0.08)), mats.coin, Vector3(0, -0.02, 0.38))


func _add_crystal_cluster(parent: Node3D, pos: Vector3, scale_value: float) -> void:
	for data in [[Vector3.ZERO, 0.75, 0.0], [Vector3(-0.28, -0.08, 0.08), 0.52, -18.0], [Vector3(0.28, -0.06, -0.05), 0.48, 20.0]]:
		var crystal := _cylinder_mesh(0.2, data[1], 6); crystal.top_radius = 0.03
		_mesh(parent, crystal, mats.crystal_violet, pos + data[0], Vector3.ONE * scale_value, Vector3(0, 0, data[2]))


func _create_bouncer() -> Node3D:
	var root := Node3D.new(); root.name = "BouncerVisual"
	var body := SphereMesh.new(); body.radius = 0.38; body.height = 0.76
	_mesh(root, body, mats.bouncer, Vector3.ZERO, Vector3(1.05, 1, 0.9))
	for x in [-0.14, 0.14]:
		var eye := SphereMesh.new(); eye.radius = 0.105; eye.height = 0.21
		_mesh(root, eye, mats.white, Vector3(x, 0.08, 0.32), Vector3(0.82, 1, 0.55))
		var pupil := SphereMesh.new(); pupil.radius = 0.052; pupil.height = 0.104
		_mesh(root, pupil, mats.ink, Vector3(x + 0.012, 0.07, 0.405), Vector3(0.72, 1, 0.45))
	var mouth := TorusMesh.new(); mouth.inner_radius = 0.07; mouth.outer_radius = 0.105; mouth.rings = 10; mouth.ring_segments = 8
	_mesh(root, mouth, mats.ink, Vector3(0, -0.13, 0.35), Vector3(1, 0.55, 1), Vector3(90, 0, 0))
	for crown_x in [-0.16, 0.0, 0.16]:
		var crown := _cylinder_mesh(0.08, 0.28 if crown_x == 0.0 else 0.2, 6); crown.top_radius = 0.015
		_mesh(root, crown, mats.coin, Vector3(crown_x, 0.41, 0), Vector3.ONE, Vector3(0, 0, crown_x * -45))
	return root


func _mesh(parent: Node, primitive: PrimitiveMesh, material: Material, pos := Vector3.ZERO, mesh_scale := Vector3.ONE, rotation := Vector3.ZERO) -> MeshInstance3D:
	primitive.material = material
	var instance := MeshInstance3D.new(); instance.mesh = primitive; instance.position = pos; instance.scale = mesh_scale; instance.rotation_degrees = rotation; parent.add_child(instance)
	return instance


func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new(); mesh.size = size; return mesh


func _cylinder_mesh(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height; mesh.radial_segments = segments; return mesh


## Test hooks use the exact same state machine and validation as touch/mouse input.
func debug_begin_gesture(pos: Vector2) -> bool:
	if launch_state != LaunchState.READY or not _is_on_cannon(pos): return false
	active_pointer_id = 99; gesture_start = pos; _set_state(LaunchState.AIMING); return true


func debug_drag_gesture(pos: Vector2) -> void:
	if launch_state == LaunchState.AIMING: _update_gesture(pos)


func debug_release_gesture() -> void:
	if launch_state != LaunchState.AIMING: return
	active_pointer_id = -999
	if gesture_distance < DEADZONE_PX: _cancel_aim()
	else: _fire()
