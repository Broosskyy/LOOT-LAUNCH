extends RefCounted
class_name MegaIslandTypes

## V32 — Shared enums and metadata keys for modular mega-island composition.

enum ModuleType {
	MAIN_PLATEAU,
	SIDE_PLATEAU,
	HIGH_TERRACE,
	LOW_BASIN,
	NARROW_CONNECTOR,
	CLIFF_LEDGE,
	RAVINE_SECTION,
	WATER_BASIN,
}

enum ElevationLayer { LOW, MID, HIGH }

enum ZoneType {
	SAFE_SPAWN_ZONE,
	TRAVERSAL_ZONE,
	COMBAT_ZONE,
	LANDMARK_ZONE,
	OBJECTIVE_ZONE,
	CANNON_ZONE,
	PORTAL_ZONE,
}

enum BiomeTag { GRASSLAND, FOREST, RUINS, CRYSTAL, WATER, FLOWER }

enum RecipeId { RIVER_TERRACE_A, BASIN_B, RAVINE_C }

enum SizeClass { LARGE, MEDIUM }

const ZONE_META_KEY := "mega_zone_type"
const BIOME_META_KEY := "mega_biome_tag"
const NAV_HINT_META_KEY := "mega_nav_hint"
