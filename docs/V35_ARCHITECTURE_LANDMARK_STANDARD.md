# V35 — Architecture & Landmark Standard

V35 introduces authored stylized fantasy architecture using the V33 mesh toolkit on V34 terrain.

## Systems

| File | Role |
|------|------|
| `StylizedArchitectureGenerator` | Walls, arches, gates, pillars, stairs, bridges |
| `StylizedLandmarkGenerator` | Towers, portal monuments, hero landmark, ruin courtyards |

## Module Types

`WALL_SECTION`, `BROKEN_WALL_SECTION`, `ARCHWAY`, `GATE`, `PILLAR_CLUSTER`, `STAIR_TOWER`, `BRIDGE`, `LOOKOUT_RUIN`, `PORTAL_MONUMENT`, `WATCHTOWER`, `HERO_TOWER`, `RUIN_COURTYARD`

## Damage Presets

`INTACT`, `LIGHT_RUIN`, `BROKEN`, `HEAVY_RUIN` — deterministic via seed.

## Rules

### Walls
- Staggered toolkit `wall_segment` blocks
- Broken tops via damage flag + rubble clusters
- No flat slab walls

### Arches / Gates
- Toolkit `arch()` with curved geometry
- Gates = twin towers + central arch + broken upper band

### Towers
- Base plinth → tapered shaft → mid band → cap
- `HERO_TOWER` adds buttress + banner mast hook
- `BROKEN_TOWER` uses broken pillar kind

### Bridges
- Curved beam deck + stone rails + support piers
- Connects V32 bridge anchor points
- Simplified box collision on deck

### Portal Monument
- Raised stepped platform + stair approach
- Segmented stone frame (toolkit `segmented_ring`)
- Portal energy rings remain gameplay hooks (V29)

### Production Integration
- Start island: broken wall + arch fragment
- Destination island 1: portal monument + lookout ruin + stone bridge
- Mega island: gate, ruin courtyard, watchtower, portal zone monument
- Hero vista: `build_hero_landmark` composite

## Materials

Reuse V26: `ruin_stone`, `stone_main`, `portal_stone`, `wood_dark`, `brass_gold`. No new global palette.

## Vegetation Hooks

Nodes named `VegHook` with `architecture_veg_hook` metadata for V28 framing.

## Collision

Simplified `BoxShape3D` on gates, stairs, bridges. Visual mesh may be richer.

## Triangle Budgets (guidelines)

| Structure | Tris |
|-----------|------|
| Wall | 300–800 |
| Arch | 300–700 |
| Gate | 600–1500 |
| Tower | 500–2000 |
| Bridge | 500–1500 |
| Hero landmark | <5000 |

## V36 Boundary (not implemented)

- Atmospheric depth / fog volume
- Cloud volume rendering
- Shadow softness / ambient contrast
- Color grading / sky richness

## Future Cursor Rule

Use `StylizedArchitectureGenerator` / `StylizedLandmarkGenerator` for new structures. Do not add raw `BoxMesh` hero architecture when toolkit builders apply.
