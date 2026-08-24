extends SceneTree

const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const Stones = preload("res://scripts/environment/stylized/mesh/stylized_stone_builder.gd")
const Profiles = preload("res://scripts/environment/stylized/mesh/stylized_profile_builder.gd")
const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var builders: Array = [
		["beveled_box", func(): return Toolkit.beveled_box(Vector3(1.0, 0.5, 0.8), 0.08, 42, 0.86, 0.05, 0.02, 0.08, 2, 2)],
		["irregular_stone", func(): return Toolkit.irregular_stone(Stones.StoneKind.BLOCK_STONE, 0.35, 0.28, 6, 0.1, 0.2, 0.0, 77, 2)],
		["tapered_pillar", func(): return Toolkit.tapered_pillar(Toolkit.PillarKind.FULL_PILLAR, 0.28, 0.2, 1.1, 6, 88, false, 2)],
		["arch", func(): return Toolkit.arch(2.0, 1.2, 0.4, 8, 99, false, 0.05, 2)],
		["curved_beam", func(): return Toolkit.curved_beam([Vector3(0, 0, 0), Vector3(0.5, 0.2, 1.2), Vector3(0, 0.1, 2.4)], Profiles.ProfileKind.STONE_EDGE, 0.35, 0.18, 120, 4, 2)],
		["segmented_ring", func(): return Toolkit.segmented_ring(0.6, 0.9, 0.12, 10, 130, 0.04, 2)],
		["low_poly_blob", func(): return Toolkit.low_poly_blob(0.5, 0.85, 0.08, 6, 140, 2)],
		["roof_cap", func(): return Toolkit.roof_cap(Toolkit.RoofKind.HIPPED_ROOF, 1.0, 1.0, 0.45, 0.08, 150, 0.04, 2)],
		["wall_segment", func(): return Toolkit.wall_segment(2.4, 0.9, 0.45, 3, 4, true, true, 160, 2)],
		["terrain_contour", func(): return Toolkit.terrain_contour_ring(1.2, 12, 0.08, 0.9, 0.15, 170, 2)],
		["path_stone", func(): return Toolkit.path_stone(3, 180, 2)],
		["octagonal_plinth", func(): return Toolkit.octagonal_plinth(0.7, 0.45, 0.55, 190, 2)],
	]
	for entry in builders:
		var name: String = entry[0]
		var build_fn: Callable = entry[1]
		var mesh_a: ArrayMesh = build_fn.call()
		var mesh_b: ArrayMesh = build_fn.call()
		var report: Dictionary = Toolkit.validate(mesh_a)
		assert(report.errors.is_empty(), "%s validation failed: %s" % [name, str(report.errors)])
		assert(report.triangles >= 4, "%s too few triangles" % name)
		assert(report.triangles <= 4000, "%s triangle budget exceeded: %d" % [name, report.triangles])
		assert(report.bounds.size.length() > 0.05, "%s bounds too small" % name)
		assert(report.max_edge <= Common.MAX_SAFE_EDGE, "%s edge too long: %f" % [name, report.max_edge])
		var hint: Dictionary = Toolkit.collision_hint(mesh_a)
		assert(hint.has("type"), "%s collision hint missing" % name)
	var varied: ArrayMesh = Toolkit.beveled_box(Vector3(1.0, 0.5, 0.8), 0.08, 1, 0.86, 0.0, 0.0, 0.0, 1, 2)
	var varied_b: ArrayMesh = Toolkit.beveled_box(Vector3(1.0, 0.5, 0.8), 0.08, 2, 0.86, 0.12, 0.0, 0.12, 2, 2)
	var rep_a: Dictionary = Toolkit.validate(varied)
	var rep_b: Dictionary = Toolkit.validate(varied_b)
	assert(rep_a.bounds != rep_b.bounds or rep_a.triangles != rep_b.triangles, "Parameter variation should change geometry")
	var World = load("res://scripts/gameplay/island_hopping_world.gd")
	var world = World.new()
	root.add_child(world)
	world.begin({"seed": 3300, "session_id": "v33", "world_key": "wolkengarten"}, "bouncer", "standard", false, 0)
	await process_frame
	assert(world.get_node_or_null("SkyIsland05") != null, "World must load with mega island")
	var unreachable: Array = world.debug_validate_all_routes_reachable()
	assert(unreachable.is_empty(), "Traversal regression: %s" % str(unreachable))
	print("V33 stylized mesh toolkit passed: builders=%d" % builders.size())
	quit(0)
