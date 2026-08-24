# V30 — Godot-Native Visual Lock (Wolkengarten)

Canonical visual baseline after V25–V30. This document supersedes the V25 camera table for tuning values while preserving the same reference intent.

## Reference role

The supplied Wolkengarten gameplay reference remains the primary target. V30 converges V26–V29 systems through micro-tuning only — no new art architecture.

## Camera (SSOT: `stylized_world_composition.gd`)

| Parameter | V30 value |
|---|---|
| FOV | 52.0° |
| Pitch | 18.0° |
| Look height | 0.68 |
| Look ahead | 4.85 |
| Follow distance | 10.15 |
| Follow height | 3.48 |
| Route blend | 0.46 |

Spawn screen targets (1080×1920 portrait):

- Player: lower-center (~48–52% x, ~72–82% y)
- Cannon: right-mid (~66–74% x, ~46–54% y)
- Chest/pad: left foreground (~12–32% x)
- Primary destination + portal: upper-mid (~35–55% x, ~8–18% y)
- Hero landmark: upper-right third

V30 lowers the top-down feel by pulling the camera back, lowering height, and looking farther ahead into the route.

## Composition hierarchy

1. **Foreground:** Lootling, start island edge, cannon, chest, pad, path
2. **Midground:** gold ring arc, first destination island, gameplay portal
3. **Far midground:** vista islands 20/21/33/34
4. **Background:** hero landmark island 22 + sky/cloud depth

## Start-island props (SSOT: `stylized_start_composition.gd`)

- Cannon: `CANNON_OFFSET` + scale `1.0`
- Chest: `(-2.65, 0, 0.72)`
- Pad: `(-2.05, 0, 0.42)`
- Path stones unchanged — leading line player → cannon → route

## Vegetation philosophy

V28 density architecture retained. V30 reduces center clutter:

- Wider spawn/path/cannon exclusion zones
- No spawn-zone center grass clumps
- Edge ring coverage 34% (was 42%)
- Trees frame edges; path corridor stays readable

## Materials (V26 foundation, V30 micro-tune)

- Grass: slightly muted (`#468f54` family) — avoids neon flat fill
- Rock/path/wood/brass unchanged in architecture
- Magic violet accents restrained

## Lighting / atmosphere (V26 + V30)

- Richer cyan sky gradient
- Exposure 0.77 (Q2) — preserves form without grass wash
- Fog density 0.00118, aerial perspective 0.34 — depth without hiding islands
- Sun energy 0.82 — readable facets on props and cliffs

## VFX / animation (V29 + V30 restraint)

- Wind Q2: 0.048 strength
- Ring bob reduced for route readability
- Portal/pad emission pulses softened
- Cannon recoil remains visual-only on `AimPivot`

## Performance philosophy

Mobile-first GL Compatibility. Quality tiers unchanged. Particle caps from `StylizedVFXController`.

## Future asset hooks (unchanged)

| Visual | Gameplay anchor |
|---|---|
| `StylizedHeroModels.build_cannon_visual` | `RouteCannon*/AimPivot` |
| `StylizedHeroModels.build_gameplay_chest` | `route_chests` / `Lid` |
| `StylizedPortalGenerator.build_monument` | portal pair |
| `StylizedHeroModels.build_pad` | start decor pad |
| `StylizedVegetationGenerator` | decoration only |
| Vista landmark decor | `SkyIsland22` |

## Reference-match conclusion

V30 achieves a clearer third-person “into the world” read with improved depth layers, prop hierarchy, and restrained motion/VFX. Remaining gaps vs a fully authored reference are documented in the V30 abschlussbericht procedural-limit section.

## Deferred

No V31 work. External asset integration is out of scope.
