extends Node3D

## Phase 17B production asset preview with original vs optimized comparison.

const ProductionAsset = preload("res://scripts/environment/production_asset.gd")
const RodinWrapper = preload("res://scripts/environment/rodin_original_asset_wrapper.gd")

const SLOT_LAYOUT := [
	{
		"id": "asset_01",
		"label": "Asset 1 — Tall Form",
		"position": Vector3(-18.0, 0.0, 0.0),
		"production": {
			"lod0": "res://art/models/production/asset_01/game_ready/LOD0.glb",
			"lod1": "res://art/models/production/asset_01/game_ready/LOD1.glb",
			"lod2": "res://art/models/production/asset_01/game_ready/LOD2.glb",
			"emissive": "res://art/models/production/asset_01/texture_emissive.png",
			"original": "res://art/models/production/asset_01/base_basic_pbr.glb",
		},
	},
	{
		"id": "asset_02_floating_island",
		"label": "Floating Island",
		"position": Vector3(0.0, 0.0, 0.0),
		"production": {
			"lod0": "res://art/models/production/asset_02_floating_island/game_ready/LOD0.glb",
			"lod1": "res://art/models/production/asset_02_floating_island/game_ready/LOD1.glb",
			"lod2": "res://art/models/production/asset_02_floating_island/game_ready/LOD2.glb",
			"emissive": "res://art/models/production/asset_02_floating_island/texture_emissive.png",
			"original": "res://art/models/production/asset_02_floating_island/base_basic_pbr.glb",
		},
	},
	{
		"id": "asset_03",
		"label": "Asset 3 — Compact Form",
		"position": Vector3(18.0, 0.0, 0.0),
		"production": {
			"lod0": "res://art/models/production/asset_03/game_ready/LOD0.glb",
			"lod1": "res://art/models/production/asset_03/game_ready/LOD1.glb",
			"lod2": "res://art/models/production/asset_03/game_ready/LOD2.glb",
			"emissive": "res://art/models/production/asset_03/texture_emissive.png",
			"original": "res://art/models/production/asset_03/base_basic_pbr.glb",
		},
	},
]

var camera: Camera3D
var production_wrappers: Array = []
var compare_mode := false


func _ready() -> void:
	_build_environment()
	_build_floor()
	await _build_slots()
	_position_camera("overview")
	print("Production preview v17B ready. Keys: 1=Overview 2=Asset1 3=FloatingIsland 4=Asset3  C=Compare toggle")


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
			KEY_C:
				compare_mode = not compare_mode
				_apply_compare_mode()


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
	camera.fov = 58.0
	camera.near = 0.05
	camera.far = 400.0
	camera.current = true
	add_child(camera)


func _build_floor() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(72.0, 28.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("1a2240", 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor.mesh = plane
	floor.material_override = mat
	floor.position = Vector3(0.0, -0.02, -1.0)
	add_child(floor)


func _build_slots() -> void:
	for layout in SLOT_LAYOUT:
		var slot := Node3D.new()
		slot.name = layout.id
		slot.position = layout.position
		add_child(slot)
		var production := ProductionAsset.new()
		production.name = "ProductionVisual"
		if layout.id == "asset_02_floating_island":
			production.configure_floating_island(12.8, 1.45, 2)
		else:
			production.asset_key = layout.id
			production.asset_label = layout.label
			production.lod0_path = layout.production.lod0
			production.lod1_path = layout.production.lod1
			production.lod2_path = layout.production.lod2
			production.emission_texture_path = layout.production.emissive
			production.emission_energy = 0.42
			production.visual_scale = 1.0
			production.enable_gameplay_collision = false
		slot.add_child(production)
		await production.asset_ready
		production_wrappers.append(production)
		var original := RodinWrapper.new()
		original.name = "OriginalReference"
		original.pbr_glb_path = layout.production.original
		original.asset_id = layout.id + "_original"
		original.asset_label = layout.label + " Original"
		original.position = Vector3(0.0, 0.0, -5.5)
		original.visible = false
		slot.add_child(original)
		_add_label(layout.position + Vector3(0.0, 2.4, 0.0), layout.label)


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


func _apply_compare_mode() -> void:
	for slot in get_children():
		if not slot is Node3D:
			continue
		var production: Node = slot.get_node_or_null("ProductionVisual")
		var original: Node = slot.get_node_or_null("OriginalReference")
		if production:
			production.visible = not compare_mode
		if original:
			original.visible = compare_mode
	print("Compare mode: ", "ORIGINAL" if compare_mode else "PRODUCTION")


func _position_camera(mode: String) -> void:
	if camera == null:
		return
	match mode:
		"overview":
			camera.global_position = Vector3(0.0, 8.0, 36.0)
			camera.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)
			camera.fov = 58.0
		"asset_1":
			_focus_slot(0)
		"asset_2":
			_focus_slot(1)
		"asset_3":
			_focus_slot(2)


func _focus_slot(index: int) -> void:
	if index < 0 or index >= production_wrappers.size():
		return
	var wrapper: Node3D = production_wrappers[index]
	var target := wrapper.global_position + wrapper.get_bounds_center() + Vector3(0.0, 0.35, 0.0)
	camera.global_position = wrapper.get_safe_camera_position(target, 3.2, 1.8)
	camera.look_at(target, Vector3.UP)
	camera.fov = 52.0
