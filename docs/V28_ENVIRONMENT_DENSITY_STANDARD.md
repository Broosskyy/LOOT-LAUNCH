# V28 Environment Density Standard

V28 enriches vegetation placement and clustering without changing V25 composition, V26 materials, or V27 geometry.

## Density hierarchy

| Zone | Density | Content |
|---|---|---|
| Foreground (start island) | Highest | Zoned grass/flowers/shrubs/trees |
| Midground (destination) | Medium-high | Tree clusters, portal framing |
| Playable/route islands | Variable identity | Per-island patterns |
| Vista / distant | Low | 0–2 tree silhouettes only |
| Hero landmark | Medium | Tree cluster + shrubs + sparse vine |

## Quality tiers

SSOT: `stylized_vegetation_density.gd`

| Tier | Scale | Behavior |
|---|---|---|
| Q0 | 42% | Skip every 2nd–3rd accent, no vista trees |
| Q1 | 76% | Skip every 2nd accent |
| Q2 | 100% | Full V28 density |

## Start island zones

- **A Spawn:** minimal — exclusion radius 1.65m
- **B Path:** medium along edges, path corridor excluded (0.48m)
- **C Chest:** shrubs + flowers
- **D Cannon:** low grass only, exclusion 2.35m
- **E Pad:** low violet/pink accents
- **F Ruin/Sign:** medium-high shrubs + vines
- **G Cliff edge:** ~38% ring coverage, clustered (not uniform)

## Exclusion zones

`start_island_exclusions()` — spawn, cannon, chest, pad, path terminus.

`is_path_corridor()` — prevents blocking walk line.

## Clustering rules

- Trees: `create_tree_cluster()` — main + support, asymmetric offset
- Grass: clumps + `create_grass_multimesh_patch()` for edge batches
- Flowers: accent clusters near props, not carpet
- Shrubs: ruin/chest/portal transitions
- Vines: max 2–3 on start island, sparse on ruins

## Performance

- MultiMesh for grass edge patches (5 instances per patch)
- Shared blade/crown meshes (cached)
- Vegetation node budget: < 120 per start island decor root
- Visibility range culling on small meshes (world `_mesh`)

## Determinism

All placement uses seeded `RandomNumberGenerator` — same world seed + island index = same layout.

## Deferred

- **V29:** wind, sway, particles, animated portal/crystals
- **V30:** final composition micro-tuning, screenshot-specific density balance
