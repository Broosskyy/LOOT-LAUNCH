# V33 — Stylized Mesh Toolkit 2.0

V33 introduces a Godot-native procedural modeling toolkit under `scripts/environment/stylized/mesh/`. Future stylized world geometry should prefer these builders over raw `BoxMesh` / `CylinderMesh` / `TorusMesh` stacking.

## Architecture

| File | Role |
|------|------|
| `stylized_mesh_common.gd` | Normal modes, validation, vertex helpers, collision hints |
| `stylized_profile_builder.gd` | 2D profiles for extrusion |
| `stylized_curve_builder.gd` | Path sampling + profile extrusion |
| `stylized_stone_builder.gd` | Irregular stone chunks |
| `stylized_mesh_toolkit.gd` | Public builder API |

`StylizedMeshLibrary` (V27) delegates to the toolkit for backward compatibility.

## Builders

1. **beveled_box** — asymmetry, taper, 1–2 bevel segments
2. **irregular_stone** — FLAT_STONE, BLOCK_STONE, TALL_ROCK, RUBBLE, CLIFF_CHUNK
3. **tapered_pillar** — FULL, BROKEN, SHORT_COLUMN
4. **arch** — curved low-poly arch + piers
5. **curved_beam** — profile extrusion along path
6. **segmented_ring** — fantasy ring segments
7. **low_poly_blob** — soft faceted blobs
8. **roof_cap** — pyramidal, hipped, tower cap
9. **wall_segment** — staggered stone rows
10. **terrain_contour_ring** — irregular ledge/pond outline
11. **path_stone** / **octagonal_plinth** — path & platform helpers

## Normal Modes

- `FLAT` — faceted stylized stone (default for ruins/terrain)
- `SMOOTH` — blobs/clouds
- `HYBRID` — reserved for hero props (V35+)

## Irregularity Rules

- Always seed-driven (`RandomNumberGenerator.seed`)
- Safe range: **0.05–0.15** for production
- Same seed → same mesh

## Bevel Rules

- Max 2 bevel segments
- Small readable edge catches, not realistic fillets
- Bevel clamped to ~38% of smallest horizontal half-extent

## Triangle Budgets (guidelines)

| Category | Target |
|----------|--------|
| Small prop | 50–300 |
| Medium prop | 200–1000 |
| Hero prop | 500–2000 |
| Architecture module | 300–1500 |

Use `detail` parameter: `0=DISTANT`, `1=PLAYABLE`, `2=HERO`.

## Collision Philosophy

`Toolkit.collision_hint(mesh)` returns a simple AABB box hint. Gameplay uses separate cheap shapes — never full visual mesh collision.

## V34 Readiness

Terrain Surface 2.0 will use:

- `terrain_contour_ring` — ledges, pond outlines, cliff caps
- `curved_beam` + `STONE_EDGE` profile — riverbanks
- `irregular_stone` — scatter rocks
- `beveled_box` — terrace blocks

## Real-Game Integration (V33)

- **Wall segments** — `StylizedGroundRuinsKit.add_wall_segment()` → `Toolkit.wall_segment()`
- **Plinths** — `add_plinth()` → `octagonal_plinth()` + `roof_cap()`
- **Arch ruins** — `add_arch_fragment()` → `Toolkit.arch()`
- **Path stones** — `MeshLib.path_stone()` → `Toolkit.path_stone()` (irregular flat stones)

## Tests

- `tests/v33_stylized_mesh_toolkit.gd` — builder validation + traversal regression
- `tests/v33_capture_toolkit.gd` — toolkit validation screenshot
- `tests/v33_capture_integration.gd` — real gameplay screenshot

## Rule for Future Cursor Tasks

> Do not use raw BoxMesh/CylinderMesh/TorusMesh as final visible hero geometry when a toolkit builder can produce a better authored form.
