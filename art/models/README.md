# LOOT LAUNCH 3D asset slots

Godot 4 imports `.glb`/glTF assets placed in this directory automatically.
The production replacement set is intentionally modular:

## Directory layout (Phase 17A+)

- `environment/islands/floating_island_base01/` — first production island GLB (LOD0–LOD2)
- `gameplay/cannons/` — cannon replacements (pending)
- `props/` — chests, portals, mushrooms, etc. (pending)

## Planned root-level slots

- `cannon_standard.glb`
- `island_cliff_chunk_a.glb`
- `portal_arch.glb`
- `treasure_chest.glb`
- `spring_mushroom.glb`
- `bouncer.glb`

Source concept: `res://art/concept/loot-launch-asset-kit-v16.png`.
Reusable island scene: `res://scenes/environment/floating_island_base01.tscn`.
Preview scene: `res://scenes/preview/glb_island_preview_v17a.tscn`.

Required conventions:

- metre scale, Y up, forward is -Z;
- object origin at its gameplay pivot;
- closed manifold meshes with outward normals;
- opaque PBR materials for stone, grass, brass and characters;
- transparency only for portal energy or particles;
- one 1024 px texture set per normal prop, at most 2048 px for hero assets;
- mobile-friendly triangle budgets documented in `docs/AI_3D_ASSET_PIPELINE.md`.
