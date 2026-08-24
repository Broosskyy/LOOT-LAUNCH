# V25 Visual Lock — Wolkengarten

This document locks the stylized Wolkengarten reference direction after V19–V25.
Do not casually change these values without an explicit visual pass.

## Reference role

The Wolkengarten gameplay reference defines target framing, hierarchy, and palette.
V25 tuned Godot-native procedural assets toward that reference without external art.

## Camera composition (SSOT: `stylized_world_composition.gd`)

| Parameter | Value |
|---|---|
| FOV | 50.5° |
| Pitch | 19.5° |
| Look height | 0.82 |
| Look ahead | 3.2 |
| Follow distance | 9.05 |
| Follow height | 4.12 |
| Route blend | 0.42 |

Spawn screen targets (1080×1920 portrait):

- Player: lower-center (~50% x, ~80% y)
- Cannon: right-mid (~70% x, ~51% y)
- Chest/pad: left foreground
- Primary destination + portal: upper-mid
- Hero landmark: upper-right third

## Island hierarchy

- **Foreground:** start island (route index 0)
- **Midground:** primary destination at `(5.2, 2.6, -13.5)`
- **Background hero:** vista island 22 (landmark castle silhouette)
- **Accents:** vista islands 20/21/33/34/35 for depth layers

## Start-island props (SSOT: `stylized_start_composition.gd`)

- Cannon offset: composition `CANNON_OFFSET` + scale `1.08`
- Chest: `(-2.9, 0, 0.55)`
- Pad: `(-2.2, 0, 0.35)`
- Path stones curve player → cannon → launch direction

## Material palette (SSOT: `stylized_material_library.gd`)

Muted fresh grass, warm grey rock, warm path stone, controlled purple magic,
warm brass accents, cool blue sky/atmosphere. Do not neon-push grass or cliffs.

## Lighting / atmosphere (SSOT: `stylized_lighting.gd`)

Bright stylized daylight, soft shadows, tiered fog by quality, restrained glow.
GL Compatibility only — no Forward+ assumptions.

## Clouds (SSOT: `stylized_cloud_generator.gd`)

Low-poly puff clusters + lower cloud bank. Atmosphere support only — must not hide
destination islands or gameplay props.

## Vegetation intent

Foreground moderately lush; midground controlled; background minimal.
Tune density via start composition arrays, not new systems.

## Future asset hooks (visual-only swap targets)

Gameplay nodes remain authoritative. These visuals may later be replaced by higher-detail assets:

| Visual root | Gameplay anchor |
|---|---|
| `StylizedHeroModels.build_cannon_visual` | `RouteCannon*/AimPivot` |
| `StylizedHeroModels.build_gameplay_chest` | `route_chests` / `Lid` |
| `StylizedPortalGenerator.build_monument` | portal pair nodes |
| `StylizedHeroModels.build_pad` | decor pad on start island |
| `StylizedVegetationGenerator` trees/shrubs | decoration only |
| Vista landmark decor | `SkyIsland22` decor root |

## Do not change without review

- Camera SSOT constants
- Route/vista island positions for island 0–1 and landmark 22
- Material emission strengths (portal/crystal/pad)
- Ring arc hop-0 trajectory
- Player spawn offset band
