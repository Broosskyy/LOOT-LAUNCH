# Phase 18 — Wolkengarten A + B

**Date:** 2026-08-21  
**Tracks:** A) PBR texture upgrade · B) Gameplay integration (Lootling + Kanone)

---

## A — PBR texture upgrade

### Added

| Asset / tool | Purpose |
|---|---|
| `texture_ao_proxy.png` | 2048² AO derived from albedo atlas (proxy until Blender bake) |
| `scripts/tools/generate_island_ao_proxy.mjs` | Regenerate AO proxy from extracted albedo |
| `source_maps/README.md` | Extract + edit workflow for embedded maps |
| `production_asset.gd` | Optional `ao_texture_path`, `ao_light_affect` (0.72) |

### Still missing (authored later)

- True mesh-baked AO
- Separate roughness refinement map
- Height / displacement

### MR interpretation (unchanged)

- **Green channel** → roughness  
- **Blue channel** → metallic  
- Scalar factors preserved from glTF import

---

## B — Gameplay integration

### Already present

- `USE_PRODUCTION_ISLAND_0 := true` — island 0 GLB visual in Wolkengarten
- Lootling + cannon procedural at existing spawn/cannon offsets
- Main flow: loadout → `island_hopping_world.begin()`

### Changed in this phase

| Area | Change |
|---|---|
| **Lighting (Wolkengarten only)** | ACES tonemap, exposure 0.88, ambient 0.36, glow 0.08, sun 0.62 — matches material QA preview |
| **Island 0 decor** | Lite mode: side trees + lanterns only; no duplicate path stones / grass / cannon pad |
| **Island 0 landmark** | Windmill removed on production island; banner kept at edge |

### Unchanged

- Cylinder gameplay collision
- Cannon at `(0, 0.92, -2.2)` per island
- Player spawn `(-2, 0.84, 2)`
- Islands 1–5 procedural

---

## How to test on smartphone

### Preview (material only)

`scenes/preview/production_assets_preview_v17b.tscn`

### Gameplay (Lootling + Kanone)

1. Launch app → Wolkengarten expedition  
2. Choose Lootling + cannon loadout  
3. Walk island 0 → cannon → aim → hop  

Compare island 0 materials between preview and gameplay — lighting should now match.

---

## Next decisions after visual review

| If materials sufficient | → proceed gameplay polish on islands 1–5 |
| If AO/MR still weak | → Blender bake AO + MR paint pass on `source_maps/` extracts |
