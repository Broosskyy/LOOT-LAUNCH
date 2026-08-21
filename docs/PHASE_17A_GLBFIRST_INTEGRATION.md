# Phase 17A — First Production GLB Integration

**Status:** Complete (controlled vertical slice)  
**Date:** 2026-08-21  
**Asset:** `LOOT_LAUNCH_FloatingIsland_Base01_GodotReady.zip`  
**Recommendation:** **ADJUST** — proceed with one more in-engine visual pass on Android before mass GLB migration.

---

## Goal

Integrate exactly **one** production floating-island GLB at real gameplay scale, with separated render mesh and collision, without replacing the procedural island pipeline or changing ballistics, economy, backend, or route logic.

---

## Imported files

| File | Location | Notes |
| --- | --- | --- |
| `LL_FloatingIsland_Base01_LOD0.glb` | `art/models/environment/islands/floating_island_base01/` | ~25,156 tris, hero close-up |
| `LL_FloatingIsland_Base01_LOD1.glb` | same | ~12,553 tris, mid distance |
| `LL_FloatingIsland_Base01_LOD2.glb` | same | ~7,254 tris, far distance |
| `validation.json` | same | Source bounds and tri counts |
| `texture_emissive_source.png` | same | Backup emissive reference |
| `README.md` | same | Supplier notes from Rodin pipeline |
| `*.glb.import` | same | Godot 4.7 scene importer, `generate_lods=false` |

**Not modified:** `scripts/gameplay/island_hopping_world.gd`, Supabase, missions, contracts, ballistics, or economy.

---

## New project structure

```
art/models/
├── environment/islands/floating_island_base01/   # Phase 17A asset
├── gameplay/cannons/                             # reserved
└── props/                                        # reserved

scenes/
├── environment/floating_island_base01.tscn       # reusable island scene
└── preview/glb_island_preview_v17a.tscn        # isolated preview

scripts/
├── environment/floating_island_base01.gd         # island loader + collision
└── preview/glb_island_preview_v17a.gd            # preview lighting/camera/refs

tests/
└── glb_island_preview_v17a.gd                    # headless GLB integration test
```

---

## Scene structure

### `floating_island_base01.tscn`

```
FloatingIslandBase01 (Node3D) — script builds children at runtime
├── Visual (Node3D)
│   ├── LOD0 — scaled GLB instance, visibility_range_end ≈ 55 m
│   ├── LOD1 — visibility_range 50–120 m
│   └── LOD2 — visibility_range_begin ≈ 115 m
└── GameplayCollision (StaticBody3D, layer 1)
    ├── WalkSurface — CylinderShape3D (walkable plateau)
    └── LandingRim — thin cylinder for landing edge contact
```

Render geometry **never** becomes trimesh collision.

### `glb_island_preview_v17a.tscn`

Isolated preview containing:

- Production GLB island at Wolkengarten island-0 scale
- Mint gameplay-radius guide ring (11.648 m)
- Lootling scale reference (sphere + collision capsule)
- Cannon scale reference (base + barrel at `Vector3(0, 0.92, -2.2)`)
- Wolkengarten-style `WorldEnvironment`, directional + rim light
- Camera presets: **1** orbit, **2** aim, **3** flight, **4** wide

**Open preview:** run `scenes/preview/glb_island_preview_v17a.tscn` as the main scene (temporarily) or instantiate from the editor.

---

## Scale mapping

Derived from procedural island 0 in `island_hopping_world.gd`:

| Parameter | Procedural reference | GLB mapping |
| --- | ---: | --- |
| Visual source radius | `12.8` m (`ROUTE_RADII[0]`) | `visual_scale = 12.8 / 0.96` |
| **Visual scale** | — | **`13.333333`** |
| Gameplay collision radius | `12.8 × 0.91 = 11.648` m | `CylinderShape3D.radius` |
| Collision thickness | `1.45` m (island 0) | walk collider height |
| Floor offset | `0.84` m (`FLOOR_OFFSET`) | player Y on island top |
| Cannon offset | `(0, 0.92, -2.2)` | unchanged reference marker |
| GLB native bounds (LOD0) | — | X ±0.96, Y 0–1.05, Z ±0.9 (metres) |

The visible mesh may extend beyond the walkable cylinder — same pattern as procedural islands where decoration sits outside the hidden cylinder collider.

---

## Collision solution

Matches the procedural approach in `_add_floating_island()`:

- **WalkSurface:** `CylinderShape3D`, radius `11.648`, height `1.45`, centred below Y=0
- **LandingRim:** slightly wider thin cylinder at plateau height for flight landing edge tolerance
- **collision_layer = 1** — same mask used by `_resolve_camera_occlusion()`
- No mesh collider on the 25k-tri render shell

---

## LOD solution

Three separate GLB files (not Godot auto-LOD) switched via **`GeometryInstance3D.visibility_range_*`** on each mesh under the LOD root:

| LOD | Triangles | Visibility |
| --- | ---: | --- |
| LOD0 | ~25,156 | 0 – 55 m |
| LOD1 | ~12,553 | 50 – 120 m |
| LOD2 | ~7,254 | 115 m + |

Margins: 8 / 10 / 12 m for cross-fade.  
Importer: `meshes/generate_lods=false` to avoid duplicating LOD work.

**Mobile note:** At typical island-hop distances (camera within ~15 m on foot, ~25 m while aiming), LOD0 is correct. Distant backdrop islands should use LOD1/LOD2 when this asset replaces silhouettes.

---

## Material status

On load, `floating_island_base01.gd` enforces:

- `transparency = DISABLED` on all `BaseMaterial3D` surfaces
- `depth_draw_mode = OPAQUE_ONLY`
- Embedded PBR + emissive from GLB preserved; emission energy floored at `0.35` when enabled

Headless validation (`validate_materials()`) fails if any rock/grass surface enters the alpha pipeline.

**Manual check still required:** crystal emissive strength and brass response under portrait aim camera (71° FOV) on a real device.

---

## Performance estimate

| Scenario | Estimate |
| --- | --- |
| One island LOD0 at preview distance | ~25k tris — within `AI_3D_ASSET_PIPELINE.md` budget (12k–30k) |
| Three LODs loaded (only one visible) | All three nodes exist; only one range-active — acceptable for preview, review for shipping |
| Textures | 2K embedded × 3 files — **heavy on memory** if all three stay resident; consider shared material atlas in Phase 17B |
| Collision | 2 cylinders — negligible CPU |
| vs. procedural island 0 | Similar tri order; GLB adds texture memory, removes runtime `SurfaceTool` generation |

**Akku tier:** When this replaces a playable island, force LOD1 within 40 m or share one material atlas to reduce VRAM.

---

## Analysis of existing systems (unchanged)

| System | Procedural behaviour | Phase 17A impact |
| --- | --- | --- |
| Island generation | `ArrayMesh` plateau + cliff in `_add_floating_island()` | Untouched; GLB is parallel |
| Collision | Hidden cylinder, radius `× 0.91` | Mirrored in GLB scene |
| Player movement | `CharacterBody3D` + capsule, floor at `center.y + 0.84` | Preview markers only |
| Cannon placement | `route_centers[i] + (0, 0.92, -2.2)` | Reference in preview |
| Landing detection | Horizontal distance vs `route_radii[i]` | Not wired in preview |
| Ballistics / aim | `_predict_target_impact()`, gesture aim | Not modified |
| Camera occlusion | Ray mask layer 1 vs static bodies | GLB collision on layer 1 |
| Quality tiers | `quality_level` 0–3, fog/shadows/pools | Preview uses “Hoch”-like lighting |

---

## Tests

### New test

```bash
godot --headless --path . --script res://tests/glb_island_preview_v17a.gd
```

Validates: scale constants, LOD separation, collision vs visual, opaque materials.  
If GLBs are not yet imported, exits 0 after constant-only validation.

### Required regressions (must pass before Phase 17B)

```bash
godot --headless --path . --script res://tests/island_solidity_v16.gd
godot --headless --path . --script res://tests/all_hops_ballistics_v9.gd
godot --headless --path . --script res://tests/aim_camera_occlusion_v11.gd
godot --headless --path . --script res://tests/multi_expedition_v15.gd
godot --headless --path . --script res://tests/performance_balance_v10.gd
```

### Execution status in this environment

| Test | Status |
| --- | --- |
| `glb_island_preview_v17a.gd` | **Not executed** — Godot 4.7 CLI not available on host |
| `island_solidity_v16.gd` | **Not executed** — same |
| `all_hops_ballistics_v9.gd` | **Not executed** |
| `aim_camera_occlusion_v11.gd` | **Not executed** |
| `multi_expedition_v15.gd` | **Not executed** |
| `performance_balance_v10.gd` | **Not executed** |

**Note:** Preview scene is **outside** existing gameplay regression paths by design. Procedural route tests remain authoritative until a GLB island is swapped into `island_hopping_world.gd` in a later phase.

---

## Open problems

1. **Godot import not run here** — first open in Godot 4.7 will rebuild `.godot/imported/` caches (~33 MB GLB data).
2. **Triple 2K texture residency** — three separate GLB files may each embed textures; deduplicate in Blender before batch import.
3. **Visual vs walkable plateau** — artist mesh lip may extend past the 11.648 m cylinder; verify feet/clipping in preview orbit camera.
4. **Underside/cliff closure** — must confirm no alpha holes from Android Compatibility angle (preview key **4** wide shot).
5. **No runtime swap yet** — expedition still 100% procedural.

---

## Recommendation: **ADJUST**

| Criterion | Verdict |
| --- | --- |
| Scale mapping | **GO** — math aligned to island 0 |
| Collision architecture | **GO** — matches procedural pattern |
| LOD approach | **GO** — visibility ranges sufficient for v1 |
| Material pipeline | **ADJUST** — verify emissive + opaque cliffs on device |
| Memory / mobile | **ADJUST** — shared textures before replacing 6 islands |
| Gameplay integration | **STOP** — preview only, as planned |

**Next steps (Phase 17B proposal, not executed):**

1. Open preview on Android Akku + Ultra tiers.
2. Profile VRAM with three LOD files loaded.
3. Replace **only** Wolkengarten `SkyIsland00` behind a feature flag after visual sign-off.
4. Deduplicate textures across LOD GLBs in Blender.
5. Re-run full regression suite on device.

---

## Quick verification checklist (manual)

1. Godot 4.7 → open project → wait for GLB import.
2. Run preview scene → keys **1/2/3/4** for camera modes.
3. Confirm mint ring matches walkable area under lootling feet.
4. Confirm cannon sits naturally on plateau near `(0, 0.92, -2.2)`.
5. Run six regression scripts listed above.
6. Compare LOD0 cliff underside against procedural solidity test intent.
