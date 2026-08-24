# V34 — Terrain Surface 2.0 Standard

V34 makes terrain itself part of the art direction using the V33 mesh toolkit.

## Terrain Layer Language

```
GRASS TOP
  ↓ soft contour breakup / shelves
EARTH / STONE LIP
  ↓ irregular edge ring
UPPER CLIFF SHELF
  ↓ faceted skirt
MAIN CLIFF BODY
  ↓ unified shell (mega islands)
LOWER ROCK MASS
```

## Core System

`StylizedTerrainSurface` (`scripts/environment/stylized/stylized_terrain_surface.gd`)

| Function | Purpose |
|----------|---------|
| `dress_hero_island()` | Start island edge lip, breakup, outcrops |
| `dress_mega_island()` | Module lips, seams, river channel, pond shore, ravine, waterfall notch |
| `dress_path_embedded()` | Path trench + embedded stones |

## Surface Tags (biome hooks)

`GRASS`, `FOREST_FLOOR`, `RUINS_GROUND`, `CRYSTAL_GROUND`, `WET_BANK`, `FLOWER_MEADOW`

Stored via `terrain_surface_tag` metadata on dressed meshes.

## Rules

### Grass / Cliff Edge
- No uniform ring; use controlled wobble (0.05–0.12)
- Earth lip before cliff skirt
- HERO islands get full dressing; distant islands stay simplified

### Shelves
- Low beveled grass shelves away from combat zones
- Max height ~0.14 m — traversal safe

### Path Integration
- Trench channel (`dress_path_embedded`) before stones
- Stones sit 0.025 m lower than before

### River Banks
- Channel depression mesh under water strip
- Flat stones + dirt bank using V33 stone builder
- Waterfall notch connects river approach to cliff edge

### Seam Hiding (Mega Island)
- Blend shelves at module midpoints when radii overlap
- Per-module edge lips
- Combat zones excluded from shelf/breakup clutter

### Collision
- Visual terrain richer than collision
- Gameplay collision unchanged (cylinders / island generator collision)

## Performance

- Static deterministic generation at island load
- Reuses shared V33 meshes/materials
- Detail tier follows `quality_level` (segments 10–18)

## V35 Boundary (not implemented)

- Tower / gate / bridge hero architecture
- Castle silhouettes
- Full ruin complexes
- Portal monument redesign

## Future Cursor Rule

Prefer `StylizedTerrainSurface` for terrain edge, path, river bank, and seam work. Do not add flat grass caps without edge dressing on playable islands.
