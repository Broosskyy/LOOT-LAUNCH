extends SceneTree

const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")
const Profiles = preload("res://scripts/environment/stylized/mesh/stylized_profile_builder.gd")
const Stones = preload("res://scripts/environment/stylized/mesh/stylized_stone_builder.gd")
const MaterialLibrary = preload("res://scripts/environment/stylized/stylized_material_library.gd")

const VIEWPORT_SIZE := Vector2i(1080, 1920)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var scene := Node3D.new()
	viewport.add_child(scene)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.8, 5.5)
	camera.rotation_degrees = Vector3(-22.0, 0.0, 0.0)
	scene.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.4
	light.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	scene.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.55
	fill.rotation_degrees = Vector3(-20.0, -120.0, 0.0)
	scene.add_child(fill)
	var mats := {}
	MaterialLibrary.apply_palette(
		mats,
		func(color: Color, roughness: float, metallic: float, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.roughness = roughness
			mat.metallic = metallic
			return mat,
		func(color: Color) -> StandardMaterial3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			return mat,
		2
	)
	var items: Array = [
		[Toolkit.beveled_box(Vector3(0.9, 0.45, 0.7), 0.08, 10, 0.86, 0.06, 0.0, 0.1, 2, 2), Vector3(-3.2, 0.0, 0.0), mats.stone_main],
		[Toolkit.irregular_stone(Stones.StoneKind.TALL_ROCK, 0.35, 0.5, 6, 0.12, 0.2, 0.0, 11, 2), Vector3(-1.6, 0.0, 0.2), mats.stone_dark],
		[Toolkit.tapered_pillar(Toolkit.PillarKind.BROKEN_PILLAR, 0.22, 0.18, 1.0, 6, 12, true, 2), Vector3(0.0, 0.0, 0.0), mats.ruin_stone],
		[Toolkit.arch(1.8, 1.1, 0.38, 8, 13, true, 0.05, 2), Vector3(1.8, 0.0, 0.0), mats.ruin_stone],
		[Toolkit.curved_beam([Vector3(-0.5, 0.0, -0.5), Vector3(0.0, 0.25, 0.5), Vector3(0.6, 0.1, 1.4)], Profiles.ProfileKind.STONE_EDGE, 0.3, 0.16, 14, 4, 2), Vector3(3.4, 0.0, -0.2), mats.path_stone],
		[Toolkit.segmented_ring(0.45, 0.7, 0.1, 10, 15, 0.05, 2), Vector3(-3.0, 1.1, 1.2), mats.brass],
		[Toolkit.low_poly_blob(0.42, 0.8, 0.1, 6, 16, 2), Vector3(-1.0, 1.0, 1.0), mats.cloud_soft],
		[Toolkit.roof_cap(Toolkit.RoofKind.HIPPED_ROOF, 1.0, 1.0, 0.4, 0.08, 17, 0.04, 2), Vector3(0.8, 1.0, 1.0), mats.wood],
		[Toolkit.wall_segment(2.0, 0.85, 0.4, 3, 4, true, true, 18, 2), Vector3(2.8, 0.0, 1.2), mats.ruin_stone],
	]
	for item in items:
		var mesh: ArrayMesh = item[0]
		var pos: Vector3 = item[1]
		var material: Material = item[2]
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.material_override = material
		instance.position = pos
		scene.add_child(instance)
	for _i in range(6):
		await process_frame
	await _save(viewport, "res://artifacts/screenshots/v33_toolkit_validation.png")
	quit(0)


func _save(viewport: SubViewport, output_rel: String) -> void:
	await RenderingServer.frame_post_draw
	await process_frame
	var image: Image = viewport.get_texture().get_image()
	var output_path: String = ProjectSettings.globalize_path(output_rel)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	assert(image.save_png(output_path) == OK, "Failed to save %s" % output_path)
