# V41 — Procedural Low-Poly Visual Benchmark

## Purpose

V41 answers one question: **how close can LOOT LAUNCH get to the established visual reference using Godot-native procedural geometry**, without new external environment models?

## Access

Launch with expedition key:

```gdscript
world.begin({"seed": 4100, "world_key": "v41_benchmark"}, "bouncer", "standard", false, 0)
```

Optional debug cliff markers:

```gdscript
{"seed": 4100, "world_key": "v41_benchmark", "v41_debug_visuals": true}
```

## Composition

Single benchmark island (`SkyIsland00`) with:

- Player start plateau + chest
- Irregular stepping-stone path (5 variants)
- Small ruin section (pillar, arch, rubble)
- Chunky stone stairs + retaining walls
- Cannon landmark (existing gameplay cannon, stylized mesh)
- Upper plateau with crystal altar
- Portal endpoint on second island (`SkyIsland01`)
- Five background vista islands with atmospheric materials

## Module Kits

| Kit | Location | Variants |
|-----|----------|----------|
| Cliff | `v41_cliff_builder.gd` | 10 module kinds |
| Path | `v41_path_kit.gd` | PathStone A–E |
| Ruins | `v41_ruin_kit.gd` | 9 ruin kinds |
| Rocks | `v41_rock_kit.gd` | Small / medium / large / rubble / landmark |
| Vegetation | `v41_vegetation_kit.gd` | Grass, flower, bush, trees, hero tree |
| Props | `v41_prop_kit.gd` | Chest, crystal altar, portal |

Composer: `v41_visual_benchmark.gd`

## Tests

```bash
godot --headless --path . -s tests/v41_procedural_benchmark.gd
godot --headless --path . -s tests/v41_capture_render.gd
```

## Visual Master

V41 reuses V40 camera, lighting, and material palette via `StylizedWorldComposition.apply_wolkengarten`. Camera values are **not** overridden for screenshot hacks.

## V42 Recommendation Criteria

- **Option A (Procedural expansion)** if cliff/path/vegetation kits read as intentionally designed low-poly in capture.
- **Option B (External assets)** if hero props (cannon, chest, complex ruins) still dominate as procedural limits.
