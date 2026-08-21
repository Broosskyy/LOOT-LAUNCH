# Wolkengarten Environment Preview Polish

**Date:** 2026-08-21  
**Scope:** Preview-only (`production_assets_preview_v17b`) — no gameplay integration.

---

## Lighting fix (overexposure)

**Cause:** Combined stack of high sun energy (0.94), strong ambient (0.60), Filmic tonemap without exposure control, glow intensity 0.38, and GLB emissive override at 0.42 — bloom pushed grass/crystal highlights to white on mobile.

**Correction (preview only):**

| Setting | Before | After |
|---------|--------|-------|
| Tonemap | Filmic | **ACES** + exposure **0.92** |
| Sun energy | 0.94 | **0.68** |
| Ambient energy | 0.60 | **0.42** |
| Glow intensity | 0.38 | **0.16** (threshold 1.12, bloom 0.08) |
| GLB emissive (preview instance) | 0.42 | **0.26** + runtime cap **0.26** |
| Rim omni | none | **0.55** (soft fill, not 1.35) |
| Fog light energy | none | **0.38** |

Gameplay `production_asset.gd` defaults unchanged.

---

## Environment dressing (preview module)

`scripts/preview/wolkengarten_preview_environment.gd`

- Atmospheric backdrop quad + distant silhouettes + cloud layers
- Composed surface scatter: grass tufts, flowers, pebbles, path edge stones
- Soft crystal accents + shard clusters at hero crystal areas
- Integration markers (spawn, cannon pad, walk radius) — UI toggle only

Dressing is parented under the production island node; atmosphere is sibling — clean separation for later gameplay merge.

---

## Controls polish

- Look zone starts below toolbar (`y >= 72`) to reduce touch/button overlap
- Preview collision disabled on island wrapper (fly camera only)

---

## Performance

- All preview deco uses low-poly primitives (cylinders, prisms, spheres)
- Shadow casting off on dressing + atmosphere
- Visibility range cull on small props (< 120 m)
- No extra dynamic lights beyond sun + one soft rim

---

## Gameplay

**Lootling / cannon / combat:** intentionally **not** integrated in this preview pass.

Island remains integration-ready via spawn/cannon/walk markers and unchanged `production_asset.gd` gameplay path.

---

## Files changed

- `scripts/preview/production_assets_preview_v17b.gd`
- `scripts/preview/wolkengarten_preview_environment.gd` (new)
- `docs/PHASE_17B_WOLKENGARTEN_PREVIEW_POLISH.md` (this file)

Open: `scenes/preview/production_assets_preview_v17b.tscn`
