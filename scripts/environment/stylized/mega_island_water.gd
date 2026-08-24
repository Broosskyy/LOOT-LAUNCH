extends RefCounted
class_name MegaIslandWater

const MeshLib = preload("res://scripts/environment/stylized/stylized_mesh_library.gd")


static func sample_river_path(control_points: Array, samples_per_segment: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if control_points.size() < 2:
		return points
	for segment_index in range(control_points.size() - 1):
		var a: Vector3 = control_points[segment_index]
		var b: Vector3 = control_points[segment_index + 1]
		var mid: Vector3 = (a + b) * 0.5
		mid.y = lerpf(a.y, b.y, 0.5) - 0.08
		for step in range(samples_per_segment):
			var t: float = float(step) / float(samples_per_segment)
			var u: float = 1.0 - t
			var pos: Vector3 = u * u * a + 2.0 * u * t * mid + t * t * b
			points.append(pos)
	points.append(control_points[control_points.size() - 1])
	return points


static func build_river(
	parent: Node3D,
	river_spec: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int
) -> Dictionary:
	if not bool(river_spec.get("enabled", false)):
		return {"points": [], "mesh": null}
	var control_points: Array = river_spec.get("control_points", [])
	var width: float = float(river_spec.get("width", 1.2))
	var depth: float = float(river_spec.get("depth", 0.18))
	var path: Array[Vector3] = sample_river_path(control_points, 6)
	if path.size() < 2:
		return {"points": [], "mesh": null}
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var water_color := Color(0.28, 0.82, 1.0, 0.58)
	for i in range(path.size() - 1):
		var a: Vector3 = path[i]
		var b: Vector3 = path[i + 1]
		var forward: Vector3 = (b - a)
		forward.y = 0.0
		if forward.length_squared() < 0.0001:
			continue
		forward = forward.normalized()
		var right: Vector3 = Vector3(-forward.z, 0.0, forward.x)
		var half: float = width * 0.5
		var ay: float = a.y - depth
		var by: float = b.y - depth
		var p0 := Vector3(a.x, ay, a.z) - right * half
		var p1 := Vector3(a.x, ay, a.z) + right * half
		var p2 := Vector3(b.x, by, b.z) + right * half
		var p3 := Vector3(b.x, by, b.z) - right * half
		MeshLib._add_quad(st, p0, p1, p2, p3, water_color)
	var mesh: ArrayMesh = st.commit()
	var instance: MeshInstance3D = mesh_fn.call(parent, mesh, mats.get("water", mats.get("aether")), Vector3.ZERO)
	instance.name = "MegaRiver"
	_build_river_banks(parent, path, width, mats, mesh_fn, quality_level, int(river_spec.get("seed", 3200)))
	return {"points": path, "mesh": instance}


static func _build_river_banks(
	parent: Node3D,
	path: Array[Vector3],
	width: float,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	seed: int
) -> void:
	var bank_root := Node3D.new()
	bank_root.name = "MegaRiverBanks"
	parent.add_child(bank_root)
	var step: int = 2 if quality_level >= 2 else 3
	for i in range(0, path.size(), step):
		var pos: Vector3 = path[i]
		for side in [-1.0, 1.0]:
			var offset := Vector3(side * width * 0.72, 0.04, 0.0)
			if i < path.size() - 1:
				var forward: Vector3 = path[i + 1] - path[i]
				forward.y = 0.0
				if forward.length_squared() > 0.01:
					forward = forward.normalized()
					offset = Vector3(-forward.z, 0.0, forward.x) * side * width * 0.72 + Vector3(0.0, 0.04, 0.0)
			var stone := MeshLib.path_stone(i % 8, seed + i * 3)
			mesh_fn.call(bank_root, stone, mats.get("path_stone", mats.get("rock")), pos + offset, Vector3.ONE, Vector3(0, float(i) * 17.0, 0))


static func build_pond(
	parent: Node3D,
	center: Vector3,
	radius_x: float,
	radius_z: float,
	depth: float,
	mats: Dictionary,
	mesh_fn: Callable
) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 14
	var water_color := Color(0.24, 0.78, 0.98, 0.62)
	for i in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var inner := 0.55
		var p0 := center + Vector3(cos(a0) * radius_x * inner, center.y - depth, sin(a0) * radius_z * inner)
		var p1 := center + Vector3(cos(a1) * radius_x * inner, center.y - depth, sin(a1) * radius_z * inner)
		var p2 := center + Vector3(cos(a1) * radius_x, center.y - depth * 0.5, sin(a1) * radius_z)
		var p3 := center + Vector3(cos(a0) * radius_x, center.y - depth * 0.5, sin(a0) * radius_z)
		MeshLib._add_quad(st, p0, p1, p2, p3, water_color)
	var mesh: ArrayMesh = st.commit()
	var instance: MeshInstance3D = mesh_fn.call(parent, mesh, mats.get("water", mats.get("aether")), Vector3.ZERO)
	instance.name = "MegaPond"
	return instance


static func build_waterfall(
	parent: Node3D,
	spec: Dictionary,
	mats: Dictionary,
	mesh_fn: Callable,
	quality_level: int,
	idle_time := 0.0
) -> Dictionary:
	if not bool(spec.get("enabled", false)):
		return {}
	var origin: Vector3 = spec.get("origin", Vector3.ZERO)
	var height: float = float(spec.get("height", 4.0))
	var width: float = float(spec.get("width", 1.4))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var color := Color(0.35, 0.88, 1.0, 0.72)
	var half := width * 0.5
	var top := origin
	var bottom := origin + Vector3(0.0, -height, 0.0)
	MeshLib._add_quad(st, top + Vector3(-half, 0, 0), top + Vector3(half, 0, 0), bottom + Vector3(half, 0, 0), bottom + Vector3(-half, 0, 0), color)
	var mesh: ArrayMesh = st.commit()
	var fall: MeshInstance3D = mesh_fn.call(parent, mesh, mats.get("water", mats.get("aether")), Vector3.ZERO)
	fall.name = "MegaWaterfall"
	if quality_level >= 1:
		var splash := MeshInstance3D.new()
		splash.name = "MegaWaterfallSplash"
		var splash_mesh := SphereMesh.new()
		splash_mesh.radius = 0.55
		splash_mesh.height = 0.35
		splash.mesh = splash_mesh
		splash.material_override = mats.get("water", mats.get("aether"))
		splash.position = bottom + Vector3(0.0, -0.35, 0.0)
		splash.scale = Vector3(1.2, 0.45, 1.2)
		parent.add_child(splash)
	return {"origin": origin, "bottom": bottom, "mesh": fall}
