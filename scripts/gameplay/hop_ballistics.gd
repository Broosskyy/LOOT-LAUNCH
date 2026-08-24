extends RefCounted
class_name HopBallistics

## V31 — Single source of truth for cannon aim, preview, launch, rings, and reachability.

const GRAVITY := 9.4
const MUZZLE_OFFSET := 2.85
const ABSOLUTE_MIN_PITCH := 4.0
const ABSOLUTE_MAX_PITCH := 72.0
const PITCH_MARGIN := 6.0


static func launch_speed(power: float, cannon_key: String = "standard") -> float:
	var modifier := 1.0
	if cannon_key == "thunder":
		modifier = 1.12
	elif cannon_key == "portal":
		modifier = 0.94
	return (18.0 + clampf(power, 0.0, 1.0) * 9.5) * modifier


static func aim_direction(yaw_deg: float, pitch_deg: float) -> Vector3:
	var yaw := deg_to_rad(yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)).normalized()


static func low_angle_pitch_deg(
	horizontal_distance: float,
	height_delta: float,
	speed: float,
	gravity: float = GRAVITY
) -> float:
	if horizontal_distance < 0.05 or speed <= 0.0:
		return -1.0
	var disc := pow(speed, 4.0) - gravity * (gravity * horizontal_distance * horizontal_distance + 2.0 * height_delta * speed * speed)
	if disc <= 0.0:
		return -1.0
	return rad_to_deg(atan((speed * speed - sqrt(disc)) / (gravity * horizontal_distance)))


static func high_angle_pitch_deg(
	horizontal_distance: float,
	height_delta: float,
	speed: float,
	gravity: float = GRAVITY
) -> float:
	if horizontal_distance < 0.05 or speed <= 0.0:
		return -1.0
	var disc := pow(speed, 4.0) - gravity * (gravity * horizontal_distance * horizontal_distance + 2.0 * height_delta * speed * speed)
	if disc <= 0.0:
		return -1.0
	return rad_to_deg(atan((speed * speed + sqrt(disc)) / (gravity * horizontal_distance)))


static func compute_world_pitch_limits(
	route_centers: Array,
	route_cannons: Array,
	cannon_key: String,
	gravity: float = GRAVITY
) -> Vector2:
	var speed_min := launch_speed(0.28, cannon_key)
	var speed_max := launch_speed(1.0, cannon_key)
	var needed_min := 90.0
	var needed_max := -90.0
	for route_index in range(route_centers.size() - 1):
		if route_index >= route_cannons.size():
			continue
		var pivot: Node3D = route_cannons[route_index].get_node_or_null("AimPivot")
		if pivot == null:
			continue
		var from_pos: Vector3 = pivot.global_position
		var to_pos: Vector3 = route_centers[route_index + 1]
		var horiz := Vector2(to_pos.x - from_pos.x, to_pos.z - from_pos.z).length()
		var dy := to_pos.y - from_pos.y
		for speed in [speed_min, speed_max]:
			var low := low_angle_pitch_deg(horiz, dy, speed, gravity)
			var high := high_angle_pitch_deg(horiz, dy, speed, gravity)
			if low > 0.0:
				needed_min = minf(needed_min, low)
			if high > 0.0:
				needed_max = maxf(needed_max, high)
	if needed_min > 80.0:
		needed_min = 12.0
	if needed_max < 0.0:
		needed_max = 55.0
	return Vector2(
		clampf(needed_min - PITCH_MARGIN, ABSOLUTE_MIN_PITCH, ABSOLUTE_MAX_PITCH - 8.0),
		clampf(needed_max + PITCH_MARGIN, ABSOLUTE_MIN_PITCH + 8.0, ABSOLUTE_MAX_PITCH)
	)


static func route_is_reachable(
	from_pos: Vector3,
	to_pos: Vector3,
	target_radius: float,
	cannon_key: String,
	pitch_min: float,
	pitch_max: float,
	gravity: float = GRAVITY
) -> bool:
	var horiz := Vector2(to_pos.x - from_pos.x, to_pos.z - from_pos.z).length()
	var dy := to_pos.y - from_pos.y
	for power in [0.35, 0.72, 1.0]:
		var speed := launch_speed(power, cannon_key)
		var low := low_angle_pitch_deg(horiz, dy, speed, gravity)
		var high := high_angle_pitch_deg(horiz, dy, speed, gravity)
		if low < 0.0 and high < 0.0:
			continue
		for pitch in [low, high]:
			if pitch < 0.0:
				continue
			if pitch < pitch_min - 0.5 or pitch > pitch_max + 0.5:
				continue
			var yaw := rad_to_deg(atan2(to_pos.x - from_pos.x, -(to_pos.z - from_pos.z)))
			var direction := aim_direction(yaw, pitch)
			var origin := from_pos + direction * MUZZLE_OFFSET
			var velocity := direction * speed
			var impact := predict_impact(origin, velocity, to_pos, target_radius, gravity, 10.0)
			if impact.valid:
				return true
	return false


static func trajectory_point(origin: Vector3, velocity: Vector3, time: float, gravity: float = GRAVITY) -> Vector3:
	return origin + velocity * time + Vector3.DOWN * (0.5 * gravity * time * time)


static func sample_trajectory_points(
	origin: Vector3,
	velocity: Vector3,
	count: int,
	start_time: float = 0.09,
	step: float = 0.09,
	gravity: float = GRAVITY
) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for i in range(count):
		var t := start_time + float(i) * step
		points.append(trajectory_point(origin, velocity, t, gravity))
	return points


static func nominal_route_launch(
	from_pos: Vector3,
	to_pos: Vector3,
	power: float,
	cannon_key: String,
	pitch_min: float,
	pitch_max: float,
	gravity: float = GRAVITY
) -> Dictionary:
	var horiz := Vector2(to_pos.x - from_pos.x, to_pos.z - from_pos.z).length()
	var dy := to_pos.y - from_pos.y
	var speed := launch_speed(power, cannon_key)
	var yaw := rad_to_deg(atan2(to_pos.x - from_pos.x, -(to_pos.z - from_pos.z)))
	var pitch := low_angle_pitch_deg(horiz, dy, speed, gravity)
	if pitch < 0.0:
		pitch = 28.0
	pitch = clampf(pitch, pitch_min, pitch_max)
	var direction := aim_direction(yaw, pitch)
	var origin := from_pos + direction * MUZZLE_OFFSET
	var velocity := direction * speed
	return {
		"yaw": yaw,
		"pitch": pitch,
		"power": power,
		"speed": speed,
		"origin": origin,
		"velocity": velocity,
		"direction": direction,
	}


static func ring_positions_for_route(
	from_pos: Vector3,
	to_pos: Vector3,
	power: float,
	cannon_key: String,
	pitch_min: float,
	pitch_max: float,
	ring_count: int = 5,
	gravity: float = GRAVITY
) -> Array[Vector3]:
	var launch: Dictionary = nominal_route_launch(from_pos, to_pos, power, cannon_key, pitch_min, pitch_max, gravity)
	var origin: Vector3 = launch.origin
	var velocity: Vector3 = launch.velocity
	var horiz_dist := Vector2(to_pos.x - origin.x, to_pos.z - origin.z).length()
	var horiz_speed := maxf(0.1, Vector2(velocity.x, velocity.z).length())
	var flight_time := horiz_dist / horiz_speed
	var points: Array[Vector3] = []
	for i in range(ring_count):
		var t := flight_time * float(i + 1) / float(ring_count + 1)
		points.append(trajectory_point(origin, velocity, t, gravity))
	return points


static func predict_impact(
	origin: Vector3,
	velocity: Vector3,
	target_center: Vector3,
	target_radius: float,
	gravity: float = GRAVITY,
	max_time: float = 10.0,
	step: float = 0.04
) -> Dictionary:
	var target_height := target_center.y + 0.72
	var previous := origin
	var last := origin
	for i in range(int(max_time / step)):
		var t := float(i + 1) * step
		var pos := trajectory_point(origin, velocity, t, gravity)
		last = pos
		if velocity.y - gravity * t <= 0.0 and previous.y > target_height and pos.y <= target_height:
			var denominator := previous.y - pos.y
			var blend := clampf((previous.y - target_height) / denominator, 0.0, 1.0) if absf(denominator) > 0.0001 else 0.0
			var impact := previous.lerp(pos, blend)
			var distance := Vector2(impact.x - target_center.x, impact.z - target_center.z).length()
			return {
				"valid": distance <= target_radius * 0.94,
				"position": Vector3(impact.x, target_center.y + 0.08, impact.z),
				"distance": distance,
			}
		previous = pos
	return {
		"valid": false,
		"position": Vector3(last.x, target_center.y + 0.08, last.z),
		"distance": Vector2(last.x - target_center.x, last.z - target_center.z).length(),
	}
