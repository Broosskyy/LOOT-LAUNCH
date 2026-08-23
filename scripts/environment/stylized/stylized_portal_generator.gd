extends RefCounted
class_name StylizedPortalGenerator

const StylizedCrystalGenerator = preload("res://scripts/environment/stylized/stylized_crystal_generator.gd")
const StylizedTypedAccess = preload("res://scripts/environment/stylized/stylized_typed_access.gd")


static func build_portal(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array
) -> Node3D:
	return build_monument(parent, mats, mesh_fn, transparent_fn, animated_nodes, 1.0)


static func build_monument(
	parent: Node3D,
	mats: Dictionary,
	mesh_fn: Callable,
	transparent_fn: Callable,
	animated_nodes: Array,
	scale_value: float
) -> Node3D:
	var root: Node3D = Node3D.new()
	parent.add_child(root)
	var pedestal: CylinderMesh = CylinderMesh.new()
	pedestal.top_radius = 1.35 * scale_value
	pedestal.bottom_radius = 1.55 * scale_value
	pedestal.height = 0.42 * scale_value
	pedestal.radial_segments = 14
	mesh_fn.call(root, pedestal, StylizedTypedAccess.material(mats, "stone_dark", "rock_dark"), Vector3(0, 0.21 * scale_value, 0))
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.95 * scale_value
	ring.outer_radius = 1.22 * scale_value
	ring.rings = 20
	ring.ring_segments = 10
	var outer: MeshInstance3D = mesh_fn.call(
		root, ring, StylizedTypedAccess.material(mats, "portal", "violet"), Vector3(0, 1.65 * scale_value, 0), Vector3.ONE, Vector3(90, 0, 0)
	) as MeshInstance3D
	outer.set_meta("animate_portal", true)
	animated_nodes.append(outer)
	var inner: TorusMesh = TorusMesh.new()
	inner.inner_radius = 0.72 * scale_value
	inner.outer_radius = 0.86 * scale_value
	inner.rings = 18
	inner.ring_segments = 8
	var inner_ring: MeshInstance3D = mesh_fn.call(
		root, inner, StylizedTypedAccess.material(mats, "crystal_violet", "crystal"), Vector3(0, 1.65 * scale_value, -0.05), Vector3.ONE, Vector3(90, 0, 0)
	) as MeshInstance3D
	inner_ring.set_meta("animate_portal", true)
	animated_nodes.append(inner_ring)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.72 * scale_value
	disc.bottom_radius = 0.72 * scale_value
	disc.height = 0.05
	disc.radial_segments = 20
	var portal_disc_mat: Material = StylizedTypedAccess.transparent_material(transparent_fn, Color(0.55, 0.28, 0.95, 0.32))
	mesh_fn.call(root, disc, portal_disc_mat, Vector3(0, 1.65 * scale_value, 0), Vector3.ONE, Vector3(90, 0, 0))
	StylizedCrystalGenerator.add_cluster(root, Vector3(-0.9, 0.35, 0.4) * scale_value, 0.42 * scale_value, mats, mesh_fn)
	StylizedCrystalGenerator.add_cluster(root, Vector3(0.85, 0.32, -0.35) * scale_value, 0.38 * scale_value, mats, mesh_fn, true)
	return root
