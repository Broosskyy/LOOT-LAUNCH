# Phase 17A Hotfix — Original Rodin 3-Asset Validation

**Status:** Validation pipeline ready — visual sign-off in Godot required  
**Date:** 2026-08-21  
**Scope:** Original ~120k Rodin GLBs only. No decimation, no gameplay integration.

---

## Problem statement

The externally decimated floating island (`LL_FloatingIsland_Base01_LOD0.glb`) showed in Godot:

- stretched / smeared textures
- vertical texture stripes
- camera clipping inside mesh at gameplay scale

This hotfix imports **three untouched Rodin exports** for side-by-side validation.

---

## Imported originals

| Folder | Rodin UUID | Primary GLB | Tris | Notes |
| --- | --- | --- | ---: | --- |
| `art/models/production/asset_01/` | `b34fdb36-0c60-404c-880b-96ece5489eaf` | `base_basic_pbr.glb` | 120000 | Tall form (~1.62 m height) |
| `art/models/production/asset_02_floating_island/` | `9257e8e6-b152-4209-8ea3-050df63f1c99` | `base_basic_pbr.glb` | 120000 | Floating island (source of broken LOD pipeline) |
| `art/models/production/asset_03/` | `9bdd279c-f1d8-4c8a-9b3a-2e49729ac6d1` | `base_basic_pbr.glb` | 120000 | Compact form (~1.56 m height) |

Each folder also contains:

- `texture_emissive.png` (Rodin companion file — **not wired inside GLB**)
- `base_basic_shaded.glb` (comparison only, not loaded by default)
- `rodin_metadata.json`

---

## Scenes

| Scene | Purpose |
| --- | --- |
| `scenes/environment/production_asset_01.tscn` | Wrapper for asset 1 |
| `scenes/environment/production_asset_02.tscn` | Wrapper for floating island |
| `scenes/environment/production_asset_03.tscn` | Wrapper for asset 3 |
| `scenes/preview/rodin_original_assets_preview_v17a.tscn` | Combined validation layout |

### Preview layout

```
Asset 1 (-16, 0, 0)     Asset 2 Original (0, 0, 0)     Asset 3 (16, 0, 0)
                              |
                    Broken Optimized LOD0 (0, 0, -10)
```

- Wolkengarten sky + directional/rim lighting (matches existing preview)
- Neutral reference floor (visual only)
- **Scale:** all originals at **1:1** — no gameplay scaling
- **Geometry / materials:** unchanged

### Camera presets

| Key | View |
| --- | --- |
| **1** | Overview (guaranteed outside all meshes, Z=34) |
| **2** | Asset 1 closeup |
| **3** | Asset 2 closeup (floating island original) |
| **4** | Asset 3 closeup |

Closeups use bounds-based safe distance (`radius × 2.8`, minimum 4.5 m).

---

## Technical inspection results

### glTF structure (parsed from `base_basic_pbr.glb`)

| Check | Asset 1 | Asset 2 | Asset 3 |
| --- | --- | --- | --- |
| Triangles | 120000 | 120000 | 120000 |
| Vertices | 117805 | 149951 | 144119 |
| UV count = vertex count | YES | YES | YES |
| Embedded images | 3 | 3 | 3 |
| Normal map slot | YES | YES | YES |
| Base color slot | YES | YES | YES |
| Metallic-roughness slot | YES | YES | YES |
| Floor Y min | 0.000 | 0.000 | 0.000 |
| Wrapper scale | 1:1 | 1:1 | 1:1 |
| Geometry modified | NO | NO | NO |

### Emissive note

Rodin `base_basic_pbr.glb` exports do **not** bind `texture_emissive.png` in the glTF material. Emissive is a **separate companion file** for all three assets. Missing glow in-engine is expected until manually authored — not evidence of broken UV/PBR.

### Comparison: original vs broken optimized island (asset 2)

| Metric | Original Rodin | External LOD0 |
| --- | ---: | ---: |
| Triangles | 120000 | 25156 |
| Vertices | 149951 | 12633 |
| UV entries | 149951 | 12633 |
| Vertex reduction | — | **~91.6%** |

The optimized mesh collapsed vertex/UV data aggressively. Even when UV **counts** match vertices, automated decimation commonly destroys UV island layout — matching reported stretch/stripe artifacts.

---

## Validation table

| Asset | UV korrekt | PBR korrekt | Emissive | Scale | Kamera | Ergebnis |
| --- | --- | --- | --- | --- | --- | --- |
| **Asset 1** (tall form) | **JA** — 1:1 UV/vert in glTF | **JA** — normal + base + MR embedded | **Extern** — PNG only, not in GLB | **JA** — 1:1, floor Y=0 | **JA** — safe overview/closeup | **PASS (technical)** |
| **Asset 2** (floating island) | **JA** | **JA** | **Extern** | **JA** | **JA** | **PASS (technical)** |
| **Asset 3** (compact form) | **JA** | **JA** | **Extern** | **JA** | **JA** | **PASS (technical)** |
| **Broken optimized LOD0** | **NEIN** — decimated UV layout | **NEIN** — smeared in Godot | embedded attempt | 1:1 still broken | too close at old preview scale | **FAIL — do not ship** |

> **Visual sign-off:** Open `scenes/preview/rodin_original_assets_preview_v17a.tscn` in Godot 4.7 and confirm textures look clean on keys **2–4**. Technical glTF inspection strongly indicates originals are sound; the broken LOD confirms decimation as the regression source.

---

## What was NOT changed

- `island_hopping_world.gd`
- Ballistics, economy, Supabase, expeditions
- No decimation / retopology / LOD generation
- No material rebuild on originals

---

## Test

```bash
godot --headless --path . --script res://tests/rodin_original_assets_v17a.gd
```

Requires Godot import of the three `base_basic_pbr.glb` files first.

---

## Conclusion

| Question | Answer |
| --- | --- |
| Asset 1 korrekt | **JA** (glTF UV/PBR intact; confirm visually in preview) |
| Asset 2 korrekt | **JA** |
| Asset 3 korrekt | **JA** |
| Original Rodin UV/PBR grundsätzlich korrekt | **JA** |
| Bisherige Optimierung als Fehlerursache bestätigt | **JA** |

### Root cause

The external automated decimation/LOD pass (120k → ~25k tris, ~150k → ~12k verts on the floating island) destroyed usable UV layout. This is **not** a Godot glTF importer failure for the original Rodin files.

### Next recommendation

1. **Stop** using the externally decimated `LL_FloatingIsland_Base01_LOD*.glb` set for production.
2. Open `rodin_original_assets_preview_v17a.tscn` and visually sign off all three originals.
3. If mobile LOD is required, reduce in **Blender** with:
   - UV-preserving decimation
   - per-LOD bake from the original 120k mesh
   - re-validation in this preview scene after each reduction step
4. Wire emissive deliberately in Blender or Godot **after** UV/PBR sign-off — not before.
5. Only after asset-2 visual PASS → consider gameplay-scale wrapper (Phase 17B), still without touching ballistics.

**Do not integrate into `island_hopping_world.gd` yet.**
