extends Node3D

## LOOT LAUNCH v16 — solid-island recovery and production-asset preparation.
## Visual simulation only. Wallets and final rewards remain backend-authoritative.

signal finished(submission: Dictionary)
signal combo_changed(value: int)
signal launched
signal aim_changed(angle: float, power: float)
signal loot_collected(kind: String, value: int, screen_position: Vector2)
signal state_changed(label: String)
signal action_prompt(text: String, enabled: bool)
signal instruction_changed(text: String)
signal flight_tally_changed(coins: int, crystals: int)
signal objective_changed(current: int, total: int, label: String)

enum HopState { ON_FOOT, ENTERING, AIMING, FLYING, LANDED, FAILED, RESULT }

const ROUTE_CENTERS := [
	Vector3(0.0, 0.0, 8.0),
	Vector3(1.0, 7.0, -34.0),
	Vector3(-14.0, 15.0, -77.0),
	Vector3(12.0, 23.0, -122.0),
	Vector3(-10.0, 31.0, -168.0),
	Vector3(8.0, 40.0, -215.0),
]
const ROUTE_RADII := [12.8, 12.0, 12.8, 13.2, 12.6, 14.8]
const CRYSTAL_ROUTE_CENTERS := [
	Vector3(0.0, 0.0, 8.0),
	Vector3(-8.0, 8.0, -35.0),
	Vector3(10.0, 17.0, -80.0),
	Vector3(-15.0, 27.0, -126.0),
	Vector3(8.0, 37.0, -173.0),
	Vector3(0.0, 49.0, -222.0),
]
const CRYSTAL_ROUTE_RADII := [13.5, 12.5, 13.0, 12.5, 13.5, 15.5]
const SOURCE_CENTER := Vector3(0.0, 0.0, 8.0)
const TARGET_CENTER := Vector3(1.0, 7.0, -34.0)
const DISTANT_CENTER := Vector3(-14.0, 15.0, -77.0)
const SOURCE_RADIUS := 12.8
const TARGET_RADIUS := 12.0
const FLOOR_OFFSET := 0.84
const GRAVITY := 9.4
const WALK_SPEED := 6.2
const JUMP_SPEED := 8.2
const WALK_GRAVITY := 21.0
const MAX_FLIGHT_TIME := 9.5
const AIM_DEADZONE := 34.0
const AIM_MAX_DRAG := 360.0
const MIN_PITCH := 18.0
const MAX_PITCH := 48.0
const USE_STYLIZED_V18 := true
const USE_PRODUCTION_ISLAND_0 := false
const ProductionAsset = preload("res://scripts/environment/production_asset.gd")
const StylizedMaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const StylizedLighting = preload("res://scripts/environment/stylized/stylized_lighting.gd")
const StylizedIslandGenerator = preload("res://scripts/environment/stylized/stylized_island_generator.gd")
const StylizedWorldDecorator = preload("res://scripts/environment/stylized/stylized_world_decorator.gd")
const StylizedCloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")
const StylizedPortalGenerator = preload("res://scripts/environment/stylized/stylized_portal_generator.gd")

var session: Dictionary = {}
var expedition_key := "wolkengarten"
var route_centers: Array = ROUTE_CENTERS.duplicate()
var route_radii: Array = ROUTE_RADII.duplicate()
var lootling_key := "bouncer"
var cannon_key := "standard"
var is_pvp := false
var shot_number := 0
var hop_state: HopState = HopState.ON_FOOT
var fired := false
var ability_used := false
var ability_uses := 0
var ability_charges := 1
var blasto_impact_used := false
var result_sent := false
var flight_time := 0.0
var ability_time := -1.0
var aim_yaw := 0.0
var base_aim_yaw := 0.0
var aim_pitch := 29.0
var aim_power := 0.64
var gesture_start := Vector2.ZERO
var gesture_last := Vector2.ZERO
var gesture_distance := 0.0
var charge_time := 0.0
var active_pointer := -999
var move_input := Vector2.ZERO
var keyboard_move := Vector2.ZERO
var events: Array = []
var sequence := 0
var combo := 0
var collected_coins := 0
var collected_crystals := 0
var chest_opened := false
var on_target_island := false
var current_island_index := 0
var opened_chests := {}
var jump_buffer := 0.0
var coyote_time := 0.12
var route_attempt := 1
var idle_time := 0.0
var shake_left := 0.0
var hit_stop_left := 0.0
var portal_cooldown := 0.0
var orbit_yaw := 0.0
var orbit_pitch := 20.0
var target_orbit_yaw := 0.0
var target_orbit_pitch := 20.0
var trail_timer := 0.0
var random := RandomNumberGenerator.new()
var quality_level := 2
var effect_density := 1.0
var landing_scores: Array[float] = []
var flight_right_input := 0.0
var trail_pool: Array = []
var spark_pool: Array = []
var trail_cursor := 0
var spark_cursor := 0
var performance_counters := {"trail_reuses": 0, "burst_reuses": 0, "peak_active_fx": 0}
var predicted_landing_valid := false
var predicted_landing_position := Vector3.ZERO
var objective_progress := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
var objective_requirements := {1: 2, 2: 3, 3: 2, 4: 3, 5: 3}
var objective_tokens: Array = []
var route_variant := 0
var boosters: Array = []
var moving_obstacles: Array = []
var airships: Array = []
var wind_streamers: Array = []

var camera: Camera3D
var sun: DirectionalLight3D
var player: CharacterBody3D
var player_visual: Node3D
var player_face: Node3D
var projectile: CharacterBody3D
var projectile_visual: Node3D
var cannon_root: Node3D
var cannon_pivot: Node3D
var loaded_lootling: Node3D
var muzzle_glow: MeshInstance3D
var target_chest: Node3D
var target_cannon: Node3D
var trajectory_root: Node3D
var landing_marker: MeshInstance3D
var flight_pickups: Array = []
var island_pickups: Array = []
var clouds: Array = []
var portal_pair: Array = []
var charge_rings: Array = []
var route_cannons: Array = []
var route_chests: Array = []
var aether_beacons: Array = []
var waterfalls: Array = []
var player_shadow: MeshInstance3D
var mats: Dictionary = {}


func begin(value: Dictionary, selected_lootling: String, selected_cannon: String, pvp := false, number := 0) -> void:
	session = value.duplicate(true)
	expedition_key = str(value.get("world_key", value.get("level_key", "wolkengarten")))
	if expedition_key in ["crystal_forge", "kristallschmiede_expedition_v1"]:
		expedition_key = "crystal_forge"
		route_centers = CRYSTAL_ROUTE_CENTERS.duplicate()
		route_radii = CRYSTAL_ROUTE_RADII.duplicate()
	else:
		expedition_key = "wolkengarten"
		route_centers = ROUTE_CENTERS.duplicate()
		route_radii = ROUTE_RADII.duplicate()
		if USE_STYLIZED_V18:
			route_radii[0] = 10.4
	lootling_key = selected_lootling
	cannon_key = selected_cannon
	ability_charges = 2 if cannon_key == "portal" else 1
	is_pvp = pvp
	shot_number = number
	quality_level = clampi(int(GameState.settings.get("quality", 2)), 0, 3)
	effect_density = [0.55, 0.78, 1.0, 1.22][quality_level]
	random.seed = int(value.get("seed", 7331)) + number * 97
	route_variant = abs(int(value.get("seed", 7331)) + number) % 3
	_build_materials()
	_build_environment()
	_build_sky_world()
	_build_fx_pool()
	_build_islands()
	_build_source_cannon()
	_build_player()
	_build_route()
	_build_target_contents()
	_build_trajectory()
	_set_state(HopState.ON_FOOT)
	if _uses_stylized_v18():
		call_deferred("_apply_stylized_start_camera")
	instruction_changed.emit(("KRISTALLSCHMIEDE" if expedition_key == "crystal_forge" else "WOLKENGARTEN") + "  •  ERKUNDE 6 INSELN  •  LAUFE ZUR KANONE")
	_update_action_prompt()
	if is_pvp:
		player.global_position = cannon_root.global_position + Vector3(-0.8, 0.0, 1.0)
		call_deferred("primary_action")


func _build_materials() -> void:
	mats = {
		"rock": _material(Color("4c5372"), 0.90, 0.0),
		"rock_mid": _material(Color("343b5a"), 0.94, 0.0),
		"rock_dark": _material(Color("20253f"), 0.97, 0.0),
		"cliff_warm": _material(Color("78614f"), 0.91, 0.0),
		"grass": _material(Color("43a968"), 0.84, 0.0),
		"grass_light": _material(Color("88d46f"), 0.76, 0.0),
		"grass_gold": _material(Color("b9d86a"), 0.78, 0.0),
		"grass_mint": _material(Color("55c995"), 0.76, 0.0),
		"grass_blue": _material(Color("52b9b5"), 0.73, 0.0),
		"grass_lilac": _material(Color("8f76cb"), 0.70, 0.0),
		"grass_amber": _material(Color("d0b45c"), 0.76, 0.0),
		"grass_royal": _material(Color("71c96d"), 0.72, 0.0),
		"edge_moss": _material(Color("267553"), 0.91, 0.0),
		"brass": _material(Color("dca64c"), 0.31, 0.75),
		"brass_light": _material(Color("ffd77a"), 0.24, 0.82, Color("ffbd3f"), 0.22),
		"bronze": _material(Color("8e5436"), 0.43, 0.62),
		"cannon": _material(Color("353458"), 0.29, 0.72),
		"violet": _material(Color("7750ee"), 0.30, 0.22, Color("6b39ff"), 2.0),
		"aether": _material(Color("69dbff"), 0.24, 0.12, Color("27c4ff"), 2.5),
		"coin": _material(Color("ffd44d"), 0.20, 0.72, Color("ffba20"), 1.1),
		"crystal": _material(Color("7ef0ff"), 0.14, 0.26, Color("35d6ff"), 2.7),
		"wood": _material(Color("87502f"), 0.82, 0.04),
		"wood_light": _material(Color("bd7541"), 0.76, 0.03),
		"red": _material(Color("ef5f70"), 0.46, 0.12, Color("b72f51"), 0.45),
		"success": _material(Color("62f0a5"), 0.34, 0.08, Color("25d57d"), 1.55),
		"objective": _material(Color("ff9ff3"), 0.22, 0.18, Color("f05cff"), 2.2),
		"booster": _material(Color("8dff72"), 0.22, 0.14, Color("42f56c"), 2.4),
		"white": _material(Color("fff5e1"), 0.72, 0.0),
		"ink": _material(Color("19203b"), 0.68, 0.0),
		"bouncer": _material(Color("5be1a8"), 0.46, 0.04, Color("2bb47e"), 0.42),
		"magneto": _material(Color("43cde0"), 0.38, 0.12, Color("2ebbd0"), 0.52),
		"blasto": _material(Color("ff775f"), 0.48, 0.06, Color("d94b3f"), 0.42),
		"blink": _material(Color("8968ff"), 0.32, 0.16, Color("6947df"), 0.76),
		"cloud": _transparent_material(Color(0.95, 0.98, 1.0, 0.64)),
		"water": _transparent_material(Color(0.28, 0.82, 1.0, 0.52)),
		"mushroom": _material(Color("f2667f"), 0.48, 0.04, Color("d94e79"), 0.24),
		"mushroom_spot": _material(Color("fff2c9"), 0.62, 0.0),
		"flower_pink": _material(Color("ff8cca"), 0.43, 0.0, Color("e34d9c"), 0.35),
		"cheek": _material(Color("ff86a8"), 0.54, 0.0),
	}
	if _uses_stylized_v18():
		StylizedMaterialLibrary.apply_palette(mats, Callable(self, "_material"), Callable(self, "_transparent_material"))
	elif expedition_key == "crystal_forge":
		mats.rock = _material(Color("394666"), 0.86, 0.04)
		mats.rock_mid = _material(Color("283653"), 0.90, 0.02)
		mats.rock_dark = _material(Color("17243d"), 0.94, 0.02)
		mats.cliff_warm = _material(Color("506080"), 0.87, 0.03)
		mats.edge_moss = _material(Color("176b73"), 0.80, 0.02, Color("165f70"), 0.16)
		mats.grass_light = _material(Color("4fd6c6"), 0.68, 0.02)
		mats.grass_mint = _material(Color("39beba"), 0.68, 0.03)
		mats.grass_blue = _material(Color("4599cc"), 0.64, 0.04)
		mats.grass_lilac = _material(Color("7768c8"), 0.63, 0.04)
		mats.grass_amber = _material(Color("bf79cf"), 0.63, 0.03)
		mats.grass_royal = _material(Color("5b8fe0"), 0.62, 0.04)
		mats.crystal = _material(Color("9af8ff"), 0.10, 0.34, Color("4de8ff"), 3.1)
		mats.objective = _material(Color("ff96ee"), 0.16, 0.22, Color("f14bd9"), 2.8)
		mats.violet = _material(Color("884fff"), 0.22, 0.30, Color("6932ff"), 2.5)
	_configure_solid_materials()


func _configure_solid_materials() -> void:
	# Mobile Compatibility can expose reversed procedural faces much more
	# aggressively than the editor. Every world surface is explicitly opaque;
	# the main island shell is rendered two-sided as a final safety net while its
	# generated mesh is also closed at the bottom below.
	var double_sided := [
		"rock", "rock_mid", "rock_dark", "cliff_warm", "grass", "grass_light",
		"grass_gold", "grass_mint", "grass_blue", "grass_lilac", "grass_amber",
		"grass_royal", "edge_moss", "grass_main", "grass_dark", "stone_main",
		"stone_dark", "stone_light", "dirt", "leaf_green", "distant_grass",
	]
	for key in mats.keys():
		var material := mats[key] as StandardMaterial3D
		if material == null or key in ["cloud", "water"]:
			continue
		material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		if _uses_stylized_v18() and key in [
			"stone_main", "stone_dark", "stone_light", "path_stone", "distant_rock", "brass", "wood", "wood_light", "cannon_dark"
		]:
			material.vertex_color_use_as_albedo = false
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			continue
		material.vertex_color_use_as_albedo = true
		if key in double_sided:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED


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


func _transparent_material(color: Color) -> StandardMaterial3D:
	var material := _material(color, 1.0, 0.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	# A real procedural sky covers every orbit direction. The old single quad
	# exposed the grey clear colour whenever the player turned sideways.
	var sky_material := ProceduralSkyMaterial.new()
	if not _uses_stylized_v18():
		sky_material.sky_top_color = Color("263c8f") if expedition_key == "crystal_forge" else Color("3d82d6")
		sky_material.sky_horizon_color = Color("b7b8f3") if expedition_key == "crystal_forge" else Color("c8e6f5")
		sky_material.ground_horizon_color = Color("8fcde3") if expedition_key == "crystal_forge" else Color("b9d9e8")
		sky_material.ground_bottom_color = Color("394f89") if expedition_key == "crystal_forge" else Color("6d9ac1")
		sky_material.sun_angle_max = 18.0
		sky_material.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if not _uses_stylized_v18():
		environment.ambient_light_color = Color("c9d4ff") if expedition_key == "crystal_forge" else Color("c5eaff")
		if _uses_production_material_lighting():
			environment.ambient_light_energy = 0.36
			environment.tonemap_mode = Environment.TONE_MAPPER_ACES
			environment.tonemap_exposure = 0.88
			environment.glow_enabled = true
			environment.glow_intensity = 0.08
			environment.glow_bloom = 0.04
			environment.glow_hdr_threshold = 1.25
		else:
			environment.ambient_light_energy = 0.60
			environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			environment.glow_enabled = quality_level >= 1
			environment.glow_intensity = 0.42 if quality_level == 1 else 0.52
		if quality_level >= 2:
			environment.fog_enabled = true
			environment.fog_light_color = Color("c9ddf5")
			environment.fog_light_energy = 0.42
			environment.fog_density = 0.0017
	world_environment.environment = environment
	add_child(world_environment)
	camera = Camera3D.new()
	camera.name = "DioramaCamera"
	camera.fov = 58.0 if _uses_stylized_v18() else 61.0
	camera.near = 0.08
	camera.far = 340.0
	camera.current = true
	if _uses_stylized_v18():
		camera.position = Vector3(route_centers[0]) + Vector3(0.0, 5.0, 11.5)
		_apply_stylized_start_camera()
	else:
		camera.position = Vector3(route_centers[0]) + Vector3(0.0, 4.1, 9.0)
	add_child(camera)
	if not _uses_stylized_v18():
		camera.look_at(Vector3(route_centers[0]) + Vector3(0.0, 1.0, -1.0), Vector3.UP)
	sun = DirectionalLight3D.new()
	if not _uses_stylized_v18():
		sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
		sun.light_color = Color("e5dcff") if expedition_key == "crystal_forge" else Color("fff0d0")
		sun.light_energy = 0.62 if _uses_production_material_lighting() else 0.94
	sun.shadow_enabled = quality_level >= 1
	sun.directional_shadow_max_distance = 52.0 if _uses_stylized_v18() else 46.0
	add_child(sun)
	if _uses_stylized_v18():
		StylizedLighting.apply(self, environment, sky_material, sun, quality_level)
	if quality_level >= 2 and not _uses_stylized_v18():
		var rim := OmniLight3D.new()
		rim.position = Vector3(-1.0, 5.0, -9.0)
		rim.light_color = Color("9274ff")
		rim.light_energy = 1.35
		rim.omni_range = 17.0
		add_child(rim)


func _build_sky_world() -> void:
	if not _uses_stylized_v18():
		var quad := QuadMesh.new()
		quad.size = Vector2(190.0, 330.0)
		var sky_mat := StandardMaterial3D.new()
		sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sky_mat.albedo_texture = load("res://art/generated/sky_route_backdrop_v10.png")
		sky_mat.albedo_color = Color(0.72, 0.82, 1.0, 1.0) if expedition_key == "crystal_forge" else Color(0.92, 0.96, 1.0, 1.0)
		sky_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		quad.material = sky_mat
		var backdrop := MeshInstance3D.new()
		backdrop.mesh = quad
		backdrop.position = Vector3(0.0, 82.0, -285.0)
		backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(backdrop)
	if _uses_stylized_v18():
		StylizedCloudGenerator.build_sky(self, quality_level, mats, random, Callable(self, "_mesh"), clouds)
	else:
		var cloud_layout := [
			[Vector3(-10.0, -0.5, -7.0), Vector3(5.0, 1.3, 2.3)],
			[Vector3(8.0, 3.5, -13.0), Vector3(4.7, 1.2, 2.0)],
			[Vector3(-8.0, 10.0, -27.0), Vector3(5.2, 1.4, 2.2)],
			[Vector3(9.0, 16.0, -52.0), Vector3(5.8, 1.5, 2.4)],
			[Vector3(-15.0, 24.0, -88.0), Vector3(6.4, 1.7, 2.7)],
			[Vector3(13.0, 34.0, -145.0), Vector3(7.0, 1.8, 2.9)],
			[Vector3(-18.0, 44.0, -205.0), Vector3(7.8, 2.0, 3.1)],
		]
		var cloud_count := 2 if quality_level == 0 else 4 if quality_level == 1 else cloud_layout.size()
		for data in cloud_layout.slice(0, cloud_count):
			_add_cloud(data[0], data[1])
	_add_sun_disc()


func _add_sun_disc() -> void:
	var sun_mesh := SphereMesh.new()
	sun_mesh.radius = 5.5
	sun_mesh.height = 11.0
	var sun_mat := _material(Color("fff1be"), 1.0, 0.0, Color("ffd377"), 2.8)
	sun_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var disc := _mesh(self, sun_mesh, sun_mat, Vector3(-42.0, 62.0, -168.0))
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_cloud(pos: Vector3, cloud_scale: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.set_meta("origin", pos)
	root.set_meta("phase", random.randf_range(0.0, 6.28))
	add_child(root)
	clouds.append(root)
	for offset in [Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.3, -0.1), Vector3(1.0, -0.05, 0.1)]:
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		_mesh(root, sphere, mats.cloud, offset, cloud_scale)


func _build_fx_pool() -> void:
	var trail_count: int = int([12, 20, 30, 40][quality_level])
	var spark_count: int = int([32, 48, 68, 88][quality_level])
	var trail_mesh := SphereMesh.new()
	trail_mesh.radius = 0.18
	trail_mesh.height = 0.36
	for i in range(trail_count):
		var trail := MeshInstance3D.new()
		trail.name = "PooledTrail%02d" % i
		trail.mesh = trail_mesh
		trail.material_override = mats.aether
		trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		trail.visible = false
		add_child(trail)
		trail_pool.append({"node": trail, "life": 0.0, "max_life": 0.48})
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.095
	spark_mesh.height = 0.19
	for i in range(spark_count):
		var spark := MeshInstance3D.new()
		spark.name = "PooledSpark%02d" % i
		spark.mesh = spark_mesh
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spark.visible = false
		add_child(spark)
		spark_pool.append({"node": spark, "life": 0.0, "max_life": 0.42, "velocity": Vector3.ZERO})


func _update_pooled_fx(delta: float) -> void:
	var active_fx := 0
	for item in trail_pool:
		if float(item.life) <= 0.0:
			continue
		item.life = float(item.life) - delta
		var trail: MeshInstance3D = item.node
		if float(item.life) <= 0.0:
			trail.visible = false
		else:
			active_fx += 1
			var ratio := float(item.life) / float(item.max_life)
			trail.scale = Vector3.ONE * maxf(0.06, ratio)
	for item in spark_pool:
		if float(item.life) <= 0.0:
			continue
		item.life = float(item.life) - delta
		var spark: MeshInstance3D = item.node
		if float(item.life) <= 0.0:
			spark.visible = false
		else:
			active_fx += 1
			var velocity: Vector3 = item.velocity
			velocity.y -= 2.4 * delta
			item.velocity = velocity
			spark.position += velocity * delta
			var ratio := float(item.life) / float(item.max_life)
			spark.scale = Vector3.ONE * maxf(0.04, ratio)
	performance_counters.peak_active_fx = maxi(int(performance_counters.peak_active_fx), active_fx)


func _build_islands() -> void:
	for i in range(route_centers.size()):
		_add_floating_island(route_centers[i], route_radii[i], 1.45 if i == 0 else 1.3, true, i)
		_decorate_island(route_centers[i], i > 0, i)
		_add_biome_landmark(route_centers[i], i)
		_add_jump_gate(route_centers[i], i)
		_add_aether_beacon(route_centers[i], route_radii[i], i)
		if i in [1, 3, 5] and quality_level >= 1:
			_add_waterfall(route_centers[i], route_radii[i], i)
		if i > 0:
			# Keep the decorative arch visible, but never put it between the
			# arriving player, the next cannon and the following target island.
			var arch_side := -1.0 if i % 2 == 0 else 1.0
			_add_arch(route_centers[i] + Vector3(arch_side * (route_radii[i] - 3.2), 1.3, 0.2), i)
	# Distant silhouettes add depth without hovering directly above a playable
	# island or being mistaken for the next destination.
	if _uses_stylized_v18():
		_add_floating_island(Vector3(-12.0, 4.0, -22.0), 7.2, 1.0, false, 20)
		_add_floating_island(Vector3(14.0, 6.0, -28.0), 7.8, 1.05, false, 21)
		_add_floating_island(Vector3(2.0, 8.0, -48.0), 8.8, 1.15, false, 22)
		for data in [
			[Vector3(-22.0, 7.0, -38.0), 5.4, 0.82, 11],
			[Vector3(26.0, 9.0, -44.0), 5.8, 0.86, 12],
			[Vector3(-16.0, 12.0, -72.0), 6.2, 0.9, 13],
			[Vector3(20.0, 14.0, -88.0), 5.6, 0.84, 14],
			[Vector3(-28.0, 18.0, -118.0), 5.0, 0.78, 15],
			[Vector3(10.0, 20.0, -138.0), 4.6, 0.74, 16],
			[Vector3(-6.0, 24.0, -168.0), 4.2, 0.72, 17],
			[Vector3(24.0, 22.0, -188.0), 3.8, 0.7, 18],
		]:
			_add_floating_island(data[0], data[1], data[2], false, data[3])
	else:
		_add_floating_island(Vector3(30.0, 15.0, -57.0), 4.6, 0.9, false, 11)
		_add_floating_island(Vector3(-34.0, 25.0, -106.0), 5.2, 1.0, false, 12)
		_add_floating_island(Vector3(37.0, 39.0, -176.0), 5.8, 1.1, false, 13)
		_add_floating_island(Vector3(-38.0, 48.0, -236.0), 4.4, 0.9, false, 14)
	_add_airship(Vector3(-14.0, 12.0, -18.0), 0.0)
	_add_airship(Vector3(24.0, 33.0, -142.0), 2.4)


func _uses_stylized_v18() -> bool:
	return USE_STYLIZED_V18 and expedition_key == "wolkengarten"


func _apply_stylized_start_camera() -> void:
	if camera == null or player == null:
		return
	var from: Vector3 = Vector3(route_centers[0])
	var to: Vector3 = Vector3(route_centers[1])
	var forward: Vector3 = to - from
	forward.y = 0.0
	if forward.length_squared() > 0.01:
		forward = forward.normalized()
		orbit_yaw = rad_to_deg(atan2(forward.x, -forward.z))
		target_orbit_yaw = orbit_yaw
	orbit_pitch = 24.0
	target_orbit_pitch = 24.0
	camera.fov = 51.0
	var look_ahead: Vector3 = player.global_position.lerp(to, 0.52)
	look_ahead.y = player.global_position.y + 2.4
	var yaw := deg_to_rad(orbit_yaw)
	var pitch := deg_to_rad(orbit_pitch)
	var orbit_offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 14.8
	camera.global_position = player.global_position + orbit_offset + Vector3(0, 1.55, 0)
	camera.look_at(look_ahead, Vector3.UP)


func _uses_production_island_visual(island_index: int) -> bool:
	return island_index == 0 and USE_PRODUCTION_ISLAND_0 and expedition_key == "wolkengarten" and not _uses_stylized_v18()


func _uses_production_material_lighting() -> bool:
	return USE_PRODUCTION_ISLAND_0 and expedition_key == "wolkengarten" and not _uses_stylized_v18()


func _add_production_island_visual(root: Node3D, radius: float, thickness: float) -> void:
	var visual = ProductionAsset.new()
	visual.name = "ProductionIslandVisual"
	visual.configure_floating_island(radius, thickness, quality_level)
	visual.enable_gameplay_collision = false
	root.add_child(visual)


func _build_procedural_island_geometry(root: Node3D, radius: float, thickness: float, playable: bool, island_index: int) -> void:
	var segments := 18
	var ring := PackedFloat32Array()
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = 9017 + island_index * 619 + route_variant * 71
	for i in range(segments):
		var wave := sin(float(i) * 1.71 + island_index) * 0.055 + cos(float(i) * 0.77) * 0.035
		ring.append(radius * (1.0 + wave + local_rng.randf_range(-0.045, 0.045)))
	var top_surface := SurfaceTool.new()
	top_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var next := (i + 1) % segments
		var a := TAU * float(i) / float(segments)
		var b := TAU * float(next) / float(segments)
		var shade := 0.94 + sin(float(i) * 1.63 + island_index) * 0.045
		top_surface.set_color(Color(shade, minf(1.0, shade + 0.025), shade, 1.0))
		top_surface.set_uv(Vector2(0.5, 0.5))
		top_surface.add_vertex(Vector3.ZERO)
		top_surface.set_uv(Vector2(0.5 + cos(b) * 0.5, 0.5 + sin(b) * 0.5))
		top_surface.add_vertex(Vector3(cos(b) * ring[next], 0.0, sin(b) * ring[next] * 0.86))
		top_surface.set_uv(Vector2(0.5 + cos(a) * 0.5, 0.5 + sin(a) * 0.5))
		top_surface.add_vertex(Vector3(cos(a) * ring[i], 0.0, sin(a) * ring[i] * 0.86))
	top_surface.generate_normals()
	var biome_surfaces := [mats.grass_light, mats.grass_mint, mats.grass_blue, mats.grass_lilac, mats.grass_amber, mats.grass_royal]
	var top_material: Material = biome_surfaces[island_index % biome_surfaces.size()]
	_mesh(root, top_surface.commit(), top_material)
	# A separate moss lip gives the plateau a readable hand-crafted edge instead
	# of ending as a razor-thin procedural disc.
	var edge_surface := SurfaceTool.new()
	edge_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var next := (i + 1) % segments
		var a := TAU * float(i) / float(segments)
		var b := TAU * float(next) / float(segments)
		var a_top := Vector3(cos(a) * ring[i], 0.02, sin(a) * ring[i] * 0.86)
		var b_top := Vector3(cos(b) * ring[next], 0.02, sin(b) * ring[next] * 0.86)
		var a_low := Vector3(cos(a) * ring[i] * 0.985, -0.34, sin(a) * ring[i] * 0.846)
		var b_low := Vector3(cos(b) * ring[next] * 0.985, -0.34, sin(b) * ring[next] * 0.846)
		edge_surface.set_color(Color(0.93, 0.98, 0.94, 1.0))
		edge_surface.set_uv(Vector2(float(i) / segments, 0.0))
		edge_surface.add_vertex(a_top); edge_surface.add_vertex(b_top); edge_surface.add_vertex(a_low)
		edge_surface.set_uv(Vector2(float(next) / segments, 1.0))
		edge_surface.add_vertex(b_top); edge_surface.add_vertex(b_low); edge_surface.add_vertex(a_low)
	edge_surface.generate_normals()
	_mesh(root, edge_surface.commit(), mats.edge_moss)
	var cliff_surface := SurfaceTool.new()
	cliff_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var depth := radius * (0.62 + local_rng.randf_range(-0.04, 0.07))
	var layer_y := [-0.10, -thickness - 0.7, -depth * 0.58, -depth]
	var layer_scale := [0.99, 0.86, 0.58, 0.12]
	for layer in range(layer_scale.size() - 1):
		for i in range(segments):
			var next := (i + 1) % segments
			var a := TAU * float(i) / float(segments)
			var b := TAU * float(next) / float(segments)
			var skew_a := 1.0 + sin(float(i) * 2.13 + island_index) * 0.07
			var skew_b := 1.0 + sin(float(next) * 2.13 + island_index) * 0.07
			var t0 := Vector3(cos(a) * ring[i] * layer_scale[layer] * skew_a, layer_y[layer], sin(a) * ring[i] * 0.86 * layer_scale[layer])
			var t1 := Vector3(cos(b) * ring[next] * layer_scale[layer] * skew_b, layer_y[layer], sin(b) * ring[next] * 0.86 * layer_scale[layer])
			var b0 := Vector3(cos(a) * ring[i] * layer_scale[layer + 1], layer_y[layer + 1], sin(a) * ring[i] * 0.86 * layer_scale[layer + 1])
			var b1 := Vector3(cos(b) * ring[next] * layer_scale[layer + 1], layer_y[layer + 1], sin(b) * ring[next] * 0.86 * layer_scale[layer + 1])
			var cliff_shade := 1.0 - float(layer) * 0.10 + sin(float(i) * 1.17) * 0.035
			cliff_surface.set_color(Color(cliff_shade, cliff_shade * 0.98, cliff_shade * 0.94, 1.0))
			cliff_surface.set_uv(Vector2(float(i) / segments, float(layer) / 3.0))
			cliff_surface.add_vertex(t0); cliff_surface.add_vertex(t1); cliff_surface.add_vertex(b0)
			cliff_surface.set_uv(Vector2(float(next) / segments, float(layer + 1) / 3.0))
			cliff_surface.add_vertex(t1); cliff_surface.add_vertex(b1); cliff_surface.add_vertex(b0)
	# Close the narrow underside ring with a real rocky tip. The v15 shell ended
	# in an open hole, which appeared as a transparent island on some Android
	# Compatibility drivers and whenever the flight camera looked upward.
	var tip := Vector3(0.0, -depth - maxf(0.55, thickness * 0.32), 0.0)
	var last_scale: float = layer_scale[layer_scale.size() - 1]
	for i in range(segments):
		var next := (i + 1) % segments
		var a := TAU * float(i) / float(segments)
		var b := TAU * float(next) / float(segments)
		var a_bottom := Vector3(cos(a) * ring[i] * last_scale, layer_y[layer_y.size() - 1], sin(a) * ring[i] * 0.86 * last_scale)
		var b_bottom := Vector3(cos(b) * ring[next] * last_scale, layer_y[layer_y.size() - 1], sin(b) * ring[next] * 0.86 * last_scale)
		var tip_shade := 0.70 + sin(float(i) * 1.37) * 0.04
		cliff_surface.set_color(Color(tip_shade, tip_shade * 0.97, tip_shade * 0.91, 1.0))
		cliff_surface.set_uv(Vector2(0.5, 1.0))
		cliff_surface.add_vertex(tip)
		cliff_surface.set_uv(Vector2(float(next) / segments, 0.88))
		cliff_surface.add_vertex(b_bottom)
		cliff_surface.set_uv(Vector2(float(i) / segments, 0.88))
		cliff_surface.add_vertex(a_bottom)
	cliff_surface.generate_normals()
	_mesh(root, cliff_surface.commit(), mats.cliff_warm if island_index in [0, 5] else mats.rock)
	# A few offset facets break the remaining cone silhouette without adding costly collision.
	for i in range(7 if playable else 3):
		var facet_angle := TAU * float(i) / float(7) + local_rng.randf_range(-0.22, 0.22)
		var facet := PrismMesh.new()
		facet.size = Vector3(radius * 0.22, depth * local_rng.randf_range(0.22, 0.42), radius * 0.16)
		_mesh(root, facet, mats.rock_mid if i % 2 == 0 else mats.rock_dark,
			Vector3(cos(facet_angle) * radius * 0.68, -depth * local_rng.randf_range(0.30, 0.70), sin(facet_angle) * radius * 0.58),
			Vector3.ONE, Vector3(local_rng.randf_range(-12.0, 12.0), rad_to_deg(-facet_angle), local_rng.randf_range(-10.0, 10.0)))
	for crystal_pos in [Vector3(-radius * 0.62, 0.25, -0.5), Vector3(radius * 0.58, 0.2, 0.7)]:
		_add_crystal_cluster(root, crystal_pos)
	# Chunky edge stones and tiny flowers break the remaining regular outline.
	if playable:
		for i in range(10):
			var edge_angle := TAU * float(i) / 10.0 + local_rng.randf_range(-0.18, 0.18)
			var edge_pos := Vector3(cos(edge_angle) * radius * 0.88, 0.18, sin(edge_angle) * radius * 0.74)
			var stone := PrismMesh.new()
			stone.size = Vector3(local_rng.randf_range(0.55, 1.05), local_rng.randf_range(0.35, 0.72), local_rng.randf_range(0.45, 0.86))
			_mesh(root, stone, mats.rock if i % 2 == 0 else mats.cliff_warm, edge_pos, Vector3.ONE, Vector3(local_rng.randf_range(-8.0, 8.0), rad_to_deg(-edge_angle), local_rng.randf_range(-9.0, 9.0)))
		for i in range(8):
			var flower_angle := TAU * float(i) / 8.0 + 0.37
			_add_flower(root, Vector3(cos(flower_angle) * radius * 0.68, 0.08, sin(flower_angle) * radius * 0.58), i % 3)


func _add_floating_island(center: Vector3, radius: float, thickness: float, playable: bool, island_index := 0) -> void:
	var root := Node3D.new()
	root.name = "SkyIsland%02d" % island_index
	root.position = center
	add_child(root)
	if _uses_production_island_visual(island_index):
		_add_production_island_visual(root, radius, thickness)
	elif _uses_stylized_v18():
		StylizedIslandGenerator.build(root, radius, thickness, playable, island_index, mats, quality_level, route_variant, Callable(self, "_mesh"))
	else:
		_build_procedural_island_geometry(root, radius, thickness, playable, island_index)
	if playable:
		var body := StaticBody3D.new()
		root.add_child(body)
		var collider := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius * 0.91
		shape.height = thickness
		collider.shape = shape
		collider.position.y = -thickness * 0.5
		body.add_child(collider)


func _decorate_island(center: Vector3, target_side: bool, island_index := 0) -> void:
	var root := Node3D.new()
	root.position = center
	root.name = "TargetIslandDecor" if target_side else "SourceIslandDecor"
	add_child(root)
	if _uses_production_island_visual(island_index):
		_decorate_production_island_lite(root, island_index)
		return
	if _uses_stylized_v18():
		var island_radius: float = float(route_radii[clampi(island_index, 0, route_radii.size() - 1)])
		if island_index == 0:
			StylizedWorldDecorator.decorate_start_island(root, mats, Callable(self, "_mesh"), Callable(self, "_transparent_material"), random, island_radius)
		elif island_index == 1:
			StylizedWorldDecorator.decorate_hero_midground(root, mats, Callable(self, "_mesh"), Callable(self, "_transparent_material"), wind_streamers)
		elif target_side:
			StylizedWorldDecorator.decorate_target_island(root, mats, Callable(self, "_mesh"), island_radius)
		else:
			StylizedWorldDecorator.decorate_playable_island(root, island_index, mats, Callable(self, "_mesh"), random, island_radius)
		return
	# Tall silhouettes frame the island at the sides instead of obscuring the
	# centre line used by the cannon and its camera.
	var spread: float = float(route_radii[clampi(island_index, 0, route_radii.size() - 1)]) * 0.46
	var tree_positions := [Vector3(-spread, 0.0, 0.2), Vector3(spread, 0.0, 1.8)] if not target_side else [Vector3(-spread, 0.0, 2.0), Vector3(spread, 0.0, 0.8)]
	for pos in tree_positions:
		_add_tree(root, pos, 0.9 + random.randf_range(-0.08, 0.12))
	for pos in [Vector3(-3.5, 0.1, 3.2), Vector3(3.4, 0.1, 3.0), Vector3(-4.0, 0.1, -2.6), Vector3(4.1, 0.1, -2.5)]:
		_add_grass_tuft(root, pos)
	for i in range(7):
		var z := 2.5 - i * 0.72
		var stone := CylinderMesh.new()
		stone.top_radius = 0.42
		stone.bottom_radius = 0.38
		stone.height = 0.09
		stone.radial_segments = 8
		_mesh(root, stone, mats.rock, Vector3(sin(i * 0.9) * 0.3, 0.13, z), Vector3(1.0, 1.0, 0.72), Vector3(0, i * 19.0, 0))
	# A readable stone-and-brass path leads naturally from the landing area to
	# the cannon and doubles as visual guidance without another HUD arrow.
	for i in range(6):
		var path_stone := CylinderMesh.new()
		path_stone.top_radius = 0.55
		path_stone.bottom_radius = 0.48
		path_stone.height = 0.08
		path_stone.radial_segments = 7
		_mesh(root, path_stone, mats.white if i % 2 == 0 else mats.rock, Vector3(sin(i * 1.4) * 0.22, 0.11, 0.95 - i * 0.68), Vector3(1.15, 1.0, 0.78), Vector3(0, i * 23.0, 0))
	for x in [-2.05, 2.05]:
		_add_aether_lantern(root, Vector3(x, 0.0, -0.3), 0.78)
	var pad := CylinderMesh.new()
	pad.top_radius = 1.45
	pad.bottom_radius = 1.55
	pad.height = 0.16
	pad.radial_segments = 18
	_mesh(root, pad, mats.rock_dark, Vector3(0, 0.09, -1.2))
	var pad_ring := TorusMesh.new()
	pad_ring.inner_radius = 0.94
	pad_ring.outer_radius = 1.18
	pad_ring.rings = 18
	pad_ring.ring_segments = 8
	_mesh(root, pad_ring, mats.brass, Vector3(0, 0.18, -1.2), Vector3.ONE, Vector3(90, 0, 0))


func _decorate_production_island_lite(root: Node3D, island_index: int) -> void:
	# Keep gameplay-readable framing without duplicating authored mesh surfaces.
	var spread: float = float(route_radii[clampi(island_index, 0, route_radii.size() - 1)]) * 0.46
	for pos in [Vector3(-spread, 0.0, 0.2), Vector3(spread, 0.0, 1.8)]:
		_add_tree(root, pos, 0.9 + random.randf_range(-0.08, 0.12))
	for x in [-2.05, 2.05]:
		_add_aether_lantern(root, Vector3(x, 0.0, -0.3), 0.78)


func _add_biome_landmark(center: Vector3, island_index: int) -> void:
	var root := Node3D.new()
	root.name = "BiomeLandmark%02d" % (island_index + 1)
	root.position = center
	add_child(root)
	if expedition_key == "crystal_forge":
		_add_crystal_forge_landmark(root, island_index)
		return
	match island_index:
		0:
			if _uses_stylized_v18():
				_add_banner(root, Vector3(6.6, 0.0, 3.4), Color("7651e8"))
			elif _uses_production_island_visual(0):
				_add_banner(root, Vector3(6.6, 0.0, 3.4), Color("7651e8"))
			else:
				_add_windmill(root, Vector3(-6.8, 0.0, 4.0), 0.92)
				_add_banner(root, Vector3(6.6, 0.0, 3.4), Color("7651e8"))
		1:
			_add_mushroom_grove(root, Vector3(5.8, 0.0, 4.0))
			_add_small_bridge(root, Vector3(-4.8, 0.0, 4.5))
		2:
			_add_crystal_workshop(root, Vector3(-6.4, 0.0, 4.2))
			_add_banner(root, Vector3(6.8, 0.0, 3.7), Color("35d6ff"))
		3:
			_add_portal_ruin(root, Vector3(6.7, 0.0, 3.7))
			_add_mushroom_grove(root, Vector3(-6.1, 0.0, 4.1))
		4:
			_add_airship_dock(root, Vector3(-6.8, 0.0, 3.8))
			_add_banner(root, Vector3(6.5, 0.0, 4.0), Color("ffc94f"))
		5:
			_add_treasure_fortress(root, Vector3(0.0, 0.0, 5.6))
			_add_banner(root, Vector3(-8.2, 0.0, 2.2), Color("ef5f70"))


func _add_crystal_forge_landmark(root: Node3D, island_index: int) -> void:
	match island_index:
		0:
			# Arrival observatory with a rotating calibration ring.
			_mesh(root, _cylinder(2.25, 0.48, 18), mats.rock_dark, Vector3(-5.8, 0.24, 4.2))
			var ring := TorusMesh.new(); ring.inner_radius = 1.25; ring.outer_radius = 1.50; ring.rings = 20; ring.ring_segments = 9
			var rotor := _mesh(root, ring, mats.brass_light, Vector3(-5.8, 2.25, 4.2), Vector3.ONE, Vector3(90, 0, 0)); rotor.set_meta("animate_portal", true); wind_streamers.append(rotor)
			_add_crystal_cluster(root, Vector3(-5.8, 2.25, 4.2), 1.05)
		1:
			# Resonance hammers frame a glowing forge heart.
			_mesh(root, _box(Vector3(5.2, 0.55, 3.6)), mats.rock_dark, Vector3(5.2, 0.28, 3.8))
			for x in [3.6, 6.8]:
				_mesh(root, _box(Vector3(0.65, 3.6, 0.78)), mats.brass, Vector3(x, 1.8, 3.8))
				_mesh(root, _box(Vector3(1.35, 0.72, 0.92)), mats.brass_light, Vector3(x, 3.62, 3.8))
			_add_crystal_cluster(root, Vector3(5.2, 0.75, 3.8), 1.25)
		2:
			# Three-tier mining rig with suspended aether drill.
			for y in [0.4, 1.45, 2.5]:
				_mesh(root, _box(Vector3(5.4 - y * 0.45, 0.28, 3.1)), mats.brass if y < 2.0 else mats.brass_light, Vector3(-5.6, y, 4.0))
			for x in [-7.5, -3.7]:
				_mesh(root, _box(Vector3(0.34, 3.2, 0.42)), mats.rock_mid, Vector3(x, 1.6, 4.0))
			var drill := PrismMesh.new(); drill.size = Vector3(1.05, 2.6, 0.95)
			_mesh(root, drill, mats.crystal, Vector3(-5.6, 2.0, 4.0), Vector3.ONE, Vector3(0, 0, 180))
		3:
			# Prism array creates a recognisable risky-route silhouette.
			for i in range(5):
				var angle := -48.0 + i * 24.0
				var prism := PrismMesh.new(); prism.size = Vector3(0.72, 3.0 + i % 2, 0.62)
				_mesh(root, prism, mats.crystal, Vector3(5.8 + (i - 2) * 0.92, 1.6 + (i % 2) * 0.45, 3.9), Vector3.ONE, Vector3(0, 0, angle * 0.16))
			_mesh(root, _box(Vector3(6.2, 0.38, 2.5)), mats.rock_dark, Vector3(5.8, 0.2, 3.9))
		4:
			# Mag-rail station and floating cargo capsules.
			for z in [2.7, 4.8]:
				_mesh(root, _box(Vector3(6.4, 0.26, 0.32)), mats.aether, Vector3(-5.7, 0.45, z))
				_mesh(root, _box(Vector3(6.4, 0.38, 0.62)), mats.brass, Vector3(-5.7, 0.18, z))
			for i in range(3):
				var capsule := SphereMesh.new(); capsule.radius = 0.72; capsule.height = 1.4
				_mesh(root, capsule, mats.violet, Vector3(-7.5 + i * 1.8, 1.0 + i * 0.25, 3.75), Vector3(1.25, 0.72, 0.72), Vector3(0, 0, 90))
		5:
			# Final crown vault with a large vertical crystal and energy rings.
			for x in [-3.5, 3.5]:
				_mesh(root, _box(Vector3(2.2, 4.4, 2.2)), mats.rock_dark, Vector3(x, 2.2, 5.2))
				_add_crystal_cluster(root, Vector3(x, 4.6, 5.2), 1.1)
			var core := PrismMesh.new(); core.size = Vector3(1.7, 4.8, 1.45)
			_mesh(root, core, mats.objective, Vector3(0, 2.5, 5.2))
			for y in [1.3, 2.6, 3.9]:
				var crown_ring := TorusMesh.new(); crown_ring.inner_radius = 1.15; crown_ring.outer_radius = 1.34; crown_ring.rings = 18; crown_ring.ring_segments = 8
				var animated_ring := _mesh(root, crown_ring, mats.brass_light, Vector3(0, y, 5.2), Vector3.ONE, Vector3(90, 0, 0)); animated_ring.set_meta("animate_portal", true); wind_streamers.append(animated_ring)


func _add_windmill(parent: Node3D, pos: Vector3, scale_value: float) -> void:
	var root := Node3D.new(); root.position = pos; root.scale = Vector3.ONE * scale_value; parent.add_child(root)
	_mesh(root, _cylinder(1.15, 3.0, 10), mats.white, Vector3(0, 1.5, 0))
	var roof := PrismMesh.new(); roof.size = Vector3(2.8, 1.5, 2.3)
	_mesh(root, roof, mats.bronze, Vector3(0, 3.55, 0), Vector3.ONE, Vector3(0, 0, 90))
	var rotor := Node3D.new(); rotor.name = "WindmillRotor"; rotor.position = Vector3(0, 2.65, -1.25); root.add_child(rotor)
	_mesh(rotor, _cylinder(0.32, 0.34, 12), mats.brass, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
	for angle in [0.0, 90.0, 180.0, 270.0]:
		var blade := _mesh(rotor, _box(Vector3(0.34, 2.45, 0.12)), mats.wood, Vector3(0, 1.12, 0))
		blade.rotation_degrees.z = angle
	rotor.set_meta("animate_rotor", true)
	wind_streamers.append(rotor)


func _add_mushroom_grove(parent: Node3D, pos: Vector3) -> void:
	var grove := Node3D.new(); grove.position = pos; parent.add_child(grove)
	for data in [[Vector3.ZERO, 1.0], [Vector3(-1.6, 0, 0.6), 0.72], [Vector3(1.5, 0, 0.8), 0.82]]:
		var stalk_height := 1.2 * float(data[1])
		_mesh(grove, _cylinder(0.22 * float(data[1]), stalk_height, 9), mats.white, data[0] + Vector3(0, stalk_height * 0.5, 0))
		var cap := SphereMesh.new(); cap.radius = 0.9 * float(data[1]); cap.height = 0.65 * float(data[1]); cap.radial_segments = 12; cap.rings = 6
		_mesh(grove, cap, mats.mushroom, data[0] + Vector3(0, stalk_height + 0.18, 0), Vector3(1.2, 0.72, 1.2))
		for spot_angle in [25.0, 145.0, 265.0]:
			var spot := SphereMesh.new(); spot.radius = 0.105 * float(data[1]); spot.height = 0.075 * float(data[1])
			var spot_pos: Vector3 = Vector3(data[0]) + Vector3(cos(deg_to_rad(spot_angle)) * 0.48 * float(data[1]), stalk_height + 0.46 * float(data[1]), sin(deg_to_rad(spot_angle)) * 0.38 * float(data[1]))
			_mesh(grove, spot, mats.mushroom_spot, spot_pos, Vector3(1.3, 0.45, 1.0))


func _add_small_bridge(parent: Node3D, pos: Vector3) -> void:
	var bridge := Node3D.new(); bridge.position = pos; bridge.rotation_degrees.y = 18.0; parent.add_child(bridge)
	for i in range(6):
		_mesh(bridge, _box(Vector3(0.92, 0.13, 1.8)), mats.wood, Vector3((i - 2.5) * 0.82, 0.25 + sin(float(i) / 5.0 * PI) * 0.34, 0))
	for x in [-2.55, 2.55]:
		_mesh(bridge, _cylinder(0.09, 1.0, 8), mats.brass, Vector3(x, 0.65, -0.75))


func _add_crystal_workshop(parent: Node3D, pos: Vector3) -> void:
	var workshop := Node3D.new(); workshop.position = pos; parent.add_child(workshop)
	_mesh(workshop, _box(Vector3(4.0, 1.8, 3.0)), mats.rock_dark, Vector3(0, 0.9, 0))
	var roof := PrismMesh.new(); roof.size = Vector3(4.5, 1.35, 3.5)
	_mesh(workshop, roof, mats.bronze, Vector3(0, 2.25, 0), Vector3.ONE, Vector3(0, 0, 90))
	_mesh(workshop, _box(Vector3(1.3, 1.45, 0.14)), mats.aether, Vector3(0, 0.95, -1.58))
	_add_crystal_cluster(workshop, Vector3(-1.25, 2.2, -1.1), 0.82)


func _add_portal_ruin(parent: Node3D, pos: Vector3) -> void:
	var ruin := Node3D.new(); ruin.position = pos; ruin.rotation_degrees.y = -24.0; parent.add_child(ruin)
	for x in [-1.3, 1.3]:
		_mesh(ruin, _box(Vector3(0.65, 3.3, 0.8)), mats.rock, Vector3(x, 1.65, 0))
	var ring := TorusMesh.new(); ring.inner_radius = 1.05; ring.outer_radius = 1.34; ring.rings = 20; ring.ring_segments = 10
	var portal_ring := _mesh(ruin, ring, mats.brass, Vector3(0, 1.9, 0), Vector3.ONE, Vector3(90, 0, 0))
	portal_ring.set_meta("animate_portal", true)
	wind_streamers.append(portal_ring)
	var inner_ring := TorusMesh.new(); inner_ring.inner_radius = 0.78; inner_ring.outer_radius = 0.94; inner_ring.rings = 20; inner_ring.ring_segments = 8
	var inner_portal := _mesh(ruin, inner_ring, mats.aether, Vector3(0, 1.9, -0.04), Vector3.ONE, Vector3(90, 0, 0))
	inner_portal.set_meta("animate_portal", true)
	wind_streamers.append(inner_portal)
	var portal_disc := CylinderMesh.new(); portal_disc.top_radius = 0.78; portal_disc.bottom_radius = 0.78; portal_disc.height = 0.04; portal_disc.radial_segments = 24
	_mesh(ruin, portal_disc, _transparent_material(Color(0.30, 0.82, 1.0, 0.42)), Vector3(0, 1.9, 0), Vector3.ONE, Vector3(90, 0, 0))
	for angle in [45.0, 135.0, 225.0, 315.0]:
		var rune := PrismMesh.new(); rune.size = Vector3(0.22, 0.42, 0.14)
		_mesh(ruin, rune, mats.crystal, Vector3(cos(deg_to_rad(angle)) * 1.46, 1.9 + sin(deg_to_rad(angle)) * 1.46, -0.05), Vector3.ONE, Vector3(0, 0, -angle))
	_add_crystal_cluster(ruin, Vector3(0, 3.75, 0), 0.68)


func _add_airship_dock(parent: Node3D, pos: Vector3) -> void:
	var dock := Node3D.new(); dock.position = pos; dock.rotation_degrees.y = 18.0; parent.add_child(dock)
	for i in range(5):
		_mesh(dock, _box(Vector3(0.95, 0.16, 3.4)), mats.wood, Vector3(i * 0.8 - 1.6, 0.35, 0))
	for x in [-2.0, 2.0]:
		_mesh(dock, _cylinder(0.12, 2.2, 8), mats.brass, Vector3(x, 1.1, 1.45))
	var balloon := SphereMesh.new(); balloon.radius = 1.2; balloon.height = 2.4; balloon.radial_segments = 12; balloon.rings = 8
	_mesh(dock, balloon, mats.white, Vector3(0, 4.1, 0.3), Vector3(1.45, 0.88, 0.88), Vector3(0, 0, 90))
	_mesh(dock, _box(Vector3(2.0, 0.65, 0.8)), mats.wood, Vector3(0, 2.45, 0.3))


func _add_treasure_fortress(parent: Node3D, pos: Vector3) -> void:
	var fort := Node3D.new(); fort.position = pos; parent.add_child(fort)
	for x in [-3.0, 3.0]:
		_mesh(fort, _box(Vector3(2.0, 3.2, 2.0)), mats.rock_dark, Vector3(x, 1.6, 0))
		_add_crystal_cluster(fort, Vector3(x, 3.5, 0), 0.9)
	_mesh(fort, _box(Vector3(4.2, 1.0, 1.4)), mats.brass, Vector3(0, 3.1, 0))
	_mesh(fort, _box(Vector3(4.5, 0.32, 0.48)), mats.violet, Vector3(0, 1.2, -0.82))


func _add_banner(parent: Node3D, pos: Vector3, color: Color) -> void:
	var root := Node3D.new(); root.position = pos; parent.add_child(root)
	_mesh(root, _cylinder(0.09, 3.1, 8), mats.brass, Vector3(0, 1.55, 0))
	var cloth_mat := _material(color, 0.72, 0.0, color, 0.22)
	_mesh(root, _box(Vector3(1.45, 1.05, 0.08)), cloth_mat, Vector3(0.72, 2.35, 0))


func _add_airship(pos: Vector3, phase: float) -> void:
	var ship := Node3D.new(); ship.position = pos; ship.name = "SkyCourier"; add_child(ship)
	var balloon := SphereMesh.new(); balloon.radius = 1.7; balloon.height = 3.4; balloon.radial_segments = 14; balloon.rings = 8
	_mesh(ship, balloon, mats.white, Vector3(0, 2.3, 0), Vector3(1.65, 0.86, 0.9), Vector3(0, 0, 90))
	_mesh(ship, _box(Vector3(3.0, 0.65, 1.0)), mats.wood, Vector3(0, 0.4, 0))
	_mesh(ship, _box(Vector3(0.18, 1.55, 0.18)), mats.brass, Vector3(-1.15, 1.25, 0))
	_mesh(ship, _box(Vector3(0.18, 1.55, 0.18)), mats.brass, Vector3(1.15, 1.25, 0))
	for x in [-1.15, 1.15]:
		_mesh(ship, _cylinder(0.22, 0.14, 10), mats.aether, Vector3(x, 0.32, 0.58), Vector3.ONE, Vector3(90, 0, 0))
	var tail := PrismMesh.new(); tail.size = Vector3(0.75, 1.25, 0.12)
	_mesh(ship, tail, mats.violet, Vector3(1.55, 2.45, 0), Vector3.ONE, Vector3(0, 0, 90))
	airships.append({"node": ship, "origin": pos, "phase": phase})


func _add_tree(parent: Node3D, pos: Vector3, scale_value: float) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.scale = Vector3.ONE * scale_value
	parent.add_child(tree)
	_mesh(tree, _cylinder(0.22, 1.5, 8), mats.wood, Vector3(0, 0.75, 0))
	for data in [[Vector3(0, 1.65, 0), 0.9], [Vector3(-0.45, 1.45, 0), 0.62], [Vector3(0.42, 1.48, 0.08), 0.68]]:
		var crown := SphereMesh.new()
		crown.radius = float(data[1])
		crown.height = float(data[1]) * 1.7
		_mesh(tree, crown, mats.grass_light, data[0], Vector3(1.0, 0.82, 1.0))


func _add_grass_tuft(parent: Node3D, pos: Vector3) -> void:
	var tuft := Node3D.new()
	tuft.position = pos
	parent.add_child(tuft)
	for i in range(3):
		var blade := PrismMesh.new()
		blade.size = Vector3(0.13, 0.52 + i * 0.08, 0.09)
		_mesh(tuft, blade, mats.grass_light, Vector3((i - 1) * 0.14, 0.25, 0), Vector3.ONE, Vector3(0, 0, -18 + i * 18))


func _add_flower(parent: Node3D, pos: Vector3, variant: int) -> void:
	var flower := Node3D.new()
	flower.name = "SkyFlower%03d" % parent.get_child_count()
	flower.position = pos
	parent.add_child(flower)
	_mesh(flower, _cylinder(0.035, 0.34, 6), mats.grass, Vector3(0, 0.17, 0))
	var petal_material: Material = mats.flower_pink if variant == 0 else mats.crystal if variant == 1 else mats.mushroom_spot
	for angle in [0.0, 90.0, 180.0, 270.0]:
		var petal := SphereMesh.new()
		petal.radius = 0.095
		petal.height = 0.15
		var offset := Vector3(cos(deg_to_rad(angle)) * 0.09, 0.38, sin(deg_to_rad(angle)) * 0.09)
		_mesh(flower, petal, petal_material, offset, Vector3(1.15, 0.62, 0.88))
	_mesh(flower, _cylinder(0.06, 0.05, 8), mats.brass_light, Vector3(0, 0.4, 0))


func _add_aether_lantern(parent: Node3D, pos: Vector3, scale_value := 1.0) -> void:
	var lantern := Node3D.new()
	lantern.name = "AetherLantern%03d" % parent.get_child_count()
	lantern.position = pos
	lantern.scale = Vector3.ONE * scale_value
	parent.add_child(lantern)
	_mesh(lantern, _cylinder(0.09, 1.25, 8), mats.brass, Vector3(0, 0.62, 0))
	_mesh(lantern, _cylinder(0.24, 0.12, 10), mats.brass_light, Vector3(0, 1.28, 0))
	var bulb := SphereMesh.new()
	bulb.radius = 0.22
	bulb.height = 0.42
	_mesh(lantern, bulb, mats.aether, Vector3(0, 1.55, 0), Vector3(0.78, 1.0, 0.78))
	var cap := PrismMesh.new()
	cap.size = Vector3(0.55, 0.28, 0.55)
	_mesh(lantern, cap, mats.brass, Vector3(0, 1.84, 0), Vector3.ONE, Vector3(0, 0, 90))


func _add_jump_gate(center: Vector3, island_index: int) -> void:
	# The conduit remains a useful jump obstacle, but sits in a side lane rather
	# than directly behind the cannon where it used to block the aim camera.
	var root := Node3D.new()
	root.name = "JumpGate%02d" % (island_index + 1)
	var side := -1.0 if island_index % 2 == 0 else 1.0
	root.position = center + Vector3(side * 4.25, 0.0, 2.0 if island_index % 2 == 0 else 1.55)
	root.rotation_degrees.y = 74.0 if island_index % 2 == 0 else -74.0
	add_child(root)
	_mesh(root, _box(Vector3(4.6, 0.62, 0.55)), mats.rock_dark, Vector3(0, 0.31, 0))
	_mesh(root, _box(Vector3(4.15, 0.18, 0.62)), mats.violet, Vector3(0, 0.67, 0))
	for x in [-2.15, 2.15]:
		_mesh(root, _cylinder(0.22, 0.88, 10), mats.brass, Vector3(x, 0.44, 0))
	var body := StaticBody3D.new()
	root.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.6, 0.62, 0.55)
	collider.shape = shape
	collider.position = Vector3(0, 0.31, 0)
	body.add_child(collider)


func _add_aether_beacon(center: Vector3, radius: float, island_index: int) -> void:
	var root := Node3D.new()
	root.name = "AetherBeacon%02d" % (island_index + 1)
	root.position = center + Vector3(radius * 0.58 * (-1.0 if island_index % 2 == 0 else 1.0), 0.12, 0.4)
	add_child(root)
	_mesh(root, _cylinder(0.48, 0.18, 14), mats.brass, Vector3(0, 0.09, 0))
	_mesh(root, _cylinder(0.22, 1.4, 10), mats.rock_dark, Vector3(0, 0.78, 0))
	var prism := PrismMesh.new()
	prism.size = Vector3(0.58, 1.25, 0.52)
	var crystal := _mesh(root, prism, mats.crystal, Vector3(0, 1.75, 0), Vector3.ONE, Vector3(0, 0, 8.0))
	aether_beacons.append({"root": root, "crystal": crystal, "phase": island_index * 1.3})
	if quality_level >= 3:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 1.8, 0)
		light.light_color = Color("54dfff")
		light.light_energy = 0.75
		light.omni_range = 5.0
		root.add_child(light)


func _add_waterfall(center: Vector3, radius: float, island_index: int) -> void:
	var fall := MeshInstance3D.new()
	fall.name = "Aetherfall%02d" % island_index
	var ribbon := BoxMesh.new()
	ribbon.size = Vector3(1.6, 10.0, 0.12)
	fall.mesh = ribbon
	fall.material_override = _transparent_material(Color(0.32, 0.87, 1.0, 0.48))
	fall.position = center + Vector3(radius * 0.54, -5.0, -radius * 0.72)
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fall)
	waterfalls.append({"node": fall, "origin": fall.position, "phase": island_index * 0.9})


func _add_arch(pos: Vector3, island_index: int) -> void:
	var root := Node3D.new()
	root.name = "SideArch%02d" % (island_index + 1)
	root.position = pos
	add_child(root)
	for x in [-1.6, 1.6]:
		_mesh(root, _box(Vector3(0.55, 3.2, 0.7)), mats.rock, Vector3(x, 1.6, 0.0))
	_mesh(root, _box(Vector3(3.8, 0.55, 0.7)), mats.brass, Vector3(0.0, 3.15, 0.0))
	_add_crystal_cluster(root, Vector3(0.0, 3.55, 0.0), 0.7)


func _build_source_cannon() -> void:
	for i in range(route_centers.size() - 1):
		var route_cannon := _create_cannon("RouteCannon%02d" % (i + 1))
		route_cannon.position = route_centers[i] + Vector3(0.0, 0.92, -2.2)
		add_child(route_cannon)
		var pivot: Node3D = route_cannon.get_node("AimPivot")
		pivot.look_at(route_centers[i + 1] + Vector3(0, 2.0, 0), Vector3.UP)
		route_cannons.append(route_cannon)
	_activate_route_cannon(0)


func _activate_route_cannon(index: int) -> void:
	if index < 0 or index >= route_cannons.size():
		return
	if is_instance_valid(loaded_lootling):
		loaded_lootling.queue_free()
	charge_rings.clear()
	cannon_root = route_cannons[index]
	cannon_pivot = cannon_root.get_node("AimPivot")
	muzzle_glow = cannon_pivot.get_node("MuzzleGlow")
	loaded_lootling = _create_lootling(0.58)
	loaded_lootling.name = "LoadedBouncer"
	loaded_lootling.visible = false
	cannon_pivot.add_child(loaded_lootling)
	loaded_lootling.position = Vector3(0.0, 0.0, -1.15)
	if not _uses_stylized_v18():
		for z in [-0.55, -1.25, -1.95]:
			var coil := TorusMesh.new()
			coil.inner_radius = 0.68; coil.outer_radius = 0.76; coil.rings = 16; coil.ring_segments = 8
			charge_rings.append(_mesh(cannon_pivot, coil, mats.violet, Vector3(0, 0, z), Vector3.ONE, Vector3(90, 0, 0)))
	_set_default_ballistic_aim()
	_update_cannon_direction()


func _set_default_ballistic_aim() -> void:
	if current_island_index >= route_centers.size() - 1:
		return
	var delta: Vector3 = route_centers[current_island_index + 1] - cannon_pivot.global_position
	base_aim_yaw = rad_to_deg(atan2(delta.x, -delta.z))
	aim_yaw = base_aim_yaw
	aim_power = 0.72
	var distance := Vector2(delta.x, delta.z).length()
	var speed := _launch_speed()
	var discriminant := pow(speed, 4.0) - GRAVITY * (GRAVITY * distance * distance + 2.0 * delta.y * speed * speed)
	if discriminant > 0.0:
		aim_pitch = clampf(rad_to_deg(atan((speed * speed - sqrt(discriminant)) / (GRAVITY * distance))), MIN_PITCH, MAX_PITCH)
	else:
		aim_pitch = 32.0


func _create_cannon(node_name: String) -> Node3D:
	if _uses_stylized_v18():
		return _create_stylized_cannon(node_name)
	var root := Node3D.new()
	root.name = node_name
	# Layered carriage: readable brass/stone silhouette instead of a stack of
	# plain cylinders.  Collision stays intentionally simple and mobile friendly.
	_mesh(root, _cylinder(1.28, 0.24, 20), mats.rock_dark, Vector3(0, -0.50, 0))
	_mesh(root, _cylinder(1.12, 0.34, 20), mats.bronze, Vector3(0, -0.30, 0))
	_mesh(root, _cylinder(0.90, 0.18, 20), mats.brass_light, Vector3(0, -0.04, 0))
	for corner in [Vector3(-0.86, -0.52, -0.70), Vector3(0.86, -0.52, -0.70), Vector3(-0.86, -0.52, 0.70), Vector3(0.86, -0.52, 0.70)]:
		var foot := PrismMesh.new(); foot.size = Vector3(0.54, 0.28, 0.64)
		_mesh(root, foot, mats.brass, corner, Vector3.ONE, Vector3(0, 0, 90))
	for x in [-0.78, 0.78]:
		var wheel := _mesh(root, _cylinder(0.62, 0.24, 20), mats.brass, Vector3(x, -0.16, 0), Vector3.ONE, Vector3(0, 0, 90))
		_mesh(wheel, _cylinder(0.42, 0.27, 16), mats.rock_dark)
		_mesh(wheel, _cylinder(0.18, 0.30, 12), mats.violet)
		for spoke_angle in [0.0, 45.0, 90.0, 135.0]:
			_mesh(wheel, _box(Vector3(0.10, 0.92, 0.08)), mats.brass_light, Vector3.ZERO, Vector3.ONE, Vector3(spoke_angle, 0, 0))
	# Visible aether receiver identifies the equipped cannon family.
	var receiver_mat: Material = mats.aether if cannon_key == "portal" else mats.red if cannon_key == "thunder" else mats.violet
	var receiver := SphereMesh.new(); receiver.radius = 0.48; receiver.height = 0.92; receiver.radial_segments = 16; receiver.rings = 8
	_mesh(root, receiver, receiver_mat, Vector3(0, 0.32, 0.58), Vector3(0.82, 1.0, 0.82))
	for x in [-0.52, 0.52]:
		_mesh(root, _box(Vector3(0.16, 0.86, 0.20)), mats.brass, Vector3(x, 0.18, 0.42), Vector3.ONE, Vector3(0, 0, 18.0 if x < 0 else -18.0))
	var pivot := Node3D.new()
	pivot.name = "AimPivot"
	pivot.position = Vector3(0, 0.68, 0)
	root.add_child(pivot)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.56 if cannon_key != "thunder" else 0.66
	barrel.bottom_radius = 0.72 if cannon_key != "portal" else 0.64
	barrel.height = 3.05
	barrel.radial_segments = 20
	_mesh(pivot, barrel, mats.cannon, Vector3(0, 0, -1.38), Vector3.ONE, Vector3(90, 0, 0))
	for z in [-0.12, -1.15, -2.55]:
		_mesh(pivot, _cylinder(0.80 if z > -2.0 else 0.88, 0.18, 20), mats.brass, Vector3(0, 0, z), Vector3.ONE, Vector3(90, 0, 0))
	var muzzle_ring := TorusMesh.new(); muzzle_ring.inner_radius = 0.57; muzzle_ring.outer_radius = 0.78; muzzle_ring.rings = 20; muzzle_ring.ring_segments = 8
	_mesh(pivot, muzzle_ring, mats.brass_light, Vector3(0, 0, -2.91), Vector3.ONE, Vector3(90, 0, 0))
	# Variant ornamentation remains compact but makes switching equipment obvious.
	if cannon_key == "thunder":
		for x in [-0.82, 0.82]:
			var spike := PrismMesh.new(); spike.size = Vector3(0.35, 0.78, 0.30)
			_mesh(pivot, spike, mats.red, Vector3(x, 0, -1.35), Vector3.ONE, Vector3(0, 0, 90))
	elif cannon_key == "portal":
		for z in [-0.65, -1.75]:
			var portal_coil := TorusMesh.new(); portal_coil.inner_radius = 0.78; portal_coil.outer_radius = 0.88; portal_coil.rings = 18; portal_coil.ring_segments = 7
			_mesh(pivot, portal_coil, mats.aether, Vector3(0, 0, z), Vector3.ONE, Vector3(90, 0, 0))
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.43
	glow_mesh.height = 0.76
	var glow := _mesh(pivot, glow_mesh, receiver_mat, Vector3(0, 0, -2.98), Vector3(1.0, 0.30, 1.0))
	glow.name = "MuzzleGlow"
	return root


func _create_stylized_cannon(node_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	_mesh(root, _cylinder(1.35, 0.18, 18), mats.stone_dark, Vector3(0, -0.42, 0))
	_mesh(root, _cylinder(1.05, 0.24, 18), mats.stone_main, Vector3(0, -0.24, 0))
	_mesh(root, _cylinder(0.88, 0.14, 18), mats.brass, Vector3(0, -0.06, 0))
	for corner in [Vector3(-0.78, -0.4, -0.62), Vector3(0.78, -0.4, -0.62), Vector3(-0.78, -0.4, 0.62), Vector3(0.78, -0.4, 0.62)]:
		var foot := BoxMesh.new()
		foot.size = Vector3(0.52, 0.18, 0.58)
		_mesh(root, foot, mats.stone_main, corner)
	var pivot := Node3D.new()
	pivot.name = "AimPivot"
	pivot.position = Vector3(0, 0.58, 0)
	root.add_child(pivot)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.48
	barrel.bottom_radius = 0.66
	barrel.height = 3.05
	barrel.radial_segments = 16
	_mesh(pivot, barrel, mats.cannon_dark, Vector3(0, 0, -1.42), Vector3.ONE, Vector3(90, 0, 0))
	for z in [-0.05, -1.12, -2.48]:
		_mesh(pivot, _cylinder(0.78, 0.17, 16), mats.brass, Vector3(0, 0, z), Vector3.ONE, Vector3(90, 0, 0))
	var muzzle_ring := TorusMesh.new()
	muzzle_ring.inner_radius = 0.58
	muzzle_ring.outer_radius = 0.78
	muzzle_ring.rings = 16
	muzzle_ring.ring_segments = 8
	_mesh(pivot, muzzle_ring, mats.brass, Vector3(0, 0, -2.86), Vector3.ONE, Vector3(90, 0, 0))
	var receiver_mat: Material = mats.portal if cannon_key == "portal" else mats.crystal_violet
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.34
	glow_mesh.height = 0.62
	var glow := _mesh(pivot, glow_mesh, receiver_mat, Vector3(0, 0, -2.92), Vector3(1.0, 0.26, 1.0))
	glow.name = "MuzzleGlow"
	return root


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "BouncerPlayer"
	player.position = Vector3(route_centers[0]) + Vector3(-2.0, FLOOR_OFFSET, 2.0)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.46
	capsule.height = 1.45
	collision.shape = capsule
	player.add_child(collision)
	player_visual = _create_lootling(1.0)
	player.add_child(player_visual)
	player_face = player_visual.get_node("Face")
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.52; shadow_mesh.bottom_radius = 0.62; shadow_mesh.height = 0.025; shadow_mesh.radial_segments = 20
	var shadow_mat := _transparent_material(Color(0.04, 0.06, 0.12, 0.42))
	player_shadow = _mesh(self, shadow_mesh, shadow_mat, player.position + Vector3(0, -FLOOR_OFFSET + 0.03, 0))


func _create_lootling(scale_value: float, visual_key := "") -> Node3D:
	var active_key: String = lootling_key if visual_key.is_empty() else visual_key
	var root := Node3D.new()
	root.scale = Vector3.ONE * scale_value
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.66
	body_mesh.height = 1.25
	_mesh(root, body_mesh, mats.get(active_key, mats.bouncer), Vector3.ZERO, Vector3(1.0, 0.9, 0.92))
	for x in [-0.25, 0.25]:
		var foot := SphereMesh.new()
		foot.radius = 0.17
		foot.height = 0.3
		_mesh(root, foot, mats.get(active_key, mats.bouncer), Vector3(x, -0.62, 0.06), Vector3(1.0, 0.65, 1.2))
	for x in [-0.67, 0.67]:
		var arm := SphereMesh.new(); arm.radius = 0.17; arm.height = 0.42
		_mesh(root, arm, mats.get(active_key, mats.bouncer), Vector3(x, -0.05, -0.02), Vector3(0.68, 1.0, 0.72), Vector3(0, 0, -48.0 if x < 0 else 48.0))
	var sprout := Node3D.new()
	sprout.position = Vector3(0, 0.63, 0)
	root.add_child(sprout)
	for x in [-0.18, 0.18]:
		var leaf := SphereMesh.new()
		leaf.radius = 0.18
		leaf.height = 0.36
		_mesh(sprout, leaf, mats.grass_light, Vector3(x, 0.12, 0), Vector3(0.75, 1.2, 0.45), Vector3(0, 0, -30 if x < 0 else 30))
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0, 0.08, -0.59)
	root.add_child(face)
	for x in [-0.22, 0.22]:
		var eye_white := SphereMesh.new(); eye_white.radius = 0.145; eye_white.height = 0.20
		_mesh(face, eye_white, mats.white, Vector3(x, 0.10, 0.0), Vector3(0.82, 1.18, 0.34))
		var pupil := SphereMesh.new(); pupil.radius = 0.086; pupil.height = 0.13
		_mesh(face, pupil, mats.ink, Vector3(x + 0.012, 0.09, -0.045), Vector3(0.78, 1.18, 0.32))
		var glint := SphereMesh.new(); glint.radius = 0.026; glint.height = 0.04
		_mesh(face, glint, mats.white, Vector3(x - 0.018, 0.135, -0.10), Vector3.ONE)
		var cheek := SphereMesh.new(); cheek.radius = 0.075; cheek.height = 0.06
		_mesh(face, cheek, mats.cheek, Vector3(x * 1.48, -0.10, -0.015), Vector3(1.2, 0.58, 0.36))
	var mouth := SphereMesh.new()
	mouth.radius = 0.13
	mouth.height = 0.16
	_mesh(face, mouth, mats.ink, Vector3(0, -0.18, 0), Vector3(0.7, 0.45, 0.35))
	_add_lootling_theme(root, active_key)
	return root


func _add_lootling_theme(root: Node3D, active_key: String) -> void:
	match active_key:
		"magneto":
			for x in [-0.62, 0.62]:
				_mesh(root, _cylinder(0.12, 0.45, 10), mats.brass, Vector3(x, 0.22, 0), Vector3.ONE, Vector3(0, 0, 90))
				var tip := SphereMesh.new(); tip.radius = 0.14; tip.height = 0.28
				_mesh(root, tip, mats.aether, Vector3(x * 1.17, 0.22, 0))
		"blasto":
			for x in [-0.28, 0.0, 0.28]:
				var spike := PrismMesh.new(); spike.size = Vector3(0.22, 0.52, 0.2)
				_mesh(root, spike, mats.brass, Vector3(x, 0.72 - absf(x) * 0.35, 0.08), Vector3.ONE, Vector3(0, 0, x * 55.0))
		"blink":
			var halo := TorusMesh.new(); halo.inner_radius = 0.66; halo.outer_radius = 0.75; halo.rings = 18; halo.ring_segments = 8
			_mesh(root, halo, mats.violet, Vector3(0, 0.05, 0.05), Vector3.ONE, Vector3(90, 0, 0))


func _build_route() -> void:
	for route_index in range(route_centers.size() - 1):
		var pivot: Node3D = route_cannons[route_index].get_node("AimPivot")
		var delta: Vector3 = route_centers[route_index + 1] - pivot.global_position
		var horizontal_distance := Vector2(delta.x, delta.z).length()
		var yaw := atan2(delta.x, -delta.z)
		var speed := 18.0 + 0.72 * 9.5
		var disc := pow(speed, 4.0) - GRAVITY * (GRAVITY * horizontal_distance * horizontal_distance + 2.0 * delta.y * speed * speed)
		var pitch := deg_to_rad(30.0)
		if disc > 0.0:
			pitch = atan((speed * speed - sqrt(disc)) / (GRAVITY * horizontal_distance))
		var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)).normalized()
		var route_right := Vector3(-direction.z, 0.0, direction.x).normalized()
		var origin := pivot.global_position + direction * 2.85
		var velocity := direction * speed
		var contact_distance := maxf(5.0, horizontal_distance - route_radii[route_index + 1] * 0.78)
		var contact_time := contact_distance / maxf(1.0, Vector2(velocity.x, velocity.z).length())
		# Each variant preserves the transparent economy: two 25-coin risks and
		# one risk crystal per hop, while their positions rotate with the seed.
		var risk_patterns := [[1, 4, 5], [0, 3, 5], [2, 5, 6]]
		var active_risks: Array = risk_patterns[(route_variant + route_index) % risk_patterns.size()]
		if _uses_stylized_v18() and route_index == 0:
			var from_center: Vector3 = Vector3(route_centers[0])
			var to_center: Vector3 = Vector3(route_centers[1])
			for i in range(7):
				var t: float = float(i + 1) / 8.0
				var pos: Vector3 = from_center.lerp(to_center, t * 0.62)
				pos.y = from_center.y + 2.2 + sin(t * PI) * 1.6
				var risk: bool = i in active_risks
				var lane_offset: float = sin(float(i) * 1.1 + route_index) * 0.35
				pos.x += lane_offset
				var kind: String = "crystal" if i == 5 else "coin"
				var value: int = 1 if kind == "crystal" else 25 if risk else 15
				_add_flight_pickup(pos, kind, value, risk, route_index)
		else:
			for i in range(7):
				var time := contact_time * float(i + 1) / 8.0
				var pos := origin + velocity * time + Vector3.DOWN * (0.5 * GRAVITY * time * time)
				var risk := i in active_risks
				var lane_offset := (2.0 + route_index * 0.18) * (-1.0 if i % 2 == 0 else 1.0) if risk else sin(float(i) * 0.8 + route_index) * 0.18
				pos += route_right * lane_offset
				var kind := "crystal" if i == 5 else "coin"
				var value := 1 if kind == "crystal" else 25 if risk else 15
				_add_flight_pickup(pos, kind, value, risk, route_index)
		var feature_time := contact_time * 0.58
		var feature_center := origin + velocity * feature_time + Vector3.DOWN * (0.5 * GRAVITY * feature_time * feature_time)
		_add_booster(feature_center + route_right * (3.5 if (route_variant + route_index) % 2 == 0 else -3.5), route_index)
		_add_moving_obstacle(feature_center + route_right * (-4.4 if route_index % 2 == 0 else 4.4), route_right, route_index)
	var first_center: Vector3 = Vector3(route_centers[0])
	var second_center: Vector3 = Vector3(route_centers[1])
	if _uses_stylized_v18():
		if route_centers.size() >= 4:
			_add_portals(
				Vector3(route_centers[2]) + Vector3(0.0, 1.2, 4.5),
				Vector3(route_centers[3]) + Vector3(0.0, 1.2, 3.8)
			)
	else:
		_add_portals(first_center.lerp(second_center, 0.38) + Vector3(2.6, 4.8, 0), second_center.lerp(first_center, 0.24) + Vector3(-2.4, 4.2, 0))


func _add_booster(pos: Vector3, route_index: int) -> void:
	var root := Node3D.new()
	root.name = "AetherBooster%02d" % (route_index + 1)
	root.position = pos
	add_child(root)
	for scale_value in [1.0, 0.72]:
		var ring := TorusMesh.new();ring.inner_radius=0.82*scale_value;ring.outer_radius=1.02*scale_value;ring.rings=16;ring.ring_segments=8
		_mesh(root,ring,mats.booster,Vector3.ZERO,Vector3.ONE,Vector3(90,0,0))
	boosters.append({"node":root,"used":false,"route":route_index,"phase":route_index*1.7})


func _add_moving_obstacle(pos: Vector3, axis: Vector3, route_index: int) -> void:
	var root := Node3D.new()
	root.name = "MovingAetherBar%02d" % (route_index + 1)
	root.position = pos
	add_child(root)
	_mesh(root,_box(Vector3(3.2,0.34,0.34)),mats.red)
	for x in [-1.65,1.65]:
		_mesh(root,_cylinder(0.24,0.58,10),mats.brass,Vector3(x,0,0),Vector3.ONE,Vector3(0,0,90))
	moving_obstacles.append({"node":root,"origin":pos,"axis":axis,"phase":route_index*1.9,"route":route_index,"hit":false})


func _add_flight_pickup(pos: Vector3, kind: String, value: int, risk: bool, route_index: int) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	if kind == "coin":
		var torus := TorusMesh.new()
		torus.inner_radius = 0.38
		torus.outer_radius = 0.58
		torus.rings = 12
		torus.ring_segments = 8
		_mesh(root, torus, mats.coin, Vector3.ZERO, Vector3.ONE * (1.18 if risk else 1.0), Vector3(90, 0, 0))
		if risk:
			var halo := TorusMesh.new()
			halo.inner_radius = 0.64; halo.outer_radius = 0.71; halo.rings = 12; halo.ring_segments = 6
			_mesh(root, halo, mats.violet, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
	else:
		var prism := PrismMesh.new()
		prism.size = Vector3(0.7, 1.1, 0.55)
		_mesh(root, prism, mats.crystal, Vector3.ZERO, Vector3.ONE * 1.18)
	flight_pickups.append({"node": root, "kind": kind, "value": value, "risk": risk, "route": route_index, "taken": false, "origin": pos, "phase": random.randf_range(0.0, 6.28)})


func _add_portals(a_pos: Vector3, b_pos: Vector3) -> void:
	for pos in [a_pos, b_pos]:
		var root := Node3D.new()
		root.position = pos
		add_child(root)
		if _uses_stylized_v18():
			StylizedPortalGenerator.build_portal(root, mats, Callable(self, "_mesh"), Callable(self, "_transparent_material"), wind_streamers)
		else:
			var torus := TorusMesh.new()
			torus.inner_radius = 1.0
			torus.outer_radius = 1.28
			torus.rings = 16
			torus.ring_segments = 10
			_mesh(root, torus, mats.violet, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
			var disc := CylinderMesh.new()
			disc.top_radius = 0.95
			disc.bottom_radius = 0.95
			disc.height = 0.04
			disc.radial_segments = 24
			var portal_mat := _transparent_material(Color(0.3, 0.85, 1.0, 0.42))
			_mesh(root, disc, portal_mat, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
		portal_pair.append(root)


func _build_target_contents() -> void:
	for island_index in range(1, route_centers.size()):
		var chest := _create_chest()
		chest.position = route_centers[island_index] + Vector3(-2.3, 0.66, -0.7)
		chest.set_meta("island_index", island_index)
		add_child(chest)
		route_chests.append(chest)
		for data in [
			[Vector3(-3.4, 0.65, 1.4), "coin", 25],
			[Vector3(-1.2, 0.65, 3.0), "coin", 25],
			[Vector3(1.6, 0.65, 2.4), "crystal", 1],
			[Vector3(3.4, 0.65, 0.2), "coin", 25],
		]:
			var root := Node3D.new()
			root.position = route_centers[island_index] + data[0]
			root.set_meta("island_index", island_index)
			add_child(root)
			if data[1] == "coin":
				var torus := TorusMesh.new(); torus.inner_radius = 0.28; torus.outer_radius = 0.46
				_mesh(root, torus, mats.coin, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
			else:
				var prism := PrismMesh.new(); prism.size = Vector3(0.6, 0.95, 0.5)
				_mesh(root, prism, mats.crystal)
			island_pickups.append({"node": root, "kind": data[1], "value": data[2], "taken": false, "origin": root.position, "island": island_index})
		var contract_positions := [
			Vector3(-4.0, 0.72, 3.2),
			Vector3(4.0, 0.72, -2.6),
			Vector3(0.4, 0.72, 4.8),
		]
		for token_index in range(int(objective_requirements[island_index])):
			var token := Node3D.new()
			token.name = "ObjectiveToken%d_%d" % [island_index, token_index]
			token.position = route_centers[island_index] + contract_positions[token_index]
			token.set_meta("island_index", island_index)
			add_child(token)
			var core := PrismMesh.new()
			core.size = Vector3(0.72, 1.08, 0.62)
			_mesh(token, core, mats.objective, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, 12.0))
			var halo := TorusMesh.new()
			halo.inner_radius = 0.58; halo.outer_radius = 0.69; halo.rings = 14; halo.ring_segments = 8
			_mesh(token, halo, mats.aether, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
			var item := {"node": token, "kind": "coin", "value": 5, "taken": false,
				"origin": token.position, "island": island_index, "objective": true,
				"phase": random.randf_range(0.0, 6.28)}
			island_pickups.append(item)
			objective_tokens.append(item)
	target_chest = route_chests[0]
	target_cannon = route_cannons[1]


func _create_chest() -> Node3D:
	var root := Node3D.new()
	root.name = "TreasureChest"
	_mesh(root, _box(Vector3(1.78, 0.78, 1.12)), mats.wood_light, Vector3(0, 0.42, 0))
	_mesh(root, _box(Vector3(1.86, 0.16, 1.20)), mats.brass, Vector3(0, 0.12, 0))
	for x in [-0.78, 0.78]:
		_mesh(root, _box(Vector3(0.16, 0.92, 1.18)), mats.brass, Vector3(x, 0.46, 0))
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.82, 0.50)
	root.add_child(lid)
	var rounded_lid := CylinderMesh.new(); rounded_lid.top_radius = 0.56; rounded_lid.bottom_radius = 0.56; rounded_lid.height = 1.78; rounded_lid.radial_segments = 16
	_mesh(lid, rounded_lid, mats.wood_light, Vector3(0, 0.0, -0.48), Vector3(1.0, 0.72, 1.0), Vector3(0, 0, 90))
	for x in [-0.78, 0.78]:
		_mesh(lid, _cylinder(0.59, 0.14, 16), mats.brass, Vector3(x, 0, -0.48), Vector3.ONE, Vector3(0, 0, 90))
	_mesh(root, _box(Vector3(0.20, 1.32, 1.20)), mats.brass_light, Vector3(0, 0.58, 0))
	var lock := PrismMesh.new(); lock.size = Vector3(0.48, 0.54, 0.20)
	_mesh(root, lock, mats.violet, Vector3(0, 0.61, -0.66), Vector3.ONE, Vector3(0, 0, 90))
	_mesh(root, _cylinder(0.10, 0.22, 10), mats.aether, Vector3(0, 0.62, -0.80), Vector3.ONE, Vector3(90, 0, 0))
	return root


func _build_trajectory() -> void:
	trajectory_root = Node3D.new()
	trajectory_root.name = "AimPreview"
	add_child(trajectory_root)
	# Only the readable first flight phase is revealed. The separate marker is
	# calculated from the real ballistic parameters and rates the landing zone.
	for i in range(8):
		var sphere := SphereMesh.new()
		sphere.radius = 0.07 + i * 0.003
		sphere.height = sphere.radius * 2.0
		var dot := _mesh(trajectory_root, sphere, mats.coin)
		dot.name = "AimDot%02d" % i
	var marker := CylinderMesh.new()
	marker.top_radius = 0.68
	marker.bottom_radius = 0.68
	marker.height = 0.06
	marker.radial_segments = 24
	landing_marker = _mesh(self, marker, mats.violet)
	trajectory_root.visible = false
	landing_marker.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		return
	var pos := Vector2.ZERO
	var pointer_id := -1
	var press := false
	var release := false
	var motion := false
	if event is InputEventScreenTouch:
		pos = event.position; pointer_id = event.index; press = event.pressed; release = not event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position; pointer_id = event.index; motion = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position; pointer_id = -1; press = event.pressed; release = not event.pressed
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pos = event.position; pointer_id = -1; motion = true
	else:
		return
	if hop_state == HopState.AIMING:
		if press and active_pointer == -999 and not _is_ui_zone(pos):
			active_pointer = pointer_id
			gesture_start = pos
			gesture_last = pos
			gesture_distance = 0.0
			charge_time = 0.0
			aim_power = 0.28
			instruction_changed.emit("HALTEN = AUFLADEN  •  WISCHEN = ZIELEN  •  LOSLASSEN = FEUER")
			return
		if pointer_id != active_pointer:
			return
		if motion:
			_update_aim_gesture(pos)
		elif release:
			active_pointer = -999
			if gesture_distance < AIM_DEADZONE and charge_time < 0.18:
				instruction_changed.emit("WEITER ZIEHEN, DAMIT DIE KANONE AUFLÄDT")
			else:
				_fire()
	elif hop_state == HopState.FLYING and press and not _is_ui_zone(pos):
		activate_special()
	elif hop_state in [HopState.ON_FOOT, HopState.LANDED]:
		if press and active_pointer == -999 and not _is_ui_zone(pos):
			active_pointer = pointer_id
			gesture_start = pos
			gesture_last = pos
			return
		if pointer_id != active_pointer:
			return
		if motion:
			var look_delta := pos - gesture_last
			gesture_last = pos
			target_orbit_yaw = fmod(target_orbit_yaw - look_delta.x * 0.16, 360.0)
			target_orbit_pitch = clampf(target_orbit_pitch + look_delta.y * 0.10, 9.0, 42.0)
		elif release:
			active_pointer = -999


func _is_ui_zone(pos: Vector2) -> bool:
	return pos.y < 180.0 or pos.y > 1240.0


func set_move_vector(value: Vector2) -> void:
	move_input = value.limit_length(1.0)


func set_move_button(direction: Vector2, pressed: bool) -> void:
	if pressed:
		move_input += direction
	else:
		move_input -= direction
	move_input.x = clampf(move_input.x, -1.0, 1.0)
	move_input.y = clampf(move_input.y, -1.0, 1.0)


func request_jump() -> void:
	if hop_state in [HopState.ON_FOOT, HopState.LANDED]:
		jump_buffer = 0.16


func primary_action() -> void:
	if hop_state in [HopState.ON_FOOT, HopState.LANDED] and player.global_position.distance_to(cannon_root.global_position) < 3.1 and current_island_index < route_centers.size() - 1 and (current_island_index == 0 or opened_chests.has(current_island_index)):
		_enter_cannon()
	elif hop_state in [HopState.ON_FOOT, HopState.LANDED] and current_island_index > 0:
		if not opened_chests.has(current_island_index) and _objective_complete(current_island_index) and player.global_position.distance_to(target_chest.global_position) < 2.7:
			_open_chest()
	elif hop_state == HopState.FAILED:
		_retry_checkpoint()


func _enter_cannon() -> void:
	_set_state(HopState.ENTERING)
	move_input = Vector2.ZERO
	player.velocity = Vector3.ZERO
	fired = false
	ability_used = false
	ability_uses = 0
	blasto_impact_used = false
	flight_time = 0.0
	gesture_distance = 0.0
	var tween := create_tween()
	tween.tween_property(player, "global_position", cannon_root.global_position + Vector3(0, 0.8, 0.1), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	player.visible = false
	if player_shadow: player_shadow.visible = false
	loaded_lootling.visible = true
	_set_state(HopState.AIMING)
	instruction_changed.emit("IN ZIELRICHTUNG WISCHEN • HALTEN = KRAFT • LOSLASSEN = FEUER")
	_update_action_prompt()
	_update_trajectory()


func _update_aim_gesture(pos: Vector2) -> void:
	var total := pos - gesture_start
	var delta := pos - gesture_last
	gesture_last = pos
	gesture_distance = minf(total.length(), AIM_MAX_DRAG)
	var yaw_sensitivity := 0.078 if cannon_key == "thunder" else 0.055 if cannon_key == "portal" else 0.065
	var pitch_sensitivity := 0.060 if cannon_key == "thunder" else 0.043 if cannon_key == "portal" else 0.050
	# Shooter-like mapping: right turns right and an upward swipe raises the
	# barrel. This is considerably easier to learn than the old inverted drag.
	aim_yaw = clampf(aim_yaw + delta.x * yaw_sensitivity, base_aim_yaw - 28.0, base_aim_yaw + 28.0)
	aim_pitch = clampf(aim_pitch - delta.y * pitch_sensitivity, MIN_PITCH, MAX_PITCH)
	var normalized := clampf((gesture_distance - AIM_DEADZONE) / (AIM_MAX_DRAG - AIM_DEADZONE), 0.0, 1.0)
	aim_power = maxf(aim_power, lerpf(0.28, 1.0, pow(normalized, 0.78)))
	_update_cannon_direction()
	_update_trajectory()
	aim_changed.emit(aim_pitch, aim_power)


func _aim_direction() -> Vector3:
	var yaw := deg_to_rad(aim_yaw)
	var pitch := deg_to_rad(aim_pitch)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)).normalized()


func _update_cannon_direction() -> void:
	if cannon_pivot == null:
		return
	var direction := _aim_direction()
	cannon_pivot.look_at(cannon_pivot.global_position + direction, Vector3.UP)


func _launch_speed() -> float:
	var modifier := 1.0
	if cannon_key == "thunder": modifier = 1.12
	elif cannon_key == "portal": modifier = 0.94
	return (18.0 + aim_power * 9.5) * modifier


func _update_trajectory() -> void:
	if trajectory_root == null or hop_state != HopState.AIMING:
		return
	trajectory_root.visible = true
	landing_marker.visible = true
	var origin := cannon_pivot.global_position + _aim_direction() * 2.8
	var velocity := _aim_direction() * _launch_speed()
	for i in range(trajectory_root.get_child_count()):
		var t := 0.09 + i * 0.09
		var pos := origin + velocity * t + Vector3.DOWN * (0.5 * GRAVITY * t * t)
		trajectory_root.get_child(i).global_position = pos
	_predict_target_impact(origin, velocity)
	landing_marker.global_position = predicted_landing_position
	landing_marker.material_override = mats.success if predicted_landing_valid else mats.red
	var pulse := 1.0 + sin(idle_time * 7.0) * 0.12
	landing_marker.scale = Vector3(pulse, 1.0, pulse)


func _predict_target_impact(origin: Vector3, velocity: Vector3) -> void:
	predicted_landing_valid = false
	var target_index := mini(current_island_index + 1, route_centers.size() - 1)
	var target_center: Vector3 = route_centers[target_index]
	var target_height := target_center.y + 0.72
	var previous := origin
	var last := origin
	var step := 0.04
	for i in range(int(MAX_FLIGHT_TIME / step)):
		var t := (i + 1) * step
		var pos := origin + velocity * t + Vector3.DOWN * (0.5 * GRAVITY * t * t)
		last = pos
		if velocity.y - GRAVITY * t <= 0.0 and previous.y > target_height and pos.y <= target_height:
			var denominator := previous.y - pos.y
			var blend := clampf((previous.y - target_height) / denominator, 0.0, 1.0) if absf(denominator) > 0.0001 else 0.0
			var impact := previous.lerp(pos, blend)
			var distance := Vector2(impact.x - target_center.x, impact.z - target_center.z).length()
			predicted_landing_valid = distance <= route_radii[target_index] * 0.82
			predicted_landing_position = Vector3(impact.x, target_center.y + 0.08, impact.z)
			return
		previous = pos
	# A failed arc still gets a warning marker rather than silently lying about
	# a valid landing point.
	predicted_landing_position = Vector3(last.x, target_center.y + 0.08, last.z)


func _fire() -> void:
	if fired or hop_state != HopState.AIMING:
		return
	fired = true
	loaded_lootling.visible = false
	trajectory_root.visible = false
	landing_marker.visible = false
	projectile = CharacterBody3D.new()
	projectile.name = "FlyingBouncer"
	add_child(projectile)
	projectile.global_position = cannon_pivot.global_position + _aim_direction() * 2.85
	projectile.velocity = _aim_direction() * _launch_speed()
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	collision.shape = sphere
	projectile.add_child(collision)
	projectile_visual = _create_lootling(0.82)
	projectile.add_child(projectile_visual)
	projectile_visual.scale = Vector3(0.72, 1.28, 0.72)
	var squash := projectile_visual.create_tween()
	squash.tween_property(projectile_visual, "scale", Vector3(1.2, 0.82, 1.2), 0.12).set_trans(Tween.TRANS_BACK)
	squash.tween_property(projectile_visual, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_ELASTIC)
	_cannon_recoil()
	AudioManager.play_launch()
	_set_state(HopState.FLYING)
	flight_time = 0.0
	launched.emit()
	instruction_changed.emit("FLUG STEUERN  •  %d SPEZIALIMPULS%s VERFÜGBAR" % [ability_charges, "E" if ability_charges > 1 else ""])
	_update_action_prompt()


func _cannon_recoil() -> void:
	shake_left = 0.3
	var original := cannon_root.position
	var recoil := cannon_root.create_tween()
	recoil.tween_property(cannon_root, "position", original + _aim_direction() * -0.38, 0.07).set_trans(Tween.TRANS_QUAD)
	recoil.tween_property(cannon_root, "position", original, 0.25).set_trans(Tween.TRANS_BACK)
	_spawn_burst(cannon_pivot.global_position + _aim_direction() * 2.7, mats.violet, 12)


func activate_special() -> void:
	if hop_state != HopState.FLYING or ability_uses >= ability_charges or projectile == null:
		return
	ability_uses += 1
	ability_used = ability_uses >= ability_charges
	if ability_time < 0.0:
		ability_time = flight_time
	var before := projectile.global_position
	if lootling_key == "blink":
		projectile.global_position += projectile.velocity.normalized() * 5.2 + Vector3.UP * 0.6
		_spawn_burst(before, mats.violet, 14)
	else:
		var forward_boost := 4.4 if cannon_key == "portal" else 6.0
		projectile.velocity += projectile.velocity.normalized() * forward_boost + Vector3.UP * (1.7 if cannon_key == "portal" else 2.2)
	projectile_visual.scale = Vector3(1.35, 0.72, 1.35)
	projectile_visual.create_tween().tween_property(projectile_visual, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC)
	_spawn_burst(projectile.global_position, mats.aether, 16)
	shake_left = 0.2
	AudioManager.play_special()
	var remaining := ability_charges - ability_uses
	instruction_changed.emit("SPEZIAL AKTIV • %d LADUNG%s ÜBRIG" % [remaining, "EN" if remaining != 1 else ""] if remaining > 0 else "SPEZIAL VERBRAUCHT • ZUR ZIELINSEL STEUERN")


func _physics_process(delta: float) -> void:
	if hit_stop_left > 0.0:
		hit_stop_left -= delta
		return
	keyboard_move = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if hop_state in [HopState.ON_FOOT, HopState.LANDED]:
		_update_walking(delta)
	elif hop_state == HopState.FLYING:
		_update_flight(delta)


func _update_walking(delta: float) -> void:
	var input_vector := (move_input + keyboard_move).limit_length(1.0)
	var yaw := deg_to_rad(orbit_yaw)
	var camera_forward := Vector3(-sin(yaw), 0.0, -cos(yaw)).normalized()
	var camera_right := Vector3(cos(yaw), 0.0, -sin(yaw)).normalized()
	var direction := (camera_right * input_vector.x + camera_forward * -input_vector.y).normalized() if input_vector.length_squared() > 0.01 else Vector3.ZERO
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if player.is_on_floor():
		coyote_time = 0.12
	elif coyote_time > 0.0:
		coyote_time -= delta
	if jump_buffer > 0.0 and coyote_time > 0.0:
		player.velocity.y = JUMP_SPEED
		jump_buffer = 0.0
		coyote_time = 0.0
		player_visual.scale = Vector3(0.88, 1.18, 0.88)
		AudioManager.play_ui()
	elif not player.is_on_floor():
		player.velocity.y -= WALK_GRAVITY * delta
	else:
		player.velocity.y = -0.6
	player.velocity.x = direction.x * WALK_SPEED
	player.velocity.z = direction.z * WALK_SPEED
	player.move_and_slide()
	var center: Vector3 = route_centers[current_island_index]
	if player.global_position.y < center.y - 11.0:
		_fail_route("BOUNCER IST IN DIE WOLKEN GEFALLEN")
		return
	if direction.length_squared() > 0.01:
		player_visual.rotation.y = lerp_angle(player_visual.rotation.y, atan2(-direction.x, -direction.z), delta * 11.0)
		player_visual.position.y = sin(idle_time * 11.0) * 0.08
		player_visual.scale = Vector3(1.06, 0.94, 1.06)
	else:
		player_visual.position.y = sin(idle_time * 3.0) * 0.035
		player_visual.scale = player_visual.scale.lerp(Vector3.ONE, delta * 8.0)
	if is_instance_valid(player_shadow):
		player_shadow.visible = player.global_position.y < center.y + 4.5
		player_shadow.global_position = Vector3(player.global_position.x, center.y + 0.05, player.global_position.z)
		var shadow_scale := clampf(1.0 - (player.global_position.y - center.y) * 0.12, 0.35, 1.0)
		player_shadow.scale = Vector3(shadow_scale, 1.0, shadow_scale)
	_check_island_pickups()
	_update_action_prompt()


func _update_flight(delta: float) -> void:
	flight_time += delta
	portal_cooldown = maxf(0.0, portal_cooldown - delta)
	var steer := clampf(move_input.x + keyboard_move.x, -1.0, 1.0)
	flight_right_input = lerpf(flight_right_input, steer, minf(1.0, delta * 8.0))
	var horizontal_forward := Vector3(projectile.velocity.x, 0.0, projectile.velocity.z).normalized()
	var flight_right := Vector3(-horizontal_forward.z, 0.0, horizontal_forward.x).normalized()
	projectile.velocity += flight_right * steer * 8.5 * delta
	var lift_input := clampf(-move_input.y - keyboard_move.y, -1.0, 1.0)
	projectile.velocity.y += lift_input * 2.2 * delta
	var horizontal_speed := Vector2(projectile.velocity.x, projectile.velocity.z).length()
	if horizontal_speed > 31.0:
		var horizontal_scale := 31.0 / horizontal_speed
		projectile.velocity.x *= horizontal_scale
		projectile.velocity.z *= horizontal_scale
	projectile.velocity.y -= GRAVITY * delta
	var next_center: Vector3 = route_centers[current_island_index + 1]
	var next_radius: float = route_radii[current_island_index + 1]
	var collision := projectile.move_and_collide(projectile.velocity * delta)
	if collision:
		var horizontal_to_target := Vector2(projectile.global_position.x - next_center.x, projectile.global_position.z - next_center.z).length()
		var ledge_contact := horizontal_to_target < next_radius + 1.0 and projectile.global_position.y >= next_center.y + 0.15 and projectile.global_position.y <= next_center.y + 2.6
		if ledge_contact or (horizontal_to_target < next_radius - 0.45 and projectile.velocity.y <= 0.0):
			_land_on_target()
			return
		var normal: Vector3 = collision.get_normal()
		var bounce_factor := 0.84 if lootling_key == "bouncer" else 0.74
		if lootling_key == "blasto" and not blasto_impact_used:
			blasto_impact_used = true
			bounce_factor = 0.9
			_record_event("destructible", "blasto_impact", 0, projectile.velocity.length())
			_spawn_burst(projectile.global_position, mats.red, 22)
		projectile.velocity = projectile.velocity.bounce(normal) * bounce_factor
		_record_event("bounce", "world", 0, projectile.velocity.length())
		combo += 1
		combo_changed.emit(combo)
		_spawn_burst(projectile.global_position, mats.aether, 7)
		hit_stop_left = 0.035
		shake_left = 0.12
	_check_flight_pickups()
	_check_portals()
	_check_flight_features()
	_spawn_flight_trail(delta)
	projectile_visual.rotation.x += delta * 6.5
	projectile_visual.rotation.z -= delta * 4.0
	if projectile.global_position.distance_to(next_center + Vector3(0, 1.0, 0)) < next_radius - 0.45 and projectile.velocity.y <= 0.0 and projectile.global_position.y <= next_center.y + 2.2:
		_land_on_target()
	elif flight_time >= MAX_FLIGHT_TIME or projectile.global_position.y < next_center.y - 18.0:
		_fail_route("ZIELINSEL VERFEHLT")


func _land_on_target() -> void:
	if hop_state != HopState.FLYING:
		return
	var landing := projectile.global_position
	current_island_index += 1
	var landed_center: Vector3 = route_centers[current_island_index]
	var landing_flat := Vector2(landing.x - landed_center.x, landing.z - landed_center.z)
	var safe_radius: float = route_radii[current_island_index] * 0.72
	var landing_score := clampf(100.0 * (1.0 - landing_flat.length() / maxf(1.0, safe_radius)), 0.0, 100.0)
	landing_scores.append(landing_score)
	if landing_flat.length() > safe_radius:
		landing_flat = landing_flat.normalized() * safe_radius
		landing.x = landed_center.x + landing_flat.x
		landing.z = landed_center.z + landing_flat.y
	landing.y = landed_center.y + FLOOR_OFFSET
	projectile.queue_free()
	projectile = null
	player.global_position = landing
	player.visible = true
	if player_shadow: player_shadow.visible = true
	player_visual.scale = Vector3(1.25, 0.72, 1.25)
	player_visual.create_tween().tween_property(player_visual, "scale", Vector3.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC)
	on_target_island = true
	chest_opened = opened_chests.has(current_island_index)
	target_chest = route_chests[current_island_index - 1]
	if current_island_index < route_cannons.size():
		target_cannon = route_cannons[current_island_index]
		_activate_route_cannon(current_island_index)
	_set_state(HopState.LANDED)
	_spawn_burst(landing, mats.grass_light, 12)
	shake_left = 0.2
	hit_stop_left = 0.045
	AudioManager.play_land(landing_score)
	var landing_label := "PERFEKTE LANDUNG" if landing_score >= 72.0 else "GUTE LANDUNG" if landing_score >= 42.0 else "KNAPPE LANDUNG"
	var required := int(objective_requirements.get(current_island_index, 0))
	objective_changed.emit(int(objective_progress.get(current_island_index, 0)), required, _objective_label(current_island_index))
	instruction_changed.emit("%s  •  %s  •  %s" % [landing_label, _island_name(current_island_index), _objective_label(current_island_index)])
	_update_action_prompt()


func _fail_route(reason: String) -> void:
	if hop_state == HopState.FAILED:
		return
	if projectile:
		_spawn_burst(projectile.global_position, mats.red, 18)
		projectile.queue_free()
		projectile = null
	player.visible = false
	if player_shadow: player_shadow.visible = false
	move_input = Vector2.ZERO
	_set_state(HopState.FAILED)
	AudioManager.play_failure()
	instruction_changed.emit("ROUTE GESCHEITERT  •  %s" % reason)
	action_prompt.emit("LETZTE KANONE WIEDERHOLEN", true)


func _retry_checkpoint() -> void:
	route_attempt += 1
	fired = false
	ability_used = false
	ability_uses = 0
	blasto_impact_used = false
	flight_time = 0.0
	active_pointer = -999
	_activate_route_cannon(current_island_index)
	player.global_position = route_centers[current_island_index] + Vector3(-2.0, FLOOR_OFFSET + 0.2, 1.8)
	player.velocity = Vector3.ZERO
	player.visible = true
	if player_shadow: player_shadow.visible = true
	_set_state(HopState.ON_FOOT if current_island_index == 0 else HopState.LANDED)
	instruction_changed.emit("CHECKPOINT WIEDERHERGESTELLT  •  KEINE ZUSÄTZLICHE ENERGIE")
	_update_action_prompt()


func _check_flight_pickups() -> void:
	var pickup_radius := 1.85 if lootling_key == "magneto" else 1.05
	for item in flight_pickups:
		if item.taken or not is_instance_valid(item.node):
			continue
		if projectile.global_position.distance_to(item.node.global_position) < pickup_radius:
			item.taken = true
			_collect(item.kind, int(item.value), item.node.global_position)
			if bool(item.get("risk", false)):
				instruction_changed.emit("RISIKOLINIE GETROFFEN  •  BONUSBEUTE!")
				_spawn_burst(item.node.global_position, mats.violet, 12)
			item.node.visible = false


func _check_island_pickups() -> void:
	if current_island_index <= 0:
		return
	for item in island_pickups:
		if item.taken or not is_instance_valid(item.node):
			continue
		if int(item.get("island", -1)) != current_island_index:
			continue
		var pickup_radius := 1.55 if lootling_key == "magneto" else 1.05
		if player.global_position.distance_to(item.node.global_position) < pickup_radius:
			item.taken = true
			var objective_target := "objective_island_%d_token_%d" % [current_island_index, int(objective_progress.get(current_island_index, 0)) + 1] if bool(item.get("objective", false)) else ""
			_collect(item.kind, int(item.value), item.node.global_position, objective_target)
			item.node.visible = false
			if bool(item.get("objective", false)):
				objective_progress[current_island_index] = int(objective_progress.get(current_island_index, 0)) + 1
				var current := int(objective_progress[current_island_index])
				var required := int(objective_requirements[current_island_index])
				objective_changed.emit(current, required, _objective_label(current_island_index))
				if current >= required:
					instruction_changed.emit("INSELAUFTRAG ERLEDIGT!  •  SCHATZTRUHE ÖFFNEN")
					AudioManager.play_chest()
				else:
					instruction_changed.emit("AETHER-SIEGEL %d / %d  •  WEITERSUCHEN" % [current, required])
				_update_action_prompt()


func _check_portals() -> void:
	if portal_pair.size() != 2 or portal_cooldown > 0.0:
		return
	for i in range(2):
		if projectile.global_position.distance_to(portal_pair[i].global_position) < 1.25:
			var destination: Node3D = portal_pair[1 - i]
			projectile.global_position = destination.global_position + projectile.velocity.normalized() * 1.5
			projectile.velocity *= 1.1
			portal_cooldown = 0.75
			_record_event("portal", "portal_%d" % i, 0, projectile.velocity.length())
			combo += 1
			combo_changed.emit(combo)
			_spawn_burst(destination.global_position, mats.violet, 14)
			return


func _check_flight_features() -> void:
	for booster in boosters:
		if bool(booster.used) or int(booster.route) != current_island_index:
			continue
		if projectile.global_position.distance_to(booster.node.global_position) < 1.35:
			booster.used = true
			projectile.velocity = projectile.velocity * 1.08 + Vector3.UP * 1.4
			_record_event("booster", "aether_booster_%d" % current_island_index, 0, projectile.velocity.length())
			combo += 1;combo_changed.emit(combo)
			_spawn_burst(booster.node.global_position, mats.booster, 16)
			instruction_changed.emit("AETHER-BOOST!  •  MEHR REICHWEITE")
	for obstacle in moving_obstacles:
		if bool(obstacle.hit) or int(obstacle.route) != current_island_index:
			continue
		if projectile.global_position.distance_to(obstacle.node.global_position) < 1.05:
			obstacle.hit = true
			var normal: Vector3 = (projectile.global_position - obstacle.node.global_position).normalized()
			if normal.length_squared() < 0.1:normal = Vector3.UP
			projectile.velocity = projectile.velocity.bounce(normal) * 0.84
			_record_event("bounce", "moving_aether_bar_%d" % current_island_index, 0, projectile.velocity.length())
			combo += 1;combo_changed.emit(combo)
			_spawn_burst(obstacle.node.global_position, mats.red, 14)
			shake_left = 0.12


func _collect(kind: String, value: int, world_position: Vector3, event_target := "") -> void:
	if kind == "coin": collected_coins += value
	elif kind == "crystal": collected_crystals += value
	var target_id := str(event_target) if not str(event_target).is_empty() else "%s_%d" % [kind, sequence]
	_record_event(kind, target_id, value, projectile.velocity.length() if projectile else player.velocity.length())
	combo += 1
	combo_changed.emit(combo)
	var screen_pos := camera.unproject_position(world_position) if camera and not camera.is_position_behind(world_position) else Vector2(540, 720)
	loot_collected.emit(kind, value, screen_pos)
	flight_tally_changed.emit(collected_coins, collected_crystals)
	AudioManager.play_reward(kind != "coin")
	_spawn_burst(world_position, mats.coin if kind == "coin" else mats.crystal, 8)


func _open_chest() -> void:
	if opened_chests.has(current_island_index):
		return
	if not _objective_complete(current_island_index):
		var current := int(objective_progress.get(current_island_index, 0))
		var required := int(objective_requirements.get(current_island_index, 0))
		instruction_changed.emit("ERST DEN INSELAUFTRAG ERLEDIGEN  •  %d / %d SIEGEL" % [current, required])
		return
	chest_opened = true
	opened_chests[current_island_index] = true
	var lid: Node3D = target_chest.get_node("Lid")
	var tween := lid.create_tween()
	tween.tween_property(lid, "rotation_degrees:x", -105.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_record_event("treasure", "island_%d_chest" % current_island_index, 100, player.velocity.length())
	combo += 1
	combo_changed.emit(combo)
	collected_coins += 100
	loot_collected.emit("treasure", 100, camera.unproject_position(target_chest.global_position))
	flight_tally_changed.emit(collected_coins, collected_crystals)
	AudioManager.play_chest()
	_spawn_burst(target_chest.global_position + Vector3(0, 1.0, 0), mats.coin, 22)
	shake_left = 0.16
	if current_island_index >= route_centers.size() - 1:
		instruction_changed.emit("HIMMELSROUTE ABGESCHLOSSEN!")
		get_tree().create_timer(0.8).timeout.connect(_finish)
	else:
		instruction_changed.emit("SCHATZ GESICHERT!  •  ZUR NÄCHSTEN KANONE LAUFEN")
	_update_action_prompt()


func _record_event(kind: String, target: String, value: int, speed: float) -> void:
	events.append({
		"sequence": sequence,
		"type": kind,
		"target": target,
		"time": flight_time,
		"x": projectile.global_position.x if projectile else player.global_position.x,
		"y": projectile.global_position.y if projectile else player.global_position.y,
		"speed": minf(59.0, speed),
		"value": value,
	})
	sequence += 1


func _finish() -> void:
	if result_sent:
		return
	result_sent = true
	_set_state(HopState.RESULT)
	instruction_changed.emit("ROUTE ABGESCHLOSSEN • BEUTE WIRD GESICHERT")
	var submission := {
		"session_id": str(session.get("session_id", session.get("id", ""))),
		"world_key": expedition_key,
		"angle": clampf(aim_pitch, 18.0, 82.0),
		"power": clampf(aim_power, 0.2, 1.0),
		"ability_time": ability_time,
		"events": events.duplicate(true),
		"checksum": _checksum(),
		"route_score": _average_landing_score(),
		"attempts": route_attempt,
		"visible_coins": collected_coins,
		"visible_crystals": collected_crystals,
	}
	await get_tree().create_timer(0.55).timeout
	finished.emit(submission)


func _average_landing_score() -> float:
	if landing_scores.is_empty():
		return 0.0
	var total := 0.0
	for score in landing_scores:
		total += score
	return total / float(landing_scores.size())


func _checksum() -> String:
	var payload := str(session.get("seed", 0)) + ":" + str(sequence) + ":" + str(int(aim_pitch * 100.0)) + ":" + str(int(aim_power * 1000.0))
	return payload.sha256_text()


func _process(delta: float) -> void:
	idle_time += delta
	_update_pooled_fx(delta)
	if hop_state == HopState.AIMING and active_pointer != -999:
		var charge_duration := 1.0 if cannon_key == "thunder" else 1.35 if cannon_key == "portal" else 1.2
		charge_time = minf(charge_duration, charge_time + delta)
		aim_power = lerpf(0.28, 1.0, charge_time / charge_duration)
		_update_trajectory()
		aim_changed.emit(aim_pitch, aim_power)
	orbit_yaw = lerp_angle(deg_to_rad(orbit_yaw), deg_to_rad(target_orbit_yaw), minf(1.0, delta * 12.0))
	orbit_yaw = rad_to_deg(orbit_yaw)
	orbit_pitch = lerpf(orbit_pitch, target_orbit_pitch, minf(1.0, delta * 12.0))
	for cloud in clouds:
		if is_instance_valid(cloud):
			var origin: Vector3 = cloud.get_meta("origin")
			var phase: float = float(cloud.get_meta("phase"))
			cloud.position.x = origin.x + sin(idle_time * 0.13 + phase) * 1.2
	for item in flight_pickups:
		if not item.taken and is_instance_valid(item.node):
			item.node.rotation.y += delta * 2.2
			item.node.position.y = item.origin.y + sin(idle_time * 2.7 + item.phase) * 0.12
	for item in island_pickups:
		if not item.taken and is_instance_valid(item.node):
			item.node.rotation.y += delta * 2.0
			if bool(item.get("objective", false)):
				item.node.position.y = item.origin.y + sin(idle_time * 3.4 + float(item.get("phase", 0.0))) * 0.16
	for portal in portal_pair:
		if is_instance_valid(portal):
			portal.rotation.z += delta * 1.5
	for booster in boosters:
		if is_instance_valid(booster.node):
			booster.node.rotation.z += delta * 1.9
			var booster_scale:=1.0+sin(idle_time*4.0+float(booster.phase))*0.08
			booster.node.scale=Vector3.ONE*booster_scale
	for obstacle in moving_obstacles:
		if is_instance_valid(obstacle.node):
			obstacle.node.global_position=obstacle.origin+obstacle.axis*sin(idle_time*1.35+float(obstacle.phase))*0.9
			obstacle.node.rotation.y=sin(idle_time*0.8+float(obstacle.phase))*0.22
	for beacon in aether_beacons:
		if is_instance_valid(beacon.crystal):
			beacon.crystal.rotation.y += delta * 1.15
			var beacon_scale := 1.0 + sin(idle_time * 2.8 + float(beacon.phase)) * 0.07
			beacon.crystal.scale = Vector3.ONE * beacon_scale
	for waterfall in waterfalls:
		if is_instance_valid(waterfall.node):
			waterfall.node.position.x = waterfall.origin.x + sin(idle_time * 1.4 + float(waterfall.phase)) * 0.08
			waterfall.node.scale.y = 1.0 + sin(idle_time * 1.8 + float(waterfall.phase)) * 0.025
	for ship in airships:
		if is_instance_valid(ship.node):
			ship.node.position = ship.origin + Vector3(sin(idle_time * 0.19 + float(ship.phase)) * 3.5, sin(idle_time * 0.48 + float(ship.phase)) * 0.5, cos(idle_time * 0.16 + float(ship.phase)) * 1.6)
			ship.node.rotation.y = sin(idle_time * 0.16 + float(ship.phase)) * 0.16
	for animated in wind_streamers:
		if is_instance_valid(animated):
			if animated.has_meta("animate_rotor"):
				animated.rotation.z += delta * 0.65
			elif animated.has_meta("animate_portal"):
				animated.rotation.y += delta * 0.55
	if muzzle_glow and hop_state == HopState.AIMING:
		var pulse := 1.0 + sin(idle_time * 7.0) * 0.12 + aim_power * 0.22
		muzzle_glow.scale = Vector3.ONE * pulse
	for i in range(charge_rings.size()):
		var ring: MeshInstance3D = charge_rings[i]
		if is_instance_valid(ring):
			ring.visible = hop_state in [HopState.ENTERING, HopState.AIMING]
			ring.rotation.z += delta * (1.6 + i * 0.55)
			var ring_pulse := 1.0 + sin(idle_time * 5.0 + i) * 0.06 + aim_power * 0.08
			ring.scale = Vector3.ONE * ring_pulse
	if loaded_lootling and loaded_lootling.visible:
		var load_pulse := 1.0 + sin(idle_time * 5.5) * 0.06
		loaded_lootling.scale = Vector3(1.0 + aim_power * 0.12, load_pulse * (1.0 - aim_power * 0.08), 1.0 + aim_power * 0.12) * 0.58
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var desired := camera.global_position
	var look_target := Vector3.ZERO
	var desired_fov := 61.0
	match hop_state:
		HopState.ON_FOOT:
			if _uses_stylized_v18():
				var yaw := deg_to_rad(orbit_yaw)
				var pitch := deg_to_rad(orbit_pitch)
				var orbit_distance := 14.8
				var orbit_offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * orbit_distance
				desired = player.global_position + orbit_offset + Vector3(0, 1.55, 0)
				var look_ahead: Vector3 = player.global_position.lerp(Vector3(route_centers[mini(current_island_index + 1, route_centers.size() - 1)]), 0.52)
				look_target = look_ahead
				look_target.y = player.global_position.y + 2.4
				desired_fov = 51.0
			else:
				var yaw := deg_to_rad(orbit_yaw)
				var pitch := deg_to_rad(orbit_pitch)
				var orbit_distance := 8.2
				var orbit_offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * orbit_distance
				desired = player.global_position + orbit_offset + Vector3(0, 1.2, 0)
				look_target = player.global_position + Vector3(0, 0.75, 0)
		HopState.ENTERING, HopState.AIMING:
			var aim_dir := _aim_direction()
			var shoulder_right := aim_dir.cross(Vector3.UP).normalized()
			var horizontal_aim := Vector3(aim_dir.x, 0.0, aim_dir.z).normalized()
			# A high over-cannon view keeps the muzzle, first trajectory segment and
			# destination in one readable portrait composition.
			desired = cannon_pivot.global_position - horizontal_aim * 6.4 + Vector3(0, 3.25, 0) + shoulder_right * 0.82
			look_target = cannon_pivot.global_position + aim_dir * 25.0 + Vector3(0, 0.25, 0)
			desired_fov = 71.0
		HopState.FLYING:
			if projectile:
				var flight_dir := projectile.velocity.normalized()
				desired = projectile.global_position - flight_dir * 5.4 + Vector3(0, 1.65, 0)
				look_target = projectile.global_position + flight_dir * 4.2
				desired_fov = 72.0 + clampf(projectile.velocity.length() - 20.0, 0.0, 6.0)
		HopState.LANDED, HopState.RESULT:
			var yaw := deg_to_rad(orbit_yaw)
			var pitch := deg_to_rad(orbit_pitch)
			var orbit_offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 8.0
			desired = player.global_position + orbit_offset + Vector3(0, 1.2, 0)
			look_target = player.global_position + Vector3(0, 0.75, 0)
		HopState.FAILED:
			desired = route_centers[current_island_index] + Vector3(0, 6.5, 10.0)
			look_target = route_centers[current_island_index] + Vector3(0, 1.0, -2.0)
			desired_fov = 58.0
	if hop_state != HopState.FLYING:
		var minimum_camera_distance := 4.8 if hop_state in [HopState.ENTERING, HopState.AIMING] else 4.2
		desired = _resolve_camera_occlusion(look_target, desired, minimum_camera_distance)
	if shake_left > 0.0:
		shake_left -= delta
		desired += Vector3(random.randf_range(-0.12, 0.12), random.randf_range(-0.1, 0.1), 0)
	var camera_response := 8.5 if hop_state == HopState.FLYING else 7.2 if hop_state in [HopState.ENTERING, HopState.AIMING] else 5.5
	camera.global_position = camera.global_position.lerp(desired, minf(1.0, delta * camera_response))
	camera.fov = lerpf(camera.fov, desired_fov, minf(1.0, delta * 5.0))
	if camera.global_position.distance_to(look_target) > 0.2:
		camera.look_at(look_target, Vector3.UP)
	var target_roll := deg_to_rad(-flight_right_input * 3.2) if hop_state == HopState.FLYING else 0.0
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, minf(1.0, delta * 6.0))


func _resolve_camera_occlusion(focus: Vector3, desired: Vector3, minimum_distance := 3.8) -> Vector3:
	if not is_inside_tree() or focus.distance_to(desired) < 0.25:
		return desired
	var query := PhysicsRayQueryParameters3D.create(focus, desired)
	query.collision_mask = 1
	query.collide_with_areas = false
	if is_instance_valid(player):
		query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return desired
	var ray_length := focus.distance_to(desired)
	var safe_length := maxf(float(minimum_distance), focus.distance_to(hit.position) - 0.48)
	return focus.lerp(desired, clampf(safe_length / ray_length, 0.0, 1.0))


func _spawn_flight_trail(delta: float) -> void:
	trail_timer -= delta
	if trail_timer > 0.0 or projectile == null or trail_pool.is_empty():
		return
	trail_timer = [0.11, 0.085, 0.065, 0.052][quality_level]
	var item: Dictionary = trail_pool[trail_cursor]
	trail_cursor = (trail_cursor + 1) % trail_pool.size()
	var trail: MeshInstance3D = item.node
	item.life = 0.48
	item.max_life = 0.48
	trail.visible = true
	trail.scale = Vector3.ONE
	trail.global_position = projectile.global_position - projectile.velocity.normalized() * 0.55
	performance_counters.trail_reuses = int(performance_counters.trail_reuses) + 1


func _update_action_prompt() -> void:
	if player == null:
		return
	if hop_state in [HopState.ON_FOOT, HopState.LANDED]:
		if current_island_index > 0 and not opened_chests.has(current_island_index):
			var objective_done := _objective_complete(current_island_index)
			if not objective_done:
				var current := int(objective_progress.get(current_island_index, 0))
				var required := int(objective_requirements.get(current_island_index, 0))
				action_prompt.emit("AETHER-SIEGEL %d / %d" % [current, required], false)
			else:
				var chest_near := player.global_position.distance_to(target_chest.global_position) < 2.7
				action_prompt.emit("TRUHE ÖFFNEN" if chest_near else "SCHATZTRUHE FINDEN", chest_near)
		elif current_island_index < route_centers.size() - 1:
			var cannon_near := player.global_position.distance_to(cannon_root.global_position) < 3.1
			action_prompt.emit("IN KANONE STEIGEN" if cannon_near else "ZUR NÄCHSTEN KANONE", cannon_near)
		else:
			action_prompt.emit("ROUTE WIRD GESICHERT", false)
	elif hop_state == HopState.FLYING:
		var remaining := ability_charges - ability_uses
		action_prompt.emit("SPEZIALIMPULS ×%d" % remaining if remaining > 0 else "IMPULS VERBRAUCHT", remaining > 0)
	elif hop_state == HopState.FAILED:
		action_prompt.emit("LETZTE KANONE WIEDERHOLEN", true)
	else:
		action_prompt.emit("", false)


func _objective_complete(island_index: int) -> bool:
	if island_index <= 0:
		return true
	return int(objective_progress.get(island_index, 0)) >= int(objective_requirements.get(island_index, 0))


func _objective_label(island_index: int) -> String:
	if expedition_key == "crystal_forge":
		return {
			1: "2 RESONANZKERNE LADEN",
			2: "3 BOHRRELAIS KALIBRIEREN",
			3: "2 PRISMENSCHALTER SYNCHRONISIEREN",
			4: "3 MAG-BAHN-KAPSELN BERGEN",
			5: "3 KRONENSIEGEL BRECHEN",
		}.get(island_index, "SCHMIEDE ERKUNDEN")
	return {
		1: "2 WINDBLUMEN SAMMELN",
		2: "3 KRISTALL-RELAIS AKTIVIEREN",
		3: "2 RUINENSCHALTER FINDEN",
		4: "3 LUFTSCHIFFTEILE BERGEN",
		5: "3 TRESORSIEGEL BRECHEN",
	}.get(island_index, "INSEL ERKUNDEN")


func _island_name(island_index: int) -> String:
	if expedition_key == "crystal_forge":
		return {
			0: "KALIBRIERKAMM",
			1: "RESONANZHOF",
			2: "TIEFENBOHRWERK",
			3: "PRISMENFELD",
			4: "MAG-BAHN-DOCK",
			5: "KRONENSCHMIEDE",
		}.get(island_index, "SCHMIEDEINSEL")
	return {
		0: "WINDMÜHLEN-KLIPPE",
		1: "PILZGARTEN",
		2: "KRISTALLWERK",
		3: "PORTALRUINEN",
		4: "LUFTSCHIFFHAFEN",
		5: "SCHATZFESTE",
	}.get(island_index, "WOLKENINSEL")


func _set_state(next: HopState) -> void:
	hop_state = next
	state_changed.emit(HopState.keys()[next])


func _spawn_burst(pos: Vector3, material: Material, count: int) -> void:
	if spark_pool.is_empty():
		return
	var adjusted_count := mini(int(ceil(float(count) * effect_density)), 28)
	for i in range(adjusted_count):
		var item: Dictionary = spark_pool[spark_cursor]
		spark_cursor = (spark_cursor + 1) % spark_pool.size()
		var spark: MeshInstance3D = item.node
		var direction := Vector3(random.randf_range(-1.0, 1.0), random.randf_range(0.25, 1.3), random.randf_range(-1.0, 1.0)).normalized()
		item.life = 0.42
		item.max_life = 0.42
		item.velocity = direction * random.randf_range(1.8, 4.3)
		spark.material_override = material
		spark.global_position = pos
		spark.scale = Vector3.ONE * random.randf_range(0.72, 1.24)
		spark.visible = true
	performance_counters.burst_reuses = int(performance_counters.burst_reuses) + adjusted_count


func _add_crystal_cluster(parent: Node3D, pos: Vector3, scale_value := 0.52) -> void:
	for data in [[Vector3(-0.25, 0, 0), -14.0], [Vector3(0.2, 0.1, 0.05), 12.0], [Vector3(0.0, -0.05, 0.22), 0.0]]:
		var prism := PrismMesh.new()
		prism.size = Vector3(0.48, 1.25, 0.42)
		_mesh(parent, prism, mats.crystal, pos + data[0], Vector3.ONE * scale_value, Vector3(0, 0, data[1]))


func _mesh(parent: Node, mesh: Mesh, material: Material, pos := Vector3.ZERO, scale_value := Vector3.ONE, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.scale = scale_value
	instance.rotation_degrees = rotation
	# Small scenic details are range-culled before they become sub-pixel noise.
	# Large island plates/cliffs remain visible as route silhouettes.
	if mesh.get_aabb().size.length() < 9.5:
		instance.visibility_range_end = 118.0
		instance.visibility_range_end_margin = 18.0
	if quality_level == 0:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh


## Test hooks use the same production state machine and calculations.
func debug_place_near_cannon() -> void:
	player.global_position = cannon_root.global_position + Vector3(-0.7, 0.0, 1.0)
	_update_action_prompt()


func debug_begin_aim(screen_position: Vector2) -> bool:
	if hop_state != HopState.AIMING or _is_ui_zone(screen_position):
		return false
	active_pointer = -1
	gesture_start = screen_position
	gesture_last = screen_position
	gesture_distance = 0.0
	charge_time = 0.0
	aim_power = 0.28
	return true


func debug_drag_aim(screen_position: Vector2) -> void:
	_update_aim_gesture(screen_position)


func debug_release_aim() -> void:
	active_pointer = -999
	if gesture_distance >= AIM_DEADZONE or charge_time >= 0.18:
		_fire()


func debug_collect_and_land() -> void:
	if projectile == null:
		return
	for item in flight_pickups.slice(0, 5):
		if not item.taken:
			item.taken = true
			_collect(item.kind, int(item.value), item.node.global_position)
			item.node.visible = false
	projectile.global_position = route_centers[current_island_index + 1] + Vector3(0, 1.0, 1.0)
	projectile.velocity = Vector3(0, -2, -1)
	_land_on_target()
	debug_complete_current_objective()


func debug_complete_current_objective() -> void:
	if current_island_index <= 0:
		return
	for item in objective_tokens:
		if int(item.get("island", -1)) != current_island_index or bool(item.get("taken", false)):
			continue
		item.taken = true
		if is_instance_valid(item.node):
			_collect("coin", int(item.value), item.node.global_position, "objective_island_%d_debug" % current_island_index)
			item.node.visible = false
		objective_progress[current_island_index] = int(objective_progress.get(current_island_index, 0)) + 1
	objective_changed.emit(int(objective_progress[current_island_index]), int(objective_requirements[current_island_index]), _objective_label(current_island_index))
	_update_action_prompt()


func debug_open_chest_and_finish() -> void:
	if hop_state != HopState.LANDED:
		return
	player.global_position = target_chest.global_position + Vector3(0.5, FLOOR_OFFSET, 0.5)
	_open_chest()
	for island_index in range(current_island_index + 1, route_centers.size()):
		if not opened_chests.has(island_index):
			opened_chests[island_index] = true
			_record_event("treasure", "island_%d_chest" % island_index, 100, 0.0)
	_finish()
