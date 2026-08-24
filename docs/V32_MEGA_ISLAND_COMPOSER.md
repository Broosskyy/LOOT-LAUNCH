# V32 — Modular Mega-Island Terrain Composer

V32 introduces a Godot-native modular composition pipeline for building larger floating islands that read as **one cohesive landmass** while preserving V26–V30 stylized art direction.

## Architecture

```
StylizedMegaIslandComposer (orchestrator)
├── MegaIslandTypes      — enums + metadata keys
├── MegaIslandRecipes    — deterministic recipe dictionaries
├── MegaIslandWater      — river, pond, waterfall meshes
├── MegaIslandCollision  — multi-cylinder walkable collision
└── StylizedWorldDecorator.decorate_mega_playable_island()
```

The composer is invoked from `island_hopping_world.gd` for route island index **5** (`SkyIsland05`). Gameplay anchors (center, radius, cannon, portal) are unchanged from `StylizedWorldComposition.ROUTE_ISLANDS`.

## Module Types

| Module | Purpose |
|--------|---------|
| `MAIN_PLATEAU` | Large central walkable mass |
| `SIDE_PLATEAU` | Connected secondary area |
| `HIGH_TERRACE` | Raised terrace (+1.45 m showcase) |
| `LOW_BASIN` | Depressed valley floor |
| `NARROW_CONNECTOR` | Natural neck / land bridge overlap |
| `CLIFF_LEDGE` | Shelf / edge accent |
| `RAVINE_SECTION` | Cut gully with rock fill |
| `WATER_BASIN` | Pond depression |

Modules are placed with overlapping ellipse grass caps, per-module rock skirts, and a unified outer cliff shell to hide seams.

## Recipe Structure

Recipes are plain dictionaries:

```gdscript
{
  "id": Types.RecipeId.RIVER_TERRACE_A,
  "seed": 9001,
  "size_class": Types.SizeClass.LARGE,
  "modules": [...],
  "river": { "enabled": true, "control_points": [...], "width": 1.35, "depth": 0.22 },
  "waterfall": { "enabled": true, "origin": Vector3(...), "height": 4.8, "width": 1.6 },
  "bridge": { "start": Vector3(...), "end": Vector3(...) },
  "zones": [...]
}
```

### Shipped Recipes

- **RECIPE_A — `river_terrace_a`** — fully integrated playable showcase (route island 5)
- **RECIPE_B — `basin_b`** — central pond + perimeter connectors (validation)
- **RECIPE_C — `ravine_c`** — split terrain + narrow crossing (validation)

`StylizedMegaIslandComposer.compose_playable_showcase()` selects RECIPE_A with seed `32007 + world_seed * 131 + route_variant * 17`.

## Elevation Rules

- Showcase uses **LOW / MID / HIGH** layers (~−0.85 m to +1.45 m relative to island root).
- Slopes are implied by overlapping caps and connector geometry; no vertical walls block required traversal paths.
- Combat zones are tagged flat and excluded from dense tree placement.

## Water Features

### River

- Quadratic Bézier segments sampled from `control_points`
- Strip mesh slightly below grass (`depth` offset) with stylized cyan water color
- Bank dressing uses existing `path_stone` meshes from `StylizedMeshLibrary`

### Pond

- Irregular ellipse basin mesh in `WATER_BASIN` modules

### Waterfall

- Vertical strip mesh at cliff edge
- **Q0**: strip only
- **Q1+**: minimal splash particles (mobile-safe cap)

## Gameplay Zones

Each recipe defines metadata zones (no AI yet):

| Zone | Metadata |
|------|----------|
| `SAFE_SPAWN_ZONE` | center, radius, biome, spawn_slots |
| `TRAVERSAL_ZONE` | walk corridors |
| `COMBAT_ZONE` | flat_open nav hint, spawn_slots for future enemies |
| `LANDMARK_ZONE` | ruin cluster anchor |
| `OBJECTIVE_ZONE` | crystal / chest hooks |
| `CANNON_ZONE` | existing cannon placement reference |
| `PORTAL_ZONE` | portal pad reference |

Biome tags: `GRASSLAND`, `FOREST`, `RUINS`, `CRYSTAL`, `WATER`, `FLOWER`.

Access via `world.mega_island_metadata` after island build.

## Collision Strategy

`MegaIslandCollision.build_collision()` creates **per-plateau vertical cylinders** aligned to module ellipses. Rivers and ponds are non-blocking. Ravine boundaries use simplified shapes only where needed.

## Performance

- Static generated meshes, shared materials from `StylizedMaterialLibrary`
- Quality tier reduces river bank density and vegetation counts
- Deterministic single build per island load (no per-frame composer logic)
- Hero island: full detail; distant vista islands unchanged

Typical showcase build: ~8 modules, ~31 river samples, vertex budget validated in `tests/v32_mega_island_composer.gd`.

## Debug Visualization

Pass `debug_view=true` to `compose()` to draw zone cylinders and river point markers. **Off by default** in production.

## Future Hooks (not implemented)

- `NavigationRegion3D` bake from combat/traversal zones
- Enemy spawn from `spawn_slots` + `navigation_hint`
- Encounter / loot / quest triggers bound to zone metadata

## Creating Another Mega Island

1. Add or duplicate a recipe in `mega_island_recipes.gd`
2. Validate with `Composer.compose()` + `Composer.validate_recipe_build()`
3. Wire route index in `island_hopping_world.gd` (or swap `MEGA_ISLAND_INDEX`)
4. Run `tests/v32_mega_island_composer.gd` and cannon reachability checks
5. Capture gameplay screenshots via `tests/v32_capture_render.gd`

## Tests

- `tests/v32_mega_island_composer.gd` — recipe build, determinism, water, zones, walk proxy, V31 reachability
- `tests/v32_capture_render.gd` — 1080×1920 OpenGL3 gameplay screenshots
