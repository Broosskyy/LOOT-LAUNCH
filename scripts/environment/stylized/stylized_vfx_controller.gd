extends RefCounted
class_name StylizedVFXController

## V29/V39 — Particle budgets and lightweight gameplay VFX helpers.

const RenderEffects = preload("res://scripts/environment/stylized/stylized_render_effects.gd")


static func particle_scale_for_quality(quality_level: int) -> float:
	match clampi(quality_level, 0, 2):
		0: return 0.45
		1: return 0.78
		_: return 1.0


static func burst_count(requested: int, quality_level: int, cap: int) -> int:
	var scaled: int = int(ceil(float(requested) * particle_scale_for_quality(quality_level)))
	return clampi(scaled, 0, cap)


static func portal_particle_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 4
		1: return 10
		_: return 14


static func cannon_burst_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 8
		1: return 14
		_: return 20


static func cannon_smoke_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 0
		1: return 4
		_: return 6


static func collect_burst_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 4
		1: return 8
		_: return 12


static func ambient_particle_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 0
		1: return 8
		_: return 12


static func waterfall_mist_cap(quality_level: int) -> int:
	var profile: Dictionary = RenderEffects.quality_profile(quality_level)
	return int(profile.get("waterfall_particles", 0))


static func clamp_active_particles(active: int, quality_level: int) -> bool:
	return active <= ambient_particle_cap(quality_level) + portal_particle_cap(quality_level) + RenderEffects.MAX_PARTICLES_Q2


static func spawn_waterfall_mist(parent: Node3D, pos: Vector3, mats: Dictionary, mesh_fn: Callable, quality_level: int) -> Array:
	var nodes: Array = []
	var cap: int = waterfall_mist_cap(quality_level)
	if cap <= 0 or parent == null:
		return nodes
	var mist_mat: Material = mats.get("water", mats.get("aether"))
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 6
	sphere.rings = 4
	for i in cap:
		var t := float(i)
		var offset := Vector3(sin(t * 2.1) * 0.28, cos(t * 1.6) * 0.12, sin(t * 1.4 + 0.8) * 0.22)
		var scale_value := Vector3.ONE * (0.42 + fmod(t * 0.17, 0.28))
		var puff: MeshInstance3D = mesh_fn.call(parent, sphere, mist_mat, pos + offset, scale_value) as MeshInstance3D
		if puff != null:
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			puff.set_meta("mist_phase", float(i) * 1.37)
			nodes.append(puff)
	return nodes
