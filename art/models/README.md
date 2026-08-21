# LOOT LAUNCH 3D asset slots

Godot 4 imports `.glb`/glTF assets placed in this directory automatically.

## Active production under `res://` (Phase 17B.1)

Only **Floating Island Base01** game-ready assets remain imported for current gameplay:

- `production/asset_02_floating_island/game_ready/LOD0.glb`
- `production/asset_02_floating_island/game_ready/LOD1.glb`
- `production/asset_02_floating_island/game_ready/LOD2.glb`
- `production/asset_02_floating_island/texture_emissive.png`

Gameplay wrapper: `res://scenes/environment/production_floating_island.tscn`  
Preview (production only): `res://scenes/preview/production_assets_preview_v17b.tscn`

## Source archive (outside project)

Rodin originals (~120k PBR), shaded comparison GLBs, asset 1/3 game-ready LODs, and deprecated broken external LODs were moved to:

**`../LOOT_LAUNCH_SOURCE_ASSETS/`** — see `art/models/SOURCE_ARCHIVE_LOCATION.md`

## Deprecated / archived

- Phase 17A broken external LODs → external `deprecated/broken_external_lods/`
- Validation scenes → `scenes/_archived/17b1/`
- `environment/islands/floating_island_base01/` — documentation slot only (GLBs archived)

## Pending slots

- `gameplay/cannons/` — cannon replacements (pending)
- `props/` — chests, portals, mushrooms, etc. (pending)

Source concept: `res://art/concept/loot-launch-asset-kit-v16.png`.

Required conventions:

- metre scale, Y up, forward is -Z;
- object origin at its gameplay pivot;
- closed manifold meshes with outward normals;
- opaque PBR materials for stone, grass, brass and characters;
- transparency only for portal energy or particles;
- one 1024 px texture set per normal prop, at most 2048 px for hero assets;
- mobile-friendly triangle budgets documented in `docs/AI_3D_ASSET_PIPELINE.md`.
