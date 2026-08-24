extends RefCounted
class_name StylizedWorldComposition

const StartComp = preload("res://scripts/environment/stylized/stylized_start_composition.gd")

## V37 — Final Wolkengarten reference composition SSOT (supersedes V30 camera table).

enum IslandRole { HERO_START, PRIMARY_DESTINATION, ROUTE, PLAYABLE, HERO_LANDMARK, VISTA, MICRO }


const CAMERA_FOV := 54.0
const CAMERA_PITCH := 16.5
const CAMERA_LOOK_HEIGHT := 0.60
const CAMERA_LOOK_AHEAD := 5.85
const CAMERA_FOLLOW_DISTANCE := 10.65
const CAMERA_FOLLOW_HEIGHT := 2.78
const CAMERA_ROUTE_BLEND := 0.50

const PLAYER_SPAWN_OFFSET := Vector3(-1.68, 0.0, 1.82)
const CANNON_OFFSET := Vector3(1.32, 0.92, -2.22)
const CANNON_VISUAL_SCALE := 1.06

const ROUTE_ISLANDS: Array[Dictionary] = [
	{
		"center": Vector3(0.0, 0.0, 5.0),
		"radius": 9.0,
		"thickness": 1.42,
		"role": IslandRole.HERO_START,
	},
	{
		"center": Vector3(5.0, 2.85, -13.8),
		"radius": 9.6,
		"thickness": 1.32,
		"role": IslandRole.PRIMARY_DESTINATION,
	},
	{
		"center": Vector3(-12.0, 19.0, -52.0),
		"radius": 10.8,
		"thickness": 1.28,
		"role": IslandRole.ROUTE,
	},
	{
		"center": Vector3(-13.0, 29.0, -92.0),
		"radius": 11.6,
		"thickness": 1.26,
		"role": IslandRole.PLAYABLE,
	},
	{
		"center": Vector3(9.0, 37.0, -132.0),
		"radius": 11.4,
		"thickness": 1.24,
		"role": IslandRole.ROUTE,
	},
	{
		"center": Vector3(-3.0, 45.0, -172.0),
		"radius": 13.2,
		"thickness": 1.3,
		"role": IslandRole.PLAYABLE,
	},
]

const VISTA_ISLANDS: Array[Dictionary] = [
	{"center": Vector3(-8.5, 5.8, -24.5), "radius": 4.8, "thickness": 0.82, "role": IslandRole.VISTA, "index": 20, "landmark": false},
	{"center": Vector3(16.5, 5.4, -29.5), "radius": 4.6, "thickness": 0.76, "role": IslandRole.VISTA, "index": 21, "landmark": false},
	{"center": Vector3(24.0, 8.8, -39.5), "radius": 8.4, "thickness": 0.98, "role": IslandRole.HERO_LANDMARK, "index": 22, "landmark": true},
	{"center": Vector3(-4.5, 6.2, -33.0), "radius": 4.2, "thickness": 0.78, "role": IslandRole.VISTA, "index": 33, "landmark": false},
	{"center": Vector3(13.5, 7.2, -46.0), "radius": 2.8, "thickness": 0.66, "role": IslandRole.MICRO, "index": 34, "landmark": false},
	{"center": Vector3(-16.0, 7.0, -42.0), "radius": 2.6, "thickness": 0.64, "role": IslandRole.MICRO, "index": 35, "landmark": false},
]


static func apply_wolkengarten(world: Node) -> void:
	world.route_centers.clear()
	world.route_radii.clear()
	for entry in ROUTE_ISLANDS:
		world.route_centers.append(entry["center"])
		world.route_radii.append(entry["radius"])
	if world.has_method("set_composition_thickness"):
		world.set_composition_thickness(_thickness_table())


static func _thickness_table() -> Array:
	var values: Array = []
	for entry in ROUTE_ISLANDS:
		values.append(entry["thickness"])
	return values


static func vista_entries() -> Array:
	return VISTA_ISLANDS.duplicate(true)


static func ring_arc_for_hop(route_index: int, from_center: Vector3, to_center: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var count: int = 5 if route_index == 0 else 4
	for i in range(count):
		var t: float = float(i + 1) / float(count + 1)
		var along: float = 0.74 if route_index == 0 else 0.62
		var pos: Vector3 = from_center.lerp(to_center, t * along)
		var apex: float = 1.6 if route_index == 0 else 1.2
		pos.y = lerpf(from_center.y + 1.0, to_center.y + 0.6, t) + sin(t * PI) * apex
		var side: float = 0.65 if route_index == 0 else 0.45
		pos.x += sin(t * PI * 1.05) * side
		points.append(pos)
	return points


static func composition_markers(world: Node) -> Dictionary:
	var markers := {}
	var floor_y: float = 0.84
	if world != null and world.get("FLOOR_OFFSET") != null:
		floor_y = float(world.FLOOR_OFFSET)
	if world.route_centers.size() > 0:
		markers["player_spawn"] = Vector3(world.route_centers[0]) + Vector3(PLAYER_SPAWN_OFFSET.x, floor_y, PLAYER_SPAWN_OFFSET.z)
		markers["cannon"] = Vector3(world.route_centers[0]) + CANNON_OFFSET
		markers["chest"] = Vector3(world.route_centers[0]) + Vector3(StartComp.CHEST_POS.x, floor_y, StartComp.CHEST_POS.z)
		markers["pad"] = Vector3(world.route_centers[0]) + Vector3(StartComp.PAD_POS.x, floor_y, StartComp.PAD_POS.z)
	if world.route_centers.size() > 1:
		markers["primary_destination"] = Vector3(world.route_centers[1]) + Vector3(0.0, 1.2, 0.0)
		markers["portal"] = Vector3(world.route_centers[1]) + Vector3(0.2, 1.4, 4.0)
		markers["route_ring_mid"] = ring_arc_for_hop(0, Vector3(world.route_centers[0]), Vector3(world.route_centers[1]))[2]
	for entry in VISTA_ISLANDS:
		if entry.get("landmark", false):
			markers["hero_landmark"] = entry["center"]
			break
	return markers


static func assert_v25_screen_bands(metrics: Dictionary, context: String) -> void:
	if metrics.has("cannon") and metrics["cannon"]["in_view"]:
		assert(metrics["cannon"]["x_pct"] >= 0.58 and metrics["cannon"]["x_pct"] <= 0.92,
			"%s: cannon x=%.2f outside 58-92%%" % [context, metrics["cannon"]["x_pct"]])
	if metrics.has("primary_destination") and metrics["primary_destination"]["in_view"]:
		assert(metrics["primary_destination"]["y_pct"] <= 0.42,
			"%s: primary destination y=%.2f too low on screen" % [context, metrics["primary_destination"]["y_pct"]])
	if metrics.has("portal") and metrics["portal"]["in_view"]:
		assert(metrics["portal"]["y_pct"] <= 0.45,
			"%s: portal y=%.2f too low on screen" % [context, metrics["portal"]["y_pct"]])
	var visible_islands := 0
	for key in ["primary_destination", "hero_landmark", "route_ring_mid"]:
		if metrics.has(key) and metrics[key]["in_view"]:
			visible_islands += 1
	assert(visible_islands >= 3,
		"%s: expected at least 3 composition landmarks visible, got %d" % [context, visible_islands])


static func project_marker_screen(world: Node, marker_name: String) -> Vector2:
	var markers: Dictionary = composition_markers(world)
	assert(markers.has(marker_name), "Unknown marker: %s" % marker_name)
	var camera: Camera3D = world.camera
	return camera.unproject_position(markers[marker_name]) if camera else Vector2.ZERO
