extends SceneTree

## Captures a real in-game frame from the Wolkengarten expedition world (V18.1A).

const OUTPUT_REL := "res://artifacts/screenshots/v18_1_real_ingame.png"
const WORLD_SCRIPT := "res://scripts/gameplay/island_hopping_world.gd"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1080, 1920)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	viewport.transparent_bg = false
	root.add_child(viewport)
	var World = load(WORLD_SCRIPT)
	var world = World.new()
	viewport.add_child(world)
	world.begin(
		{"seed": 1818, "session_id": "v18-1-screenshot", "world_key": "wolkengarten"},
		"bouncer",
		"standard",
		false,
		0
	)
	for _i in range(6):
		await process_frame
	await create_timer(0.45).timeout
	_compose_camera(world)
	for _i in range(30):
		world._update_camera(0.016)
		await process_frame
	await RenderingServer.frame_post_draw
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var output_path: String = ProjectSettings.globalize_path(OUTPUT_REL)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var image: Image = viewport.get_texture().get_image()
	var err: Error = image.save_png(output_path)
	assert(err == OK, "Screenshot save failed with code %d at %s" % [err, output_path])
	print("V18.1A ingame screenshot saved: ", output_path, " size=", image.get_size())
	quit(0)


func _compose_camera(world: Node) -> void:
	var player_pos: Vector3 = world.player.global_position
	var cannon_pos: Vector3 = world.cannon_root.global_position
	var focus: Vector3 = player_pos.lerp(cannon_pos, 0.35)
	focus.y += 0.55
	var camera_pos: Vector3 = player_pos + Vector3(4.2, 4.8, 7.8)
	world.camera.current = true
	world.camera.global_position = camera_pos
	world.camera.look_at(focus, Vector3.UP)
	world.camera.fov = 52.0
	world.orbit_yaw = 20.0
	world.orbit_pitch = 14.0
	world.target_orbit_yaw = world.orbit_yaw
	world.target_orbit_pitch = world.orbit_pitch
