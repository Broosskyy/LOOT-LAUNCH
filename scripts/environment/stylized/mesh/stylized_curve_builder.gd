extends RefCounted
class_name StylizedCurveBuilder

## V33 — Path sampling and profile extrusion along curves.

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")
const Profiles = preload("res://scripts/environment/stylized/mesh/stylized_profile_builder.gd")


static func sample_path(control_points: Array, samples_per_segment: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if control_points.size() < 2:
		return points
	for segment_index in range(control_points.size() - 1):
		var a: Vector3 = control_points[segment_index]
		var b: Vector3 = control_points[segment_index + 1]
		var mid: Vector3 = (a + b) * 0.5
		for step in range(samples_per_segment):
			var t: float = float(step) / float(samples_per_segment)
			var u: float = 1.0 - t
			points.append(u * u * a + 2.0 * u * t * mid + t * t * b)
	points.append(control_points[control_points.size() - 1])
	return points


static func frame_along_path(prev: Vector3, current: Vector3, next: Vector3) -> Basis:
	var forward: Vector3 = next - prev
	if forward.length_squared() < 0.0001:
		forward = next - current
	if forward.length_squared() < 0.0001:
		return Basis.IDENTITY
	forward = forward.normalized()
	var up := Vector3.UP
	var right: Vector3 = up.cross(forward)
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	right = right.normalized()
	up = forward.cross(right).normalized()
	return Basis(right, up, forward)


static func extrude_profile(
	profile: PackedVector2Array,
	path: Array[Vector3],
	seed: int = 0,
	uv_scale: float = 1.0,
	closed_ends: bool = true
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	if profile.size() < 3 or path.size() < 2:
		return ArrayMesh.new()
	var rng := Common.rng(6600 + seed)
	for i in range(path.size()):
		var prev: Vector3 = path[maxi(i - 1, 0)]
		var current: Vector3 = path[i]
		var next: Vector3 = path[mini(i + 1, path.size() - 1)]
		var basis: Basis = frame_along_path(prev, current, next)
		var shade: float = 0.82 + sin(float(i) * 0.7) * 0.06
		var col := Common.shade_color(shade)
		var ring_start: int = vertices.size()
		for j in range(profile.size()):
			var p: Vector2 = profile[j]
			var local := Vector3(p.x, p.y, 0.0) + Common.jitter_vec(rng, 0.008)
			var world: Vector3 = current + basis * local
			vertices.append(world)
			colors.append(col)
			uvs.append(Vector2(float(i) * uv_scale, float(j) * 0.2))
		if i > 0:
			var prev_start: int = ring_start - profile.size()
			for j in range(profile.size()):
				var n: int = (j + 1) % profile.size()
				var a: int = prev_start + j
				var b: int = prev_start + n
				var c: int = ring_start + n
				var d: int = ring_start + j
				indices.append_array([a, b, c, a, c, d])
	if closed_ends:
		_cap_end(vertices, colors, uvs, indices, profile, path[0], frame_along_path(path[0], path[0], path[1]), true)
		var last_i: int = path.size() - 1
		_cap_end(
			vertices, colors, uvs, indices, profile, path[last_i],
			frame_along_path(path[last_i - 1], path[last_i], path[last_i]), false
		)
	return Common.commit_triangles(vertices, colors, uvs, indices, Common.NormalMode.FLAT)


static func _cap_end(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	profile: PackedVector2Array,
	center: Vector3,
	basis: Basis,
	flip: bool
) -> void:
	var hub: int = vertices.size()
	vertices.append(center)
	colors.append(Common.shade_color(0.78))
	uvs.append(Vector2.ZERO)
	var ring_start: int = hub - profile.size()
	for j in range(profile.size()):
		var n: int = (j + 1) % profile.size()
		if flip:
			indices.append_array([hub, ring_start + n, ring_start + j])
		else:
			indices.append_array([hub, ring_start + j, ring_start + n])
