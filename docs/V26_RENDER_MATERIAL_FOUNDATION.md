# V26 Render & Material Foundation

V26 upgrades shading and materials without changing V25 composition (see `V25_VISUAL_LOCK.md`).

## Material palette

Central SSOT: `stylized_material_library.gd`

| Family | Keys | Surface |
|---|---|---|
| Grass | `grass_main`, `grass_light`, `grass_dark` | `stylized_grass.gdshader` (Q1+) |
| Rock | `stone_*`, `path_stone`, `ruin_stone`, `distant_rock` | `stylized_rock.gdshader` (Q1+) |
| Leaves | `leaf_*` | grass shader |
| Clouds | `cloud_soft`, `cloud_mid`, `cloud_shadow` | `stylized_cloud.gdshader` (Q1+) |
| Metals / wood / magic | brass, cannon_dark, wood, portal, crystals | StandardMaterial3D |

## Roughness / metallic rules

- Stone/grass/leaves: metallic 0, roughness 0.88–0.96
- Wood: metallic 0, roughness 0.86–0.92
- Brass: metallic 0.72, roughness 0.38, specular 0.42
- Dark metal: metallic 0.62, roughness 0.42
- Magic: low metallic, emission 0.28–0.52 (no white clip)

## Stylized shading

Shaders multiply albedo with mesh vertex colors and apply orientation-based
warm/cool tint (up-facing warmer, down-facing cooler). No textures. GLES-safe.

## Sun / ambient / shadows

SSOT: `stylized_lighting.gd`

- Single warm directional sun (`#fff2cc`, energy 0.74–0.80)
- Cool sky ambient fill (`#b8d8f0`, energy 0.40–0.50)
- Filmic tonemap exposure 0.78–0.80, white point 1.15
- Shadow bias 0.05, normal bias 1.05, blend splits at Q2

## Sky / fog

Procedural sky with clean cyan gradient. Tiered fog density unchanged in spirit
from V24 but tuned for depth without hiding destinations.

## Quality tiers

| Tier | Materials |
|---|---|
| 0 | StandardMaterial3D only (simplest) |
| 1+ | Full stylized shaders for grass/rock/cloud |

## Shader files

- `shaders/stylized/stylized_grass.gdshader`
- `shaders/stylized/stylized_rock.gdshader`
- `shaders/stylized/stylized_cloud.gdshader`

Managed by `stylized_shader_library.gd`.

## Do not change in V26+ without review

- V25 camera/composition constants
- Shader parameter semantics (vertex COLOR modulation)
- Emission caps for portal/crystal/pad
