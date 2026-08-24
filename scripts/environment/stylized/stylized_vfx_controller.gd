extends RefCounted
class_name StylizedVFXController

## V29 — Particle budgets and lightweight gameplay VFX helpers.


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
		1: return 12
		_: return 18


static func cannon_burst_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 8
		1: return 16
		_: return 22


static func collect_burst_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 4
		1: return 8
		_: return 12


static func ambient_particle_cap(quality_level: int) -> int:
	match clampi(quality_level, 0, 2):
		0: return 0
		1: return 10
		_: return 16


static func clamp_active_particles(active: int, quality_level: int) -> bool:
	return active <= ambient_particle_cap(quality_level) + portal_particle_cap(quality_level) + 30
