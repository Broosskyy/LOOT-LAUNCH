# Phase 17B — UV-Safe Game-Ready Asset Pipeline

**Status:** Pipeline implemented — visual sign-off in Godot required  
**Date:** 2026-08-21

---

## Summary

Phase 17B converts the three validated Rodin originals into **meshoptimizer-based game-ready LODs** (via `gltf-transform weld + simplify`), wraps them in reusable Godot production scenes with **non-destructive emissive overrides**, and replaces **Wolkengarten island 0 visuals only** behind `USE_PRODUCTION_ISLAND_0`.

Broken external LODs are **isolated** under `_deprecated/` and must not be used.

---

## Asset matrix

| Asset | Role | Original Tris | LOD0 | LOD1 | LOD2 | UV Status | PBR Status | Emission | Collision | Visual Validation | Gameplay |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- | --- | --- |
| **asset_01** (tall form) | Production prop | 120000 | 62400 | 36820 | 32570 | TEXCOORD_0 on all LODs | Embedded normal/base/MR | Override PNG @ 0.42 energy | None (preview) | **Manual Godot preview** | Not integrated |
| **asset_02_floating_island** | Island 0 visual | 120000 | 70658 | 56502 | 50308 | TEXCOORD_0 on all LODs | Embedded normal/base/MR | Override PNG @ 0.42 energy | Walk + rim + skirt cylinders | **Manual Godot preview** | **Island 0 visual swap** |
| **asset_03** (compact form) | Production prop | 120000 | 62400 | 52102 | 48544 | TEXCOORD_0 on all LODs | Embedded normal/base/MR | Override PNG @ 0.42 energy | None (preview) | **Manual Godot preview** | Not integrated |

### Pipeline notes

- **Tool:** `@gltf-transform/cli` weld → cascade simplify (meshoptimizer)
- **Error budget:** conservative on LOD0 (`0.0008`), relaxed on LOD1/LOD2
- **LOD2 counts** intentionally above 18k target where meshoptimizer error limit protected silhouette/UV layout
- **Originals untouched** at `base_basic_pbr.glb`

---

## Directory layout

```
art/models/production/
  asset_01/game_ready/LOD{0,1,2}.glb + pipeline_manifest.json
  asset_02_floating_island/game_ready/LOD{0,1,2}.glb
  asset_03/game_ready/LOD{0,1,2}.glb

art/models/_deprecated/broken_external_lods/floating_island_base01/
  LL_FloatingIsland_Base01_LOD*.glb   ← DO NOT USE

scripts/environment/production_asset.gd
scenes/environment/production_{tall_prop,floating_island,compact_prop}.tscn
scenes/preview/production_assets_preview_v17b.tscn
tests/production_assets_v17b.gd
```

---

## Production wrapper (`production_asset.gd`)

- Loads three game-ready GLB LODs with visibility ranges
- Applies **duplicate** `StandardMaterial3D` surface overrides for emissive (original GLB unchanged)
- `emission_energy` default **0.42** (mobile-safe, glow intensity 0.38 in preview environment)
- Optional gameplay collision separated from render mesh
- Floating island gameplay scale: `radius / 0.96` (island 0 → **13.333×**)

---

## Preview scene

`scenes/preview/production_assets_preview_v17b.tscn`

| Key | View |
| --- | --- |
| **1** | Overview (camera Z=36, outside all meshes) |
| **2** | Asset 1 closeup |
| **3** | Floating island closeup |
| **4** | Asset 3 closeup |
| **C** | Toggle production ↔ original Rodin reference |

---

## Gameplay integration (island 0 only)

In `island_hopping_world.gd`:

```gdscript
const USE_PRODUCTION_ISLAND_0 := true
```

When enabled for Wolkengarten:

- **Replaced:** procedural mesh geometry on island 0
- **Unchanged:** position, radius (12.8), collision cylinder, cannon offset, player spawn, ballistics, contracts, backend

Set to `false` to revert instantly to procedural island 0.

---

## Deprecated assets

Moved to `_deprecated/broken_external_lods/`:

- `LL_FloatingIsland_Base01_LOD0.glb`
- `LL_FloatingIsland_Base01_LOD1.glb`
- `LL_FloatingIsland_Base01_LOD2.glb`

`floating_island_base01.gd` now references deprecated paths only to surface explicit errors.

---

## Preview inspection (free-roam)

Manual visual sign-off uses the production-only preview with mobile/desktop fly camera:

- Scene: `scenes/preview/production_assets_preview_v17b.tscn`
- Docs: `docs/PHASE_17B_PREVIEW_FREE_ROAM.md`

---

## Tests

```bash
godot --headless --path . --script res://tests/production_assets_v17b.gd
godot --headless --path . --script res://tests/island_solidity_v16.gd
godot --headless --path . --script res://tests/all_hops_ballistics_v9.gd
godot --headless --path . --script res://tests/aim_camera_occlusion_v11.gd
godot --headless --path . --script res://tests/multi_expedition_v15.gd
godot --headless --path . --script res://tests/performance_balance_v10.gd
```

**Expected:** `island_solidity_v16.gd` may **fail** with `USE_PRODUCTION_ISLAND_0 = true` because it asserts procedural cliff meshes on `SkyIsland00`. This is intentional — do not weaken the test.

---

## Performance estimate

| Context | Estimate |
| --- | --- |
| Island 0 hero (LOD0 @ gameplay scale) | ~70k tris visible up close — acceptable for one hero island |
| Akku tier | LOD visibility + `quality_level` caps still apply |
| VRAM | Three 2K PBR sets per asset — monitor on device |
| Collision | 3 cylinders — negligible |

---

## Recommendation: **ADJUST → conditional GO**

Proceed to broader migration **after**:

1. Visual sign-off in `production_assets_preview_v17b.tscn` (no stripes/stretch)
2. Gameplay walk on island 0 with `USE_PRODUCTION_ISLAND_0`
3. Optional: refine LOD2 with Blender UV-preserving decimation to hit 8–18k without quality loss

**Stop condition met:** island 0 visual swap implemented; no further islands/assets integrated.
