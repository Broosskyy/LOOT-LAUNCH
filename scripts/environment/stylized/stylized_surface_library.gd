extends RefCounted
class_name StylizedSurfaceLibrary

## V38 — Surface 3.0 material family profiles (shared parameters, no per-object materials).

enum StoneFamily { CLIFF, PATH, RUIN, ARCHITECTURE }
enum MetalFamily { DARK_METAL, BRASS }


static func quality_profile(quality_level: int) -> Dictionary:
	var q: int = clampi(quality_level, 0, 2)
	return {
		"use_shaders": q >= 1,
		"use_macro_textures": q >= 2,
		"macro_strength": [0.0, 0.55, 1.0][q],
		"vertex_variation": [0.04, 0.08, 0.12][q],
	}


static func stone_profile(family: int) -> Dictionary:
	match family:
		StoneFamily.PATH:
			return {
				"cool_shadow": 0.07, "warm_highlight": 0.12, "macro_mul": 0.65,
				"secondary_tint": Color("d8c8b0"), "moss_strength": 0.0, "wet_darken": 0.08,
			}
		StoneFamily.RUIN:
			return {
				"cool_shadow": 0.11, "warm_highlight": 0.09, "macro_mul": 0.85,
				"secondary_tint": Color("9a8e7e"), "moss_strength": 0.18, "wet_darken": 0.12,
			}
		StoneFamily.ARCHITECTURE:
			return {
				"cool_shadow": 0.08, "warm_highlight": 0.11, "macro_mul": 0.55,
				"secondary_tint": Color("c8beb0"), "moss_strength": 0.08, "wet_darken": 0.06,
			}
		_:
			return {
				"cool_shadow": 0.16, "warm_highlight": 0.08, "macro_mul": 1.0,
				"secondary_tint": Color("788088"), "moss_strength": 0.05, "wet_darken": 0.14,
			}


static func metal_profile(family: int) -> Dictionary:
	if family == MetalFamily.BRASS:
		return {
			"metallic": 0.74, "roughness": 0.34, "bevel_boost": 0.14,
			"rim_tint": Color("ffe8a8"), "recess_darken": 0.22,
		}
	return {
		"metallic": 0.64, "roughness": 0.40, "bevel_boost": 0.10,
		"rim_tint": Color("a8b8d0"), "recess_darken": 0.28,
	}


static func grass_profile(variant: String) -> Dictionary:
	match variant:
		"light":
			return {"dry_tint": Color("6aaa58"), "edge_strength": 0.10, "patch_strength": 0.09}
		"dark":
			return {"dry_tint": Color("3a7044"), "edge_strength": 0.14, "patch_strength": 0.07}
		_:
			return {"dry_tint": Color("5a9850"), "edge_strength": 0.12, "patch_strength": 0.10}
