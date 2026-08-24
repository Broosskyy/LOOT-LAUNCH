# V27 Procedural Model Standard

V27 upgrades Godot-native procedural geometry while preserving V25 composition and V26 materials.

## Silhouette principles

- Hero objects must read clearly at gameplay distance without material detail.
- Use 2–5 major forms per object; avoid primitive stacks (cylinder-on-disc).
- Asymmetry is allowed but controlled — no random rubble soup.

## Bevel rules

- Use `StylizedMeshLibrary.beveled_box()` for chests, ruins, pads, sign boards.
- Bevel = 6–10% of smallest horizontal dimension.
- Top-face chamfer only; preserve faceted side normals.

## Faceting rules

- Stone, metal, wood: flat normals per face.
- Tree crowns: soft blob facets (7 segments × 4 rings).
- Cannon barrel: 10–12 radial segments, tapered profile.

## Material reuse

All models use V26 palette via `stylized_material_library.gd`. No new competing materials.

## Scale rules (relative to Lootling ~1.3m)

| Object | Height / footprint |
|---|---|
| Cannon | ~1.2m wide base, barrel ~2.8m long |
| Chest | ~0.6m tall, wider than tall |
| Portal | ~3.5m tall monument |
| Pad | ~1.6m square |
| Sign | ~1.4m post height |
| Trees | 1.2–1.8m total |

## Triangle budget (guidance)

| Object | Target tris |
|---|---|
| Cannon | 500–1500 |
| Chest | 250–700 |
| Portal | 500–1200 |
| Pad | 200–600 |
| Tree | 200–700 |
| Ruin module | 100–600 |
| Crystal cluster | 100–400 |

## Gameplay / visual separation

```
GameplayNode (collision, logic)
  └── VisualRoot
        └── generated MeshInstance3D children
```

- `AimPivot`, `MuzzleGlow`, `Lid`, `CannonCollider` names preserved.
- Decorative geometry never bound to gameplay child indices.

## Shared builders

SSOT: `stylized_mesh_library.gd`

- `beveled_box`, `tapered_cylinder`, `octagonal_plinth`
- `faceted_crystal`, `path_stone`, `small_rock`
- `curved_lid`, `ring_band`, `tapered_trunk`

## Deferred

- **V28:** vegetation density, flower/grass placement
- **V29:** portal animation, wind, particles, cannon recoil

## External asset hooks

Geometry is ArrayMesh-based. Future GLB replacement can swap visual roots without touching gameplay nodes.
