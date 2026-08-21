# Phase 17B — Wolkengarten Material Visual QA

**Date:** 2026-08-21  
**Base commit:** `2908e3ab2e1c605541046adcc2e583376719f25e`  
**Preview scene:** `scenes/preview/production_assets_preview_v17b.tscn`

---

## Purpose

Prepare the existing production preview for **smartphone material evaluation** without adding environment content or changing Phase 17B lighting values.

---

## Preview controls (mobile)

| Control | Action |
|---|---|
| **OVERVIEW** | Full island framing (existing) |
| **UI** | Toggle QA preset row |
| **SURFACE** | Close top-down view for grass / stone path detail |
| **CRYSTAL** | Close view on upper crystal cluster |
| **CLIFF** | Side view on rock underside / moss |
| **RESET** | Return to last overview framing |
| **+ / −** | FOV zoom |
| **Left joystick** | Fly move |
| **Right drag** | Look |
| **Pinch** | FOV zoom (mobile) |

Free-roam remains available after any preset for fine adjustment.

---

## Material verification (runtime)

On load, `island_material_recovery.gd` verifies active runtime materials:

| Check | Expected |
|---|---|
| Albedo | 2048×2048, `albedo_color = WHITE` |
| Normal | 2048×2048, `normal_enabled = true` |
| MR map | metallic + roughness textures bound |
| MR channels | Blue = metallic, Green = roughness (glTF 2.0) |
| Filtering | `LINEAR_WITH_MIPMAPS_ANISOTROPIC` |
| Emission | enabled, energy `0.16`, tint `(0.58, 0.46, 0.92)` |
| External emissive | `texture_emissive.png` mask |

Results print to Godot console as `[OK]` / `[FAIL]`.

---

## Technical fix applied in QA pass

**Removed scalar roughness/metallic clamp** in `production_asset.gd` `_enhance_imported_materials()`.

Previous `roughness = clampf(..., 0.22, 1.0)` multiplied against the MR texture and could flatten per-region variation from the atlas. Scalar factors now remain as imported from glTF.

---

## Atlas material analysis

| Topic | Finding |
|---|---|
| Material count | 1 shared `"model"` material |
| Per-region roughness | Possible via MR green channel in atlas |
| Per-region metallic | Possible via MR blue channel in atlas |
| Normal mapping | Single 2048 normal atlas — active |
| Crystal emission | Masked via external `texture_emissive.png`; non-mask pixels should stay dark |
| Emission bleed risk | If mask has gray on grass/stone, those areas will glow slightly — verify in SURFACE preset |
| AO | Not present in asset |
| UV seams / mip bleed | Possible at atlas color boundaries — inspect SURFACE + CLIFF presets |

No material split performed in this pass.

---

## Lighting

Phase 17B values unchanged:

- Exposure `0.88`
- Ambient energy `0.36`
- Sun energy `0.62`
- Glow intensity `0.08`
- Emission energy `0.16`

---

## QA checklist

| Item | Status |
|---|---|
| Original island only | ✓ |
| No placeholder deco | ✓ |
| No background plane | ✓ |
| Albedo / Normal / MR active | ✓ (runtime verify) |
| Anisotropic + mipmaps | ✓ |
| Crystal emission active | ✓ |
| OVERVIEW works | ✓ |
| SURFACE / CRYSTAL / CLIFF presets | ✓ (via UI toggle) |
| Touch / zoom / free-roam | ✓ (unchanged) |
| Lighting unchanged | ✓ |

---

## Smartphone test steps

1. Open `production_assets_preview_v17b.tscn` on device (portrait).
2. Tap **OVERVIEW** — judge whole island color, silhouette, crystal placement.
3. Tap **UI** → **SURFACE** — grass detail, stone path, transitions.
4. Tap **CRYSTAL** — color, emission, overexposure.
5. Tap **CLIFF** — rock normals, moss, depth.
6. Use joystick + drag to fine-tune; **RESET** returns to overview framing.

**Stop here** — no further island changes until visual review decision (PBR upgrade vs gameplay integration).
