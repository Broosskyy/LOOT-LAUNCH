extends RefCounted
class_name MegaIslandCollision

## V32 — Simplified multi-plateau collision for mega islands.


static func build_collision(body: StaticBody3D, modules: Array, thickness: float, overlap_scale := 0.82) -> Array:
	var shapes: Array = []
	for module in modules:
		var elevation: float = float(module.get("elevation", 0.0))
		var pos: Vector3 = module.get("position", Vector3.ZERO)
		var rx: float = float(module.get("radius_x", 4.0)) * overlap_scale
		var rz: float = float(module.get("radius_z", 4.0)) * overlap_scale
		var collider := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = maxf(rx, rz) * 0.92
		shape.height = thickness + maxf(0.5, elevation + 0.8)
		collider.shape = shape
		collider.position = Vector3(pos.x, elevation - thickness * 0.5, pos.z)
		body.add_child(collider)
		shapes.append(collider)
	return shapes
