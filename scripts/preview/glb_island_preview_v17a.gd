extends Node3D

## Phase 17A preview — one production GLB island at real gameplay scale.
## Does not modify island_hopping_world.gd or live route logic.

const SOURCE_RADIUS := 12.8
const FLOOR_OFFSET := 0.84
const CANNON_OFFSET := Vector3(0.0, 0.92, -2.2)
const PLAYER_OFFSET := Vector3(-2.0, FLOOR_OFFSET, 2.0)
const AIM_CAMERA_OFFSET := Vector3(0.0, 3.25, 0.0)
const AIM_CAMERA_BACK := 6.4

var island: Node3D
var camera: Camera3D
var orbit_yaw := 24.0
var orbit_pitch := 20.0


func _ready() -> void:
	_build_environment()
	_build_island()
	_build_reference_markers()
	_build_player_reference()
	_build_cannon_reference()
	_position_preview_camera("orbit")
	print("LOOT LAUNCH Phase 17A preview ready. Keys: 1=orbit 2=aim 3=flight 4=wide")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_position_preview_camera("orbit")
			KEY_2:
				_position_preview_camera("aim")
			KEY_3:
				_position_preview_camera("flight")
			KEY_4:
				_position_preview_camera("wide")
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		orbit_yaw += event.relative.x * 0.35
		orbit_pitch = clampf(orbit_pitch - event.relative.y * 0.28, 8.0, 55.0)
		if camera:
			_position_preview_camera("orbit")


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
	environment.glow_intensity = 0.52
	environment.fog_enabled = true
	environment.fog_light_color = Color("c9ddf5")
	environment.fog_density = 0.0017
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	sun.light_color = Color("fff0d0")
	sun.light_energy = 0.94
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 46.0
	add_child(sun)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.0, 5.0, -9.0)
	rim.light_color = Color("9274ff")
	rim.light_energy = 1.35
	rim.omni_range = 17.0
	add_child(rim)
	camera = Camera3D.new()
	camera.name = "PreviewCamera"
	camera.fov = 61.0
	camera.near = 0.08
	camera.far = 340.0
	camera.current = true
	add_child(camera)


func _build_island() -> void:
	var IslandScript = load("res://scripts/environment/floating_island_base01.gd")
	island = IslandScript.new()
	island.name = "FloatingIslandBase01"
	add_child(island)
	await island.island_built
	if island.load_errors.size() > 0:
		push_warning("GLB preview load issues: %s" % ", ".join(island.load_errors))


func _build_reference_markers() -> void:
	var gameplay_radius: float = island.gameplay_radius if island else SOURCE_RADIUS * 0.91
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = gameplay_radius - 0.12
	ring_mesh.outer_radius = gameplay_radius
	ring_mesh.rings = 48
	ring_mesh.ring_segments = 4
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color("45d8aa", 0.55)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ring := MeshInstance3D.new()
	ring.name = "GameplayRadiusGuide"
	ring.mesh = ring_mesh
	ring.material_override = ring_mat
	ring.position.y = 0.06
	add_child(ring)
	var label_root := Node3D.new()
	label_root.name = "ScaleReferences"
	add_child(label_root)
	_add_marker(label_root, "IslandOrigin", Vector3.ZERO, Color.WHITE)
	_add_marker(label_root, "CannonPivotRef", CANNON_OFFSET, Color("ffc94f"))
	_add_marker(label_root, "PlayerSpawnRef", PLAYER_OFFSET, Color("7651e8"))


func _add_marker(parent: Node3D, marker_name: String, pos: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = marker_name
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	marker.mesh = sphere
	marker.material_override = mat
	marker.position = pos + Vector3(0.0, 0.12, 0.0)
	parent.add_child(marker)


func _build_player_reference() -> void:
	var lootling := Node3D.new()
	lootling.name = "LootlingScaleReference"
	lootling.position = PLAYER_OFFSET
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.66
	body_mesh.height = 1.25
	body.mesh = body_mesh
	body.material_override = _preview_material(Color("88d46f"))
	body.scale = Vector3(1.0, 0.9, 0.92)
	lootling.add_child(body)
	var capsule := MeshInstance3D.new()
	var cap_mesh := CapsuleMesh.new()
	cap_mesh.radius = 0.46
	cap_mesh.height = 1.45
	capsule.mesh = cap_mesh
	capsule.material_override = _preview_material(Color("45d8aa", 0.18))
	capsule.position.y = 0.72
	lootling.add_child(capsule)
	add_child(lootling)


func _build_cannon_reference() -> void:
	var cannon := Node3D.new()
	cannon.name = "CannonScaleReference"
	cannon.position = CANNON_OFFSET
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.12
	base_mesh.bottom_radius = 1.28
	base_mesh.height = 0.58
	base.mesh = base_mesh
	base.material_override = _preview_material(Color("c9a35a"))
	base.position.y = -0.30
	cannon.add_child(base)
	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.42
	barrel_mesh.bottom_radius = 0.48
	barrel_mesh.height = 2.35
	barrel.mesh = barrel_mesh
	barrel.material_override = _preview_material(Color("7651e8"))
	barrel.position = Vector3(0.0, 0.55, -1.1)
	barrel.rotation_degrees.x = -18.0
	cannon.add_child(barrel)
	add_child(cannon)


func _preview_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	return mat


func _position_preview_camera(mode: String) -> void:
	if camera == null:
		return
	var cannon_pivot := CANNON_OFFSET + Vector3(0.0, 0.35, 0.0)
	match mode:
		"orbit":
			var yaw := deg_to_rad(orbit_yaw)
			var pitch := deg_to_rad(orbit_pitch)
			var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 8.2
			camera.global_position = PLAYER_OFFSET + offset + Vector3(0.0, 1.2, 0.0)
			camera.look_at(PLAYER_OFFSET + Vector3(0.0, 0.75, 0.0), Vector3.UP)
			camera.fov = 61.0
		"aim":
			var aim_dir := Vector3(0.0, 0.12, -1.0).normalized()
			var shoulder := aim_dir.cross(Vector3.UP).normalized()
			camera.global_position = cannon_pivot - Vector3(aim_dir.x, 0.0, aim_dir.z).normalized() * AIM_CAMERA_BACK + AIM_CAMERA_OFFSET + shoulder * 0.82
			camera.look_at(cannon_pivot + aim_dir * 25.0 + Vector3(0.0, 0.25, 0.0), Vector3.UP)
			camera.fov = 71.0
		"flight":
			camera.global_position = Vector3(0.0, 8.0, 14.0)
			camera.look_at(Vector3(0.0, 2.0, -34.0), Vector3.UP)
			camera.fov = 72.0
		"wide":
			camera.global_position = Vector3(0.0, 24.0, 34.0)
			camera.look_at(Vector3(0.0, 1.0, -8.0), Vector3.UP)
			camera.fov = 58.0
