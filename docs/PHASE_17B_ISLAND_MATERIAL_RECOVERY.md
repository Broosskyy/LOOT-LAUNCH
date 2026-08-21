# Phase 17B — Island Material & Texture Recovery Pass

**Date:** 2026-08-21  
**Scope:** Visual material/texture quality of the existing Wolkengarten floating island only.  
**No new environment geometry. No gameplay changes.**

---

## 1. Placeholder cleanup

Removed the previous preview polish pass that added primitive environment dressing:

| Removed element | Source |
|---|---|
| Green wire/triangle grass tufts | `wolkengarten_preview_environment.gd` |
| Black platforms / integration markers | same |
| Cyan crystal wedges / shards | same |
| Large white sky backdrop quad | same |
| Cyan debug lines / walk rings | same |
| Semi-transparent reference floor plane | `production_assets_preview_v17b.gd` |
| Distant island silhouettes / cloud billboards | same |

**Deleted:** `scripts/preview/wolkengarten_preview_environment.gd`  
**Kept:** Original GLB meshes, embedded PBR textures, external emissive companion.

Preview background is now procedural sky only (no rectangular image plane).

---

## 2. Asset inventory (LOD0.glb — authoritative)

Inspected with `@gltf-transform/cli inspect`.

### Mesh

| Property | Value |
|---|---|
| Vertices | 118,476 |
| Primitives | 1 |
| Attributes | POSITION, NORMAL, TANGENT, TEXCOORD_0 |
| Double-sided | yes |

### Embedded textures (inside GLB)

| Map | Name | Resolution | Notes |
|---|---|---|---|
| Base Color / Albedo | `texture_diffuse` | **2048×2048** | PNG, sRGB |
| Normal | `texture_normal` | **2048×2048** | PNG, linear |
| Metallic + Roughness | `texture_metallic-texture_roughness` | **2048×2048** | Combined ORM-style MR |

### Not present in GLB

| Map | Status |
|---|---|
| Ambient Occlusion | **missing** |
| Separate Roughness | bundled in MR texture |
| Separate Metallic | bundled in MR texture |
| Height / Displacement | **missing** |
| Emission (embedded) | **missing** |
| Detail maps / masks | **missing** |

### External companion (not in glTF material binding)

| File | Resolution | Role |
|---|---|---|
| `texture_emissive.png` | ~240 KB PNG | Crystal glow mask — applied at runtime by `production_asset.gd` |

**Conclusion:** The island is a **single PBR material** (albedo + normal + MR). Additional AO/height maps would need to be authored separately if desired.

---

## 3. Godot import — issues found & fixes

| Issue | Before | After | Effect |
|---|---|---|---|
| Emission energy too high | `0.42` (preview `0.26`) | `0.16` + purple tint | Crystals glow without white blowout on bloom |
| Emission tint default white | `Color(1,1,1)` implicit | `Color(0.58, 0.46, 0.92)` | Preserves lila/rosa/blau crystal hue |
| Albedo multiplier drift | possible non-white tint | forced `Color.WHITE` on tuned duplicate | Grass no longer yellow/burnt from tint stack |
| Texture filtering default | linear+mipmap | **anisotropic** filtering | Sharper stone paths & grass detail on mobile |
| Roughness floor missing | could read flat/shiny | clamp min `0.22` | Grass reads matte; stone keeps MR variation |
| Preview exposure stack | exposure `0.92`, glow `0.16` | exposure `0.88`, glow `0.08` | Materials read closer to authored albedo |
| Placeholder rim omni | purple omni `0.55` | removed; soft fill dir `0.18` | Less artificial highlight on crystals |
| Rectangular backdrop plane | visible white/texture quad | removed | Clean neutral preview framing |

GLB scene import params unchanged (`embedded_image_handling=1`, tangents ensured).

---

## 4. Per-surface material report

All LODs share one material instance `"model"` per mesh.

### Grass / topsoil (albedo regions)

| | |
|---|---|
| **Resolution** | 2048×2048 diffuse + normal + MR |
| **Maps present** | albedo, normal, metallicRoughness |
| **Maps missing** | AO, emission (embedded), height |
| **Before** | High ambient + exposure + roughness floor → yellow/burnt; flat specular |
| **After** | `albedo_color = WHITE`, roughness ≥ 0.22, anisotropic filter, lower exposure |
| **Expected effect** | Natural fantasy green from original diffuse; visible micro-detail |

### Stone paths (albedo regions)

| | |
|---|---|
| **Resolution** | same atlas |
| **Before** | Normal/MR present but washed by lighting + low filtering |
| **After** | Anisotropic filtering + conservative lighting |
| **Expected effect** | Path stones readable; normal detail separates from grass |

### Cliff / rock sides

| | |
|---|---|
| **Resolution** | same atlas |
| **Before** | Already acceptable |
| **After** | Conservative — only filtering + roughness floor; no color reinterpretation |
| **Expected effect** | Moss/rock variation preserved |

### Crystals (emissive mask regions)

| | |
|---|---|
| **Resolution** | external emissive PNG + diffuse normal detail |
| **Before** | `emission_energy 0.42`, white emission, glow `0.16` → clipped white faces |
| **After** | `emission_energy 0.16`, tint `(0.58, 0.46, 0.92)`, glow `0.08`, threshold `1.25` |
| **Expected effect** | Visible purple/blue crystal color, edges readable, controlled glow |

---

## 5. Mobile considerations

| Setting | Choice |
|---|---|
| Texture resolution | Keep 2048² (authored size; no downscale) |
| Filtering | `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC` |
| Material complexity | Single StandardMaterial3D — mobile friendly |
| Compression | GLB embedded PNGs; no extra uncompressed duplicates added |

---

## 6. Files changed

| File | Change |
|---|---|
| `scripts/environment/production_asset.gd` | Emission tint/energy, PBR presentation pass |
| `scripts/preview/production_assets_preview_v17b.gd` | Remove placeholder env + floor; conservative lighting |
| `scripts/preview/island_material_recovery.gd` | **new** — runtime material audit helper |
| `scripts/preview/wolkengarten_preview_environment.gd` | **deleted** |

---

## 7. QA checklist

| Check | Status |
|---|---|
| Island loads without errors | expected ✓ |
| No placeholder deco visible | ✓ removed |
| No background plane | ✓ removed |
| Grass not blown out | ✓ tint/exposure/roughness fix |
| Stone paths more readable | ✓ filtering + lighting |
| Cliff quality preserved | ✓ conservative |
| Crystal color visible | ✓ tint + lower emission |
| Preview controls work | ✓ unchanged |
| No new improvised assets | ✓ |
| Godot CLI parse test | not available in CI shell |

---

## 8. Next step recommendation

The asset ships **albedo + normal + MR only**. If grass/path AO micro-contrast or crystal depth still feels insufficient after this pass, the next investment should be **authored AO and/or roughness refinement maps** — not more preview primitives.
