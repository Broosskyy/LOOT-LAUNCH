extends Node3D

## Phase 17B production preview — floating island only (Phase 17B.1 import hotfix).
## Original Rodin 120k compare assets live outside res://; see docs/PHASE_17B1_GODOT_IMPORT_HOTFIX.md.

const ProductionAsset = preload("res://scripts/environment/production_asset.gd")

var camera: Camera3D
var island_wrapper: Node3D


func _ready() -> void:
	_build_environment()
	_build_floor()
	await _build_island()
	_position_camera()
	print("Production preview v17B ready (island only). Key 1 = reset camera.")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		_position_camera()


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
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(36.0, 28.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("1a2240", 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor.mesh = plane
	floor.material_override = mat
	floor.position = Vector3(0.0, -0.02, -1.0)
	add_child(floor)


func _build_island() -> void:
	island_wrapper = ProductionAsset.new()
	island_wrapper.name = "FloatingIslandProduction"
	island_wrapper.configure_floating_island(12.8, 1.45, 2)
	add_child(island_wrapper)
	await island_wrapper.asset_ready
	_add_label(Vector3(0.0, 2.4, 0.0), "Floating Island — Production LOD0/1/2")


func _add_label(pos: Vector3, text: String) -> void:
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("45d8aa")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.mesh = sphere
	marker.material_override = mat
	marker.position = pos
	add_child(marker)
	print(text, " @ ", pos)


func _position_camera() -> void:
	if camera == null or island_wrapper == null:
		return
	var target := island_wrapper.global_position + island_wrapper.get_bounds_center() + Vector3(0.0, 0.35, 0.0)
	camera.global_position = island_wrapper.get_safe_camera_position(target, 3.2, 1.8)
	camera.look_at(target, Vector3.UP)
