# Phase 17C — Rodin → Godot Visual Parity Recovery

**Date:** 2026-08-21  
**Scope:** Preview render/material parity only. No geometry, no gameplay, no new assets.

---

## Root-cause audit

| Source | Before | Problem |
|---|---|---|
| Ambient light | energy `0.36`, bright `#c5eaff` | Flat fill; lifted shadows; reduced contrast |
| Directional sun | energy `0.62`, warm `#fff0d0` | Yellow cast on grass; highlight clip |
| Fill directional | energy `0.18` | Second key light washed normals |
| ACES exposure | `0.88` | Combined stack pushed albedo toward white |
| Glow / bloom | intensity `0.08`, threshold `1.25` | Crystal HDR clipped to white |
| Fog | enabled, energy `0.28` | Atmospheric haze on all surfaces |
| Sky ground hemisphere | bright `#b9d9e8` / `#6d9ac1` | Visible gray/blue disk below island |
| Emission tint | `(0.58, 0.46, 0.92)` × energy `0.16` | Overrode texture violet → near-white with glow |
| AO proxy (albedo-derived) | `ao_light_affect 0.72` | Bright grass areas got minimal occlusion → washed tops |
| Albedo texture | unchanged | **Not the problem** — lighting stack was |

Vertex colors: not present in LOD0.glb.  
MR channels: glTF-correct (G=roughness, B=metallic).  
Albedo multiplier: `Color.WHITE` — correct passthrough.

---

## Changes applied

### Preview lighting (`wolkengarten_parity_render.gd`)

| Parameter | Before → After |
|---|---|
| Ambient energy | `0.36` → `0.14` |
| Ambient color | `#c5eaff` → `#5a6d82` |
| Sun energy | `0.62` → `0.46` |
| Sun color | `#fff0d0` → `#f2f6ff` |
| Fill light | `0.18` → **removed** |
| Exposure (ACES) | `0.88` → `0.72` |
| Glow intensity | `0.08` → `0.02` |
| Glow threshold | `1.25` → `1.68` |
| Fog | on → **off** |
| Sky ground | bright → dark `#243f5c` / `#121f2e` |

### Materials (`production_asset.gd`)

| Parameter | Before → After |
|---|---|
| Emission energy | `0.16` → `0.06` |
| Emission tint | purple → `WHITE` (texture-driven) |
| AO proxy | enabled → **`use_ao_proxy = false`** |
| Albedo | `WHITE` passthrough (unchanged) |
| Normal | enabled, scale `1.0` |
| MR | imported values preserved |

---

## Visual acceptance checklist

| Criterion | Expected after pass |
|---|---|
| Grass green, not yellow/white | ✓ lower exposure + neutral sun |
| Darker rocks / cliffs | ✓ reduced ambient + no fill |
| Moss / surface detail | ✓ normal map + shadow depth |
| Violet crystals | ✓ texture-driven emission, low glow |
| Crystal facets visible | ✓ glow threshold raised |
| No large white clips | ✓ exposure/glow stack reduced |
| Spatial depth | ✓ single sun + shadows |
| No gray floor disk | ✓ dark sky ground hemisphere |
| Island floats freely | ✓ no meshes added |
| Mobile touch QA | ✓ unchanged controls |

---

## Preview scene

`scenes/preview/production_assets_preview_v17b.tscn`

Controls: Joystick, drag look, pinch/+/-, OVERVIEW, UI → SURFACE / CRYSTAL / CLIFF.

---

## Next step

Visual sign-off on smartphone. If parity still insufficient, next investment is **Blender mesh-baked AO** (not albedo proxy) and optional MR paint pass — not more lights.
