# Phase 17B.1 — Godot Import / Project Startup Hotfix

**Date:** 2026-08-21  
**Goal:** Restore fast Godot startup by removing non-gameplay heavy 3D assets from `res://` while preserving all originals outside the project root.

---

## 1. Analysis (before cleanup)

| Metric | Value |
|--------|------:|
| `res://` total size (excl. `.git`) | **280.8 MB** |
| GLB/GLTF count | **18** |
| GLB total size | **269.5 MB** |
| Art texture size (PNG under `art/`) | **10.7 MB** |
| `.godot/` import cache | **none present** (clean slate on next editor open) |

### Largest GLB sources (before)

| Size (MB) | Path |
|----------:|------|
| 20.34 | `production/asset_02_floating_island/base_basic_pbr.glb` |
| 18.56 | `production/asset_03/base_basic_pbr.glb` |
| 18.33 | `production/asset_02_floating_island/game_ready/LOD0.glb` |
| 18.32 | `production/asset_01/base_basic_pbr.glb` |
| 17.56 | `production/asset_02_floating_island/game_ready/LOD1.glb` |
| 17.22 | `production/asset_02_floating_island/game_ready/LOD2.glb` |
| 16.18 | `production/asset_01/game_ready/LOD0.glb` |
| 16.05 | `production/asset_03/game_ready/LOD0.glb` |
| 15.44 | `production/asset_03/game_ready/LOD1.glb` |
| 15.24 | `production/asset_03/game_ready/LOD2.glb` |

**Root cause:** Three ~120k Rodin originals, shaded variants, nine game-ready LOD sets, deprecated broken LODs, and dual preview pipelines all coexisted under `res://`, forcing Godot to import ~270 MB of mesh data on project open.

---

## 2. Actions taken

### Source assets moved outside project root

**Archive path (not in Git):**

```
c:\Users\manue\Downloads\LOOT_LAUNCH_SOURCE_ASSETS\
```

Relative: `../LOOT_LAUNCH_SOURCE_ASSETS/`

Git safety: all moved files were present on `main` at commit `1ddd6c3` before any moves.

| Archive folder | Contents moved |
|----------------|----------------|
| `rodin/asset_01/` | Full asset 1 folder (original PBR, shaded, emissive, game_ready LODs, metadata) |
| `rodin/asset_03/` | Full asset 3 folder |
| `rodin/floating_island/` | `base_basic_pbr.glb`, `base_basic_shaded.glb`, `rodin_metadata.json` |
| `deprecated/broken_external_lods/floating_island_base01/` | UV-broken external decimation LOD0/1/2 + sidecars |

**External archive total:** 32 files, **~217.5 MB**

### `res://` production trim

Kept only floating-island gameplay production:

```
art/models/production/asset_02_floating_island/
├── game_ready/LOD0.glb
├── game_ready/LOD1.glb
├── game_ready/LOD2.glb
├── game_ready/pipeline_manifest.json
└── texture_emissive.png
```

### Preview de-escalation

| Change | Detail |
|--------|--------|
| `production_assets_preview_v17b.gd` | Floating island production only; no original compare; no asset 1/3 slots |
| `rodin_original_assets_preview_v17a` | Scene → `scenes/_archived/17b1/`; script shows archived warning |
| Other validation scenes | Moved to `scenes/_archived/17b1/` (see README there) |

### Import cache

No `.godot/` folder existed pre-cleanup. No manual cache deletion required. Next Godot open will import **3 GLBs + 1 emissive PNG** only.

### Gameplay unchanged

- `USE_PRODUCTION_ISLAND_0 := true` in `island_hopping_world.gd` — **unchanged**
- Ballistics, cannon, lootling, contracts, backend, expedition radii — **unchanged**
- No new LOD decimation or asset integration

---

## 3. Results (after cleanup)

| Metric | Before | After | Delta |
|--------|-------:|------:|------:|
| `res://` total size | 280.8 MB | **63.3 MB** | **−217.5 MB (−77%)** |
| GLB count | 18 | **3** | **−15** |
| GLB total size | 269.5 MB | **53.1 MB** | **−216.4 MB** |

---

## 4. Checklist (requested report fields)

| # | Item | Result |
|---|------|--------|
| 1 | Size `res://` before | **280.8 MB** |
| 2 | Size `res://` after | **63.3 MB** |
| 3 | GLB count before / after | **18 / 3** |
| 4 | Largest archived import sources | asset_02 original PBR (20.3 MB), asset_03 original (18.6 MB), asset_01 original (18.3 MB), asset_01/03 game_ready LOD sets (~14–16 MB each), deprecated broken LODs (~11 MB each) |
| 5 | Production GLBs active in `res://` | `asset_02_floating_island/game_ready/LOD0.glb`, `LOD1.glb`, `LOD2.glb` |
| 6 | Rodin originals archived | **YES** — `../LOOT_LAUNCH_SOURCE_ASSETS/rodin/{asset_01,floating_island,asset_03}/` |
| 7 | Broken LODs archived | **YES** — `../LOOT_LAUNCH_SOURCE_ASSETS/deprecated/broken_external_lods/floating_island_base01/` |
| 8 | Production Island 0 still active | **YES** — `USE_PRODUCTION_ISLAND_0 = true`, `production_asset.gd` + `production_floating_island.tscn` |
| 9 | Missing resource paths (active game) | **NO** — main scene, production island wrapper, and v17B preview reference only remaining `res://` assets |
| 10 | Godot import test | **NICHT AUSFÜHRBAR** — Godot CLI not in PATH; no `.godot/` cache to headless-import against |
| 11 | Expected startup improvement | **~77% less mesh data under `res://`**, **15 fewer GLB imports**, no 120k originals or shaded duplicates on project scan; first editor open should re-import ~53 MB GLB + emissive only |

---

## 5. Active vs archived reference map

### Still loaded by normal game start

- `res://scenes/main.tscn`
- `res://scripts/environment/production_asset.gd` (via `island_hopping_world.gd` for island 0)
- `res://art/models/production/asset_02_floating_island/game_ready/LOD{0,1,2}.glb`
- `res://art/models/production/asset_02_floating_island/texture_emissive.png`

### Archived (intentional broken refs if opened)

- `scenes/_archived/17b1/*` — see `scenes/_archived/17b1/README.md`
- `scripts/preview/rodin_original_assets_preview_v17a.gd` — stub warning only

---

## 6. Restore procedure

1. Copy needed folders from `../LOOT_LAUNCH_SOURCE_ASSETS/` back under `res://art/models/`.
2. Optionally move archived scenes back from `scenes/_archived/17b1/`.
3. Delete `.godot/` if present, then reopen project for clean re-import.

---

## 7. Validation notes

- `tests/production_assets_v17b.gd` — validates floating island production paths only.
- `tests/rodin_original_assets_v17a.gd` — exits immediately with archived notice (sources not under `res://`).
- `floating_island_base01.gd` — `LOD_PATHS` emptied; emits explicit archive location error instead of importing deprecated GLBs.

**STOP.** No further asset integration or LOD optimization in this phase.
