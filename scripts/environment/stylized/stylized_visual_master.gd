extends RefCounted
class_name StylizedVisualMaster

## V40 — Final Wolkengarten visual master lock (canonical art-direction SSOT).

const VisualVersion := 40

# Camera master (preserves V31 gameplay orbit limits)
const CAMERA_FOV := 52.5
const CAMERA_PITCH := 18.5
const CAMERA_LOOK_HEIGHT := 0.54
const CAMERA_LOOK_AHEAD := 6.35
const CAMERA_FOLLOW_DISTANCE := 11.15
const CAMERA_FOLLOW_HEIGHT := 2.74
const CAMERA_ROUTE_BLEND := 0.48

const PLAYER_SPAWN_OFFSET := Vector3(-1.62, 0.0, 1.78)
const CANNON_OFFSET := Vector3(1.28, 0.92, -2.18)
const CANNON_VISUAL_SCALE := 1.08

# Surface polish multipliers (applied at Q2)
const MACRO_STRENGTH_Q2 := 0.78
const VERTEX_VARIATION_Q2 := 0.10

# Motion production caps
const PORTAL_ROT_SPEED := 0.38
const RING_BOB_AMPLITUDE := 0.016
const CLOUD_DRIFT_SCALE := 0.88


static func apply_world_meta(world: Node3D) -> void:
	if world == null:
		return
	world.set_meta("v40_visual_master_applied", true)
	world.set_meta("v40_visual_version", VisualVersion)


static func validate(world: Node, quality_level: int) -> Array[String]:
	var errors: Array[String] = []
	if world == null or not world.has_meta("v40_visual_master_applied"):
		errors.append("v40_master_not_applied")
	if world != null and world.get("camera") != null:
		var cam: Camera3D = world.camera
		if is_finite(cam.fov) and absf(cam.fov - CAMERA_FOV) > 6.0:
			errors.append("camera_fov_drift")
	var RenderEffects = preload("res://scripts/environment/stylized/stylized_render_effects.gd")
	errors.append_array(RenderEffects.validate(world, quality_level))
	return errors


static func performance_report(world: Node) -> Dictionary:
	var RenderEffects = preload("res://scripts/environment/stylized/stylized_render_effects.gd")
	var CloudGenerator = preload("res://scripts/environment/stylized/stylized_cloud_generator.gd")
	var base: Dictionary = RenderEffects.performance_report(world)
	base["visual_version"] = VisualVersion
	base["vista_islands"] = _visible_vista_count()
	base["renderer"] = "GL Compatibility"
	return base


static func visible_vista_entries() -> Array:
	var WorldComp = preload("res://scripts/environment/stylized/stylized_world_composition.gd")
	var out: Array = []
	for entry in WorldComp.VISTA_ISLANDS:
		if not bool(entry.get("hidden", false)):
			out.append(entry)
	return out


static func _visible_vista_count() -> int:
	return visible_vista_entries().size()
