extends Node3D

## Phase 17B production preview — floating island inspection with free-roam fly camera.

const ProductionAssetScript = preload("res://scripts/environment/production_asset.gd")
const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")
const CAMERA_PADDING := 1.35
const PITCH_MIN_RAD := -1.483529864195791
const PITCH_MAX_RAD := 1.483529864195791
const JOYSTICK_SIZE := Vector2(560.0, 475.0)

var _view_direction: Vector3 = Vector3(0.55, 0.38, 0.74).normalized()

var camera: Camera3D
var island_wrapper: Node3D
var debug_marker: MeshInstance3D
var reference_floor: MeshInstance3D
var inspection_ui: CanvasLayer
var move_joystick: Control
var look_zone: Control

var _last_world_bounds := AABB()
var _last_camera_position := Vector3.ZERO
var _framing_center := Vector3.ZERO
var _framing_position := Vector3.ZERO
var _framing_yaw := 0.0
var _framing_pitch := 0.0
var _framing_fov := 52.0
var _camera_yaw := 0.0
var _camera_pitch := 0.0
var _joystick_vector := Vector2.ZERO
var _keyboard_planar := Vector2.ZERO
var _keyboard_vertical := 0.0
var _move_speed := 14.0
var _look_sensitivity := 0.0032
var _mouse_look_active := false
var _look_pointer := -1
var _look_last_pos := Vector2.ZERO
var _debug_ui_visible := true
var _navigation_ready := false
var _pinch_base_fov := 52.0


func _ready() -> void:
	_build_environment()
	_build_floor()
	_build_inspection_ui()
	await _build_island()
	_apply_framing_camera()
	_navigation_ready = true
	print("Production preview v17B ready — touch free-roam enabled.")
	print("Preview camera bounds=", _last_world_bounds, " position=", _last_camera_position)


func _process(delta: float) -> void:
	if not _navigation_ready or camera == null:
		return
	_apply_camera_rotation()
	_apply_free_movement(delta)


func _input(event: InputEvent) -> void:
	if not _navigation_ready:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_apply_framing_camera()
				get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_move_speed = clampf(_move_speed + 1.5, 3.0, 42.0)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_move_speed = clampf(_move_speed - 1.5, 3.0, 42.0)
			get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		camera.fov = clampf(_pinch_base_fov / event.factor, 24.0, 78.0)
		get_viewport().set_input_as_handled()


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("3d82d6")
	sky_material.sky_horizon_color = Color("c8e6f5")
	sky_material.ground_horizon_color = Color("b9d9e8")
	sky_material.ground_bottom_color = Color("6d9ac1")
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c5eaff")
	environment.ambient_light_energy = 0.60
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.38
	environment.fog_enabled = true
	environment.fog_light_color = Color("c9ddf5")
	environment.fog_density = 0.0017
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	sun.light_color = Color("fff0d0")
	sun.light_energy = 0.94
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	camera.name = "PreviewCamera"
	camera.fov = 52.0
	camera.near = 0.05
	camera.far = 400.0
	camera.current = true
	add_child(camera)


func _build_floor() -> void:
	reference_floor = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(36.0, 28.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("1a2240", 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	reference_floor.mesh = plane
	reference_floor.material_override = mat
	reference_floor.position = Vector3(0.0, -0.02, -1.0)
	add_child(reference_floor)


func _build_inspection_ui() -> void:
	inspection_ui = $InspectionUI as CanvasLayer
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var left_zone := _make_screen_zone(
		"MoveZone",
		Vector2(0.0, 0.0),
		Vector2(viewport_size.x * 0.5, viewport_size.y)
	)
	inspection_ui.add_child(left_zone)
	move_joystick = VirtualJoystickScript.new() as Control
	move_joystick.name = "MoveJoystick"
	move_joystick.size = JOYSTICK_SIZE
	move_joystick.position = Vector2(
		24.0,
		viewport_size.y - JOYSTICK_SIZE.y - 140.0
	)
	move_joystick.vector_changed.connect(_on_joystick_vector_changed)
	left_zone.add_child(move_joystick)
	look_zone = _make_screen_zone(
		"LookZone",
		Vector2(viewport_size.x * 0.5, 0.0),
		Vector2(viewport_size.x * 0.5, viewport_size.y)
	)
	look_zone.gui_input.connect(_on_look_zone_gui_input)
	inspection_ui.add_child(look_zone)
	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.add_theme_constant_override("separation", 8)
	toolbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toolbar.offset_top = 18.0
	toolbar.offset_bottom = 62.0
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	inspection_ui.add_child(toolbar)
	toolbar.add_child(_make_tool_button("RESET", _on_reset_pressed))
	toolbar.add_child(_make_tool_button("OVERVIEW", _on_overview_pressed))
	toolbar.add_child(_make_tool_button("UI", _on_ui_toggle_pressed))
	toolbar.add_child(_make_tool_button("+", _on_zoom_in_pressed))
	toolbar.add_child(_make_tool_button("-", _on_zoom_out_pressed))


func _make_screen_zone(zone_name: String, origin: Vector2, zone_size: Vector2) -> Control:
	var zone := Control.new()
	zone.name = zone_name
	zone.position = origin
	zone.size = zone_size
	zone.mouse_filter = Control.MOUSE_FILTER_STOP
	return zone


func _make_tool_button(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(96.0, 40.0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


func _build_island() -> void:
	island_wrapper = ProductionAssetScript.new()
	island_wrapper.name = "FloatingIslandProduction"
	island_wrapper.configure_floating_island(12.8, 1.45, 2)
	add_child(island_wrapper)
	await island_wrapper.asset_ready


func _apply_framing_camera() -> void:
	if camera == null or island_wrapper == null:
		return
	_last_world_bounds = _compute_world_visual_bounds(island_wrapper)
	if _last_world_bounds.size == Vector3.ZERO:
		push_warning("Preview camera: no world-space mesh bounds found")
		return
	_framing_center = _last_world_bounds.get_center()
	var bounding_radius: float = _last_world_bounds.size.length() * 0.5
	var fov_rad: float = deg_to_rad(camera.fov)
	var distance: float = (bounding_radius / tan(fov_rad * 0.5)) * CAMERA_PADDING * 1.15
	var expanded_bounds: AABB = _last_world_bounds.grow(0.75)
	var camera_position: Vector3 = _framing_center + _view_direction * distance
	while expanded_bounds.has_point(camera_position):
		distance *= 1.15
		camera_position = _framing_center + _view_direction * distance
	camera.global_position = camera_position
	camera.look_at(_framing_center, Vector3.UP)
	_store_framing_state()
	_update_debug_marker(_framing_center)


func _store_framing_state() -> void:
	_last_camera_position = camera.global_position
	_framing_position = camera.global_position
	_framing_yaw = camera.rotation.y
	_framing_pitch = camera.rotation.x
	_framing_fov = camera.fov
	_camera_yaw = _framing_yaw
	_camera_pitch = _framing_pitch
	_pinch_base_fov = camera.fov


func _apply_camera_rotation() -> void:
	camera.rotation = Vector3(_camera_pitch, _camera_yaw, 0.0)


func _apply_free_movement(delta: float) -> void:
	_read_keyboard_input()
	var planar: Vector2 = _joystick_vector + _keyboard_planar
	if planar.length() > 1.0:
		planar = planar.normalized()
	var basis: Basis = camera.global_basis
	var move_direction: Vector3 = Vector3.ZERO
	move_direction += basis.x * planar.x
	move_direction += basis.z * planar.y
	move_direction.y += _keyboard_vertical
	if move_direction.length_squared() > 0.0001:
		move_direction = move_direction.normalized()
		camera.global_position += move_direction * _move_speed * delta


func _read_keyboard_input() -> void:
	_keyboard_planar = Vector2.ZERO
	_keyboard_vertical = 0.0
	if Input.is_key_pressed(KEY_D):
		_keyboard_planar.x += 1.0
	if Input.is_key_pressed(KEY_A):
		_keyboard_planar.x -= 1.0
	if Input.is_key_pressed(KEY_S):
		_keyboard_planar.y += 1.0
	if Input.is_key_pressed(KEY_W):
		_keyboard_planar.y -= 1.0
	if Input.is_key_pressed(KEY_E):
		_keyboard_vertical += 1.0
	if Input.is_key_pressed(KEY_Q):
		_keyboard_vertical -= 1.0


func _apply_look_delta(delta: Vector2) -> void:
	_camera_yaw -= delta.x * _look_sensitivity
	_camera_pitch -= delta.y * _look_sensitivity
	_camera_pitch = clampf(_camera_pitch, PITCH_MIN_RAD, PITCH_MAX_RAD)


func _on_joystick_vector_changed(value: Vector2) -> void:
	_joystick_vector = value


func _on_look_zone_gui_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pointer := -1
	var press := false
	var release := false
	var motion := false
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		pos = touch_event.position
		pointer = touch_event.index
		press = touch_event.pressed
		release = not touch_event.pressed
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		pos = drag_event.position
		pointer = drag_event.index
		motion = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		pos = mouse_event.position
		pointer = -1
		press = mouse_event.pressed
		release = not mouse_event.pressed
	elif event is InputEventMouseMotion and _mouse_look_active:
		var motion_event := event as InputEventMouseMotion
		_apply_look_delta(motion_event.relative)
		look_zone.accept_event()
		return
	else:
		return
	if press and _look_pointer == -1:
		_look_pointer = pointer
		_look_last_pos = pos
		_mouse_look_active = pointer == -1
		_pinch_base_fov = camera.fov
		look_zone.accept_event()
	elif pointer == _look_pointer and motion:
		var drag_delta: Vector2 = pos - _look_last_pos
		_look_last_pos = pos
		_apply_look_delta(drag_delta)
		look_zone.accept_event()
	elif pointer == _look_pointer and release:
		_look_pointer = -1
		_mouse_look_active = false
		look_zone.accept_event()


func _on_reset_pressed() -> void:
	camera.global_position = _framing_position
	_camera_yaw = _framing_yaw
	_camera_pitch = _framing_pitch
	camera.fov = _framing_fov
	_pinch_base_fov = _framing_fov
	_apply_camera_rotation()


func _on_overview_pressed() -> void:
	_apply_framing_camera()


func _on_ui_toggle_pressed() -> void:
	_debug_ui_visible = not _debug_ui_visible
	if debug_marker:
		debug_marker.visible = _debug_ui_visible
	if reference_floor:
		reference_floor.visible = _debug_ui_visible


func _on_zoom_in_pressed() -> void:
	camera.fov = clampf(camera.fov - 4.0, 24.0, 78.0)
	_pinch_base_fov = camera.fov


func _on_zoom_out_pressed() -> void:
	camera.fov = clampf(camera.fov + 4.0, 24.0, 78.0)
	_pinch_base_fov = camera.fov


func _compute_world_visual_bounds(root: Node3D) -> AABB:
	var production_root := root as ProductionAssetScript
	var search_root: Node = production_root.visual_root if production_root and production_root.visual_root else root
	return _merge_world_mesh_bounds(search_root)


func _merge_world_mesh_bounds(node: Node) -> AABB:
	var merged := AABB()
	var has_box := false
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh:
			var world_aabb: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
			merged = world_aabb
			has_box = true
	for child in node.get_children():
		var child_box: AABB = _merge_world_mesh_bounds(child)
		if child_box.size != Vector3.ZERO:
			merged = child_box if not has_box else merged.merge(child_box)
			has_box = true
	return merged if has_box else AABB()


func _update_debug_marker(center: Vector3) -> void:
	if debug_marker == null:
		debug_marker = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("45d8aa")
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_marker.mesh = sphere
		debug_marker.material_override = mat
		add_child(debug_marker)
	var marker_position: Vector3 = Vector3(
		center.x,
		_last_world_bounds.position.y + _last_world_bounds.size.y + 0.45,
		center.z
	)
	debug_marker.global_position = marker_position
	debug_marker.visible = _debug_ui_visible
