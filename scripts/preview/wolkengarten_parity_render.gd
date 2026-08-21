extends RefCounted

## Phase 17C — Rodin/Hyper3D visual parity targets for preview lighting.

const EMISSION_ENERGY := 0.06
const EMISSION_COLOR := Color(1.0, 1.0, 1.0)
const NORMAL_SCALE := 1.0

const SKY_TOP := Color("3d6f9e")
const SKY_HORIZON := Color("6fa8cc")
const SKY_GROUND_HORIZON := Color("243f5c")
const SKY_GROUND_BOTTOM := Color("121f2e")

const AMBIENT_COLOR := Color("5a6d82")
const AMBIENT_ENERGY := 0.14

const SUN_COLOR := Color("f2f6ff")
const SUN_ENERGY := 0.46

const TONEMAP_EXPOSURE := 0.72
const GLOW_INTENSITY := 0.02
const GLOW_THRESHOLD := 1.68


static func apply_preview_environment(environment: Environment, sky_material: ProceduralSkyMaterial) -> void:
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_horizon_color = SKY_GROUND_HORIZON
	sky_material.ground_bottom_color = SKY_GROUND_BOTTOM
	sky_material.sun_angle_max = 8.0
	sky_material.sun_curve = 0.02
	sky_material.ground_curve = 0.08
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOR
	environment.ambient_light_energy = AMBIENT_ENERGY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = TONEMAP_EXPOSURE
	environment.tonemap_white = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = GLOW_INTENSITY
	environment.glow_bloom = 0.01
	environment.glow_hdr_threshold = GLOW_THRESHOLD
	environment.fog_enabled = false


static func apply_preview_sun(sun: DirectionalLight3D) -> void:
	sun.light_color = SUN_COLOR
	sun.light_energy = SUN_ENERGY


static func print_root_cause_audit() -> void:
	print("Phase 17C parity audit — root causes addressed:")
	print("  - removed fill directional (multi-light wash)")
	print("  - lowered ambient 0.36 -> ", AMBIENT_ENERGY)
	print("  - neutral sun (no warm yellow on grass)")
	print("  - exposure 0.88 -> ", TONEMAP_EXPOSURE)
	print("  - glow 0.08 -> ", GLOW_INTENSITY, " threshold ", GLOW_THRESHOLD)
	print("  - fog disabled (haze wash)")
	print("  - dark sky ground hemisphere (gray disk)")
	print("  - disabled albedo-derived AO proxy (brightened grass)")
	print("  - emission energy -> ", EMISSION_ENERGY, " texture-driven violet")
