extends SceneTree

const V41Benchmark = preload("res://scripts/environment/stylized/benchmark/v41_visual_benchmark.gd")
const CliffBuilder = preload("res://scripts/environment/stylized/benchmark/v41_cliff_builder.gd")
const PathKit = preload("res://scripts/environment/stylized/benchmark/v41_path_kit.gd")
const RuinKit = preload("res://scripts/environment/stylized/benchmark/v41_ruin_kit.gd")
const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")
const ShaderLibrary = preload("res://scripts/environment/stylized/stylized_shader_library.gd")

const STEP := 0.033


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(ShaderLibrary.validate_shaders().is_empty(), "Shader compile validation failed")
	var validation_errors: Array[String] = V41Benchmark.validate()
	assert(validation_errors.is_empty(), "V41 module validation: %s" % ", ".join(validation_errors))
	assert(CliffBuilder.all_kinds().size() >= 10, "Cliff variants required")
	assert(PathKit.all_kinds().size() >= 5, "Path stone variants required")
	assert(RuinKit.all_kinds().size() >= 8, "Ruin kit variants required")
	for kind in CliffBuilder.all_kinds():
		var mesh: ArrayMesh = CliffBuilder.build_module(kind, 2.4, 4.0, 4100 + kind)
		assert(mesh.get_surface_count() > 0, "Cliff module mesh empty: %s" % CliffBuilder.kind_name(kind))
	for kind in PathKit.all_kinds():
		var stone: ArrayMesh = PathKit.build_stone(kind, 4200)
		assert(stone.get_surface_count() > 0, "Path stone empty: %s" % PathKit.kind_name(kind))
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	for quality in [0, 2]:
		var world = World.new()
		root.add_child(world)
		var game_state = root.get_node("GameState")
		game_state.settings.quality = quality
		world.begin(
			{"seed": 4100, "session_id": "v41-benchmark-q%d" % quality, "world_key": "v41_benchmark"},
			"bouncer",
			"standard",
			false,
			0
		)
		await process_frame
		assert(world.has_meta("v41_benchmark_applied"), "V41 meta required")
		assert(int(world.get_meta("v41_visual_version")) == 41, "V41 version meta")
		var palette_errors: Array[String] = MaterialLibrary.validate_palette(world.mats)
		assert(palette_errors.is_empty(), "Palette: %s" % ", ".join(palette_errors))
		var island: Node3D = world.get_node_or_null("SkyIsland00") as Node3D
		assert(island != null, "Benchmark island 0 required")
		assert(island.has_meta("v41_benchmark_island"), "V41 island meta required")
		var vista: Node3D = world.get_node_or_null("V41Vista_81") as Node3D
		assert(vista != null, "Background vista required")
		assert(world.route_cannons.size() >= 1, "Cannon required")
		assert(world.player != null, "Player required")
		assert(world.route_centers.size() == 2, "V41 uses two-island route for flight")
		world.queue_free()
		await process_frame
	print("V41 procedural benchmark validation passed")
	quit(0)
