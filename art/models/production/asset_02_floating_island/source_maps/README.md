# Island source maps (extracted from LOD0.glb)

Regenerate locally — **not committed** (see `.gitignore`).

```bash
npx @gltf-transform/cli copy art/models/production/asset_02_floating_island/game_ready/LOD0.glb art/models/production/asset_02_floating_island/source_maps/LOD0_extract.gltf
```

Outputs:

| File | Role |
|---|---|
| `baseColor_1.png` | Albedo atlas 2048² |
| `normal_1.png` | Normal atlas 2048² |
| `metallicRoughness_1.png` | MR atlas 2048² (G=roughness, B=metallic) |

AO proxy generation:

```bash
node scripts/tools/generate_island_ao_proxy.mjs
```

Writes `../texture_ao_proxy.png` (albedo-derived proxy — replace with Blender mesh bake when ready).
