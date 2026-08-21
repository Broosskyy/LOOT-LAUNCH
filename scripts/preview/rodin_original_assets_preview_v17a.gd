extends Node3D

## Side-by-side validation of three original Rodin PBR GLBs + broken optimized island reference.
## Keys: 1=Overview 2=Asset1 3=Asset2 4=Asset3

const WRAPPER := preload("res://scripts/environment/rodin_original_asset_wrapper.gd")
const BROKEN_LOD0 := "res://art/models/_deprecated/broken_external_lods/floating_island_base01/LL_FloatingIsland_Base01_LOD0.glb"

const ASSET_LAYOUT := [
	{
		"id": "asset_01",
		"label": "Asset 1 — Tall Form",
		"uuid": "b34fdb36-0c60-404c-880b-96ece5489eaf",
		"path": "res://art/models/production/asset_01/base_basic_pbr.glb",
		"position": Vector3(-16.0, 0.0, 0.0),
	},
	{
		"id": "asset_02_floating_island",
		"label": "Asset 2 — Floating Island (Original Rodin)",
		"uuid": "9257e8e6-b152-4209-8ea3-050df63f1c99",
		"path": "res://art/models/production/asset_02_floating_island/base_basic_pbr.glb",
		"position": Vector3(0.0, 0.0, 0.0),
	},
	{
		"id": "asset_03",
		"label": "Asset 3 — Compact Form",
		"uuid": "9bdd279c-f1d8-4c8a-9b3a-2e49729ac6d1",
		"path": "res://art/models/production/asset_03/base_basic_pbr.glb",
		"position": Vector3(16.0, 0.0, 0.0),
	},
]

var camera: Camera3D
var wrappers: Array = []
var reports: Array = []


func _ready() -> void:
	_build_environment()
	_build_reference_floor()
	await _build_assets()
	_build_broken_reference()
	_position_camera("overview")
	_print_summary()
	print("Rodin original preview ready. Keys: 1=Overview 2=Asset1 3=Asset2 4=Asset3")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_position_camera("overview")
			KEY_2:
				_position_camera("asset_1")
			KEY_3:
				_position_camera("asset_2")
			KEY_4:
				_position_camera("asset_3")


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
	camera.name = "ValidationCamera"
	camera.fov = 58.0
	camera.near = 0.05
	camera.far = 400.0
	camera.current = true
	add_child(camera)


func _build_reference_floor() -> void:
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(64.0, 36.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("1a2240", 0.35)
	floor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var floor := MeshInstance3D.new()
	floor.name = "ReferenceFloor"
	floor.mesh = floor_mesh
	floor.material_override = floor_mat
	floor.position = Vector3(0.0, -0.02, -2.0)
	add_child(floor)


func _build_assets() -> void:
	for layout in ASSET_LAYOUT:
		var wrapper: Node3D = WRAPPER.new()
		wrapper.name = layout.id
		wrapper.pbr_glb_path = layout.path
		wrapper.asset_id = layout.id
		wrapper.asset_label = layout.label
		wrapper.rodin_uuid = layout.uuid
		wrapper.position = layout.position
		add_child(wrapper)
		wrappers.append(wrapper)
		await wrapper.asset_ready
		reports.append(wrapper.inspection_report)
		_add_marker(layout.position + Vector3(0.0, 2.2, 0.0), layout.label, _marker_color(layout.id))


func _build_broken_reference() -> void:
	if not ResourceLoader.exists(BROKEN_LOD0):
		push_warning("Broken optimized LOD0 missing for comparison: %s" % BROKEN_LOD0)
		return
	var packed: PackedScene = load(BROKEN_LOD0) as PackedScene
	if packed == null:
		return
	var broken: Node3D = packed.instantiate() as Node3D
	broken.name = "BrokenOptimizedReference"
	broken.position = Vector3(0.0, 0.0, -10.0)
	broken.scale = Vector3.ONE
	add_child(broken)
	_add_marker(Vector3(0.0, 2.2, -10.0), "Broken Optimized LOD0 (external decimation)", Color("e95468"))


func _add_marker(pos: Vector3, label: String, color: Color) -> void:
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.mesh = sphere
	marker.material_override = mat
	marker.position = pos
	add_child(marker)
	print(label, " @ ", pos)


func _marker_color(asset_id: String) -> Color:
	match asset_id:
		"asset_01":
			return Color("7651e8")
		"asset_02_floating_island":
			return Color("45d8aa")
		_:
			return Color("ffc94f")


func _position_camera(mode: String) -> void:
	if camera == null:
		return
	match mode:
		"overview":
			camera.global_position = Vector3(0.0, 7.5, 34.0)
			camera.look_at(Vector3(0.0, 0.8, -2.0), Vector3.UP)
			camera.fov = 58.0
		"asset_1":
			_focus_wrapper(0)
		"asset_2":
			_focus_wrapper(1)
		"asset_3":
			_focus_wrapper(2)


func _focus_wrapper(index: int) -> void:
	if index < 0 or index >= wrappers.size():
		return
	var wrapper: Node3D = wrappers[index]
	var target := wrapper.global_position + wrapper.get_bounds_center() + Vector3(0.0, 0.35, 0.0)
	camera.global_position = wrapper.get_safe_camera_position(target, 3.0, 1.6)
	camera.look_at(target, Vector3.UP)
	camera.fov = 52.0


func _print_summary() -> void:
	for report in reports:
		print("Rodin validation ", report.get("asset_id", "?"), " pbr_ok=", report.get("pbr_slots_ok", false),
			" bounds=", report.get("bounds_min", Vector3.ZERO), " -> ", report.get("bounds_max", Vector3.ZERO),
			" errors=", report.get("load_errors", []))
