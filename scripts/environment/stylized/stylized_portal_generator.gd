extends RefCounted
class_name StylizedPortalGenerator

const StylizedCrystalGenerator = preload("res://scripts/environment/stylized/stylized_crystal_generator.gd")


static func build_portal(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array
) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = 1.35
	pedestal.bottom_radius = 1.55
	pedestal.height = 0.42
	pedestal.radial_segments = 14
	mesh_fn.call(root, pedestal, mats.get("stone_dark", mats.rock_dark), Vector3(0, 0.21, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.95
	ring.outer_radius = 1.22
	ring.rings = 20
	ring.ring_segments = 10
	var outer := mesh_fn.call(root, ring, mats.get("portal", mats.violet), Vector3(0, 1.65, 0), Vector3.ONE, Vector3(90, 0, 0))
	outer.set_meta("animate_portal", true)
	animated_nodes.append(outer)
	var inner := TorusMesh.new()
	inner.inner_radius = 0.72
	inner.outer_radius = 0.86
	inner.rings = 18
	inner.ring_segments = 8
	var inner_ring := mesh_fn.call(root, inner, mats.get("crystal_violet", mats.crystal), Vector3(0, 1.65, -0.05), Vector3.ONE, Vector3(90, 0, 0))
	inner_ring.set_meta("animate_portal", true)
	animated_nodes.append(inner_ring)
	var disc := CylinderMesh.new()
	disc.top_radius = 0.72
	disc.bottom_radius = 0.72
	disc.height = 0.05
	disc.radial_segments = 20
	mesh_fn.call(root, disc, transparent_fn.call(Color(0.55, 0.28, 0.95, 0.35)), Vector3(0, 1.65, 0), Vector3.ONE, Vector3(90, 0, 0))
	StylizedCrystalGenerator.add_cluster(root, Vector3(-0.9, 0.35, 0.4), 0.42, mats, mesh_fn)
	StylizedCrystalGenerator.add_cluster(root, Vector3(0.85, 0.32, -0.35), 0.38, mats, mesh_fn, true)
	return root
