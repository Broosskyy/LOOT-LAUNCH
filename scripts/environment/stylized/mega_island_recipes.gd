extends RefCounted
class_name MegaIslandRecipes

const Types = preload("res://scripts/environment/stylized/mega_island_types.gd")


static func recipe_for(id: int, seed: int) -> Dictionary:
	match id:
		Types.RecipeId.RIVER_TERRACE_A:
			return recipe_river_terrace(seed)
		Types.RecipeId.BASIN_B:
			return recipe_basin(seed)
		Types.RecipeId.RAVINE_C:
			return recipe_ravine(seed)
		_:
			return recipe_river_terrace(seed)


static func recipe_river_terrace(seed: int) -> Dictionary:
	return {
		"id": Types.RecipeId.RIVER_TERRACE_A,
		"name": "river_terrace_a",
		"seed": seed,
		"size_class": Types.SizeClass.LARGE,
		"plateau_count": 4,
		"elevation_layers": 3,
		"modules": [
			_module(Types.ModuleType.MAIN_PLATEAU, Vector3(0.0, 0.0, 0.0), 10.2, 8.6, 0.0),
			_module(Types.ModuleType.HIGH_TERRACE, Vector3(-5.4, 0.0, 3.2), 5.8, 4.8, 1.45),
			_module(Types.ModuleType.SIDE_PLATEAU, Vector3(6.2, 0.0, 2.8), 4.6, 4.0, 0.75),
			_module(Types.ModuleType.LOW_BASIN, Vector3(3.8, 0.0, -3.6), 5.2, 4.4, -0.85),
			_module(Types.ModuleType.NARROW_CONNECTOR, Vector3(1.8, 0.0, 0.6), 2.8, 2.2, 0.35),
			_module(Types.ModuleType.RAVINE_SECTION, Vector3(-1.2, 0.0, -5.2), 3.4, 2.6, -0.55),
			_module(Types.ModuleType.CLIFF_LEDGE, Vector3(-7.8, 0.0, -4.8), 3.0, 2.4, 1.1),
			_module(Types.ModuleType.WATER_BASIN, Vector3(5.0, 0.0, -1.8), 2.8, 2.4, -0.35),
		],
		"river": {
			"enabled": true,
			"source": Vector3(-6.8, 1.52, 5.4),
			"width": 1.35,
			"depth": 0.22,
			"control_points": [
				Vector3(-6.8, 1.52, 5.4),
				Vector3(-4.2, 1.38, 3.8),
				Vector3(-1.5, 0.95, 1.2),
				Vector3(1.0, 0.55, -0.8),
				Vector3(3.6, 0.15, -2.4),
				Vector3(4.8, -0.18, -3.2),
			],
		},
		"waterfall": {
			"enabled": true,
			"origin": Vector3(-8.2, 1.35, -6.4),
			"height": 4.8,
			"width": 1.6,
		},
		"bridge": {
			"start": Vector3(-2.6, 0.15, -4.4),
			"end": Vector3(1.4, 0.35, -3.2),
		},
		"zones": [
			_zone(Types.ZoneType.SAFE_SPAWN_ZONE, Vector3(-2.0, 0.0, 4.5), 3.8, Types.BiomeTag.GRASSLAND, 4),
			_zone(Types.ZoneType.CANNON_ZONE, Vector3(1.05, 0.92, -2.05), 2.4, Types.BiomeTag.GRASSLAND, 0),
			_zone(Types.ZoneType.COMBAT_ZONE, Vector3(0.5, 0.0, -0.5), 6.5, Types.BiomeTag.GRASSLAND, 6),
			_zone(Types.ZoneType.COMBAT_ZONE, Vector3(-4.5, 1.45, 2.5), 4.2, Types.BiomeTag.GRASSLAND, 4),
			_zone(Types.ZoneType.LANDMARK_ZONE, Vector3(-6.5, 1.2, -3.5), 3.5, Types.BiomeTag.RUINS, 0),
			_zone(Types.ZoneType.TRAVERSAL_ZONE, Vector3(2.0, 0.0, 1.0), 8.0, Types.BiomeTag.GRASSLAND, 0),
			_zone(Types.ZoneType.OBJECTIVE_ZONE, Vector3(5.5, 0.0, 3.0), 2.5, Types.BiomeTag.CRYSTAL, 2),
			_zone(Types.ZoneType.PORTAL_ZONE, Vector3(-5.0, 1.45, 4.8), 2.0, Types.BiomeTag.CRYSTAL, 0),
		],
	}


static func recipe_basin(seed: int) -> Dictionary:
	return {
		"id": Types.RecipeId.BASIN_B,
		"name": "basin_b",
		"seed": seed,
		"size_class": Types.SizeClass.MEDIUM,
		"plateau_count": 3,
		"elevation_layers": 2,
		"modules": [
			_module(Types.ModuleType.MAIN_PLATEAU, Vector3(0.0, 0.0, 0.0), 8.5, 7.2, 0.0),
			_module(Types.ModuleType.SIDE_PLATEAU, Vector3(-5.5, 0.0, 0.5), 4.0, 3.5, 0.55),
			_module(Types.ModuleType.SIDE_PLATEAU, Vector3(5.2, 0.0, -0.8), 3.8, 3.2, 0.45),
			_module(Types.ModuleType.WATER_BASIN, Vector3(0.0, 0.0, -1.5), 4.5, 3.8, -0.65),
			_module(Types.ModuleType.NARROW_CONNECTOR, Vector3(-2.5, 0.0, 1.2), 2.0, 1.6, 0.2),
		],
		"river": {"enabled": false},
		"waterfall": {"enabled": false},
		"bridge": {"start": Vector3(-1.5, 0.1, 0.8), "end": Vector3(1.5, 0.1, 0.2)},
		"zones": [
			_zone(Types.ZoneType.COMBAT_ZONE, Vector3(0.0, 0.0, 2.0), 5.0, Types.BiomeTag.GRASSLAND, 4),
			_zone(Types.ZoneType.LANDMARK_ZONE, Vector3(0.0, 0.0, -1.5), 3.0, Types.BiomeTag.WATER, 0),
		],
	}


static func recipe_ravine(seed: int) -> Dictionary:
	return {
		"id": Types.RecipeId.RAVINE_C,
		"name": "ravine_c",
		"seed": seed,
		"size_class": Types.SizeClass.MEDIUM,
		"plateau_count": 2,
		"elevation_layers": 2,
		"modules": [
			_module(Types.ModuleType.MAIN_PLATEAU, Vector3(-3.5, 0.0, 0.0), 6.5, 6.0, 0.0),
			_module(Types.ModuleType.SIDE_PLATEAU, Vector3(4.5, 0.0, 0.5), 5.5, 5.0, 0.65),
			_module(Types.ModuleType.RAVINE_SECTION, Vector3(0.0, 0.0, -1.0), 2.8, 4.5, -1.1),
			_module(Types.ModuleType.NARROW_CONNECTOR, Vector3(0.8, 0.0, 0.2), 1.8, 1.4, 0.15),
		],
		"river": {
			"enabled": true,
			"source": Vector3(-2.0, 0.35, 2.5),
			"width": 0.9,
			"depth": 0.15,
			"control_points": [
				Vector3(-2.0, 0.35, 2.5),
				Vector3(-0.5, 0.1, 0.5),
				Vector3(0.5, -0.55, -1.5),
			],
		},
		"waterfall": {"enabled": false},
		"bridge": {"start": Vector3(-0.5, 0.2, -0.2), "end": Vector3(1.8, 0.45, 0.1)},
		"zones": [
			_zone(Types.ZoneType.COMBAT_ZONE, Vector3(-3.5, 0.0, 0.0), 4.5, Types.BiomeTag.GRASSLAND, 4),
			_zone(Types.ZoneType.COMBAT_ZONE, Vector3(4.5, 0.65, 0.5), 4.0, Types.BiomeTag.GRASSLAND, 4),
			_zone(Types.ZoneType.LANDMARK_ZONE, Vector3(4.5, 0.65, -2.5), 2.5, Types.BiomeTag.RUINS, 0),
		],
	}


static func _module(module_type: int, pos: Vector3, rx: float, rz: float, elevation: float) -> Dictionary:
	return {
		"type": module_type,
		"position": pos,
		"radius_x": rx,
		"radius_z": rz,
		"elevation": elevation,
	}


static func _zone(zone_type: int, center: Vector3, radius: float, biome: int, spawn_slots: int) -> Dictionary:
	return {
		"type": zone_type,
		"center": center,
		"radius": radius,
		"biome": biome,
		"spawn_slots": spawn_slots,
		"navigation_hint": "flat_open" if zone_type == Types.ZoneType.COMBAT_ZONE else "walk_path",
	}
