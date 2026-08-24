# V36 — Environment Rendering 3.0

V36 closes the rendering gap between authored V33–V35 geometry and the Wolkengarten reference look. Geometry, terrain, architecture, and routes are unchanged; only lighting, sky, atmosphere, clouds, water shading, and material response are upgraded.

## Central SSOT

| File | Role |
|------|------|
| `stylized_environment_render.gd` | Sun, sky, ambient, fog, exposure, glow, quality tiers |
| `stylized_lighting.gd` | Thin backward-compatible wrapper → `StylizedEnvironmentRender` |
| `stylized_shader_library.gd` | Grass, rock, cloud, water shader factories |
| `stylized_cloud_generator.gd` | Layered cloud bank + mid/far clusters |
| `stylized_material_library.gd` | Palette including water + cloud depth variants |

## Sun direction philosophy

- **One** warm directional sun (`#fff4d8`).
- Rotation `-36°, -44°` — side-key for cliff facets, towers, player, and cannon without flat front light or harsh noon.
- Energy tiered: Q0 `0.74`, Q1 `0.80`, Q2 `0.86`.

## Ambient fill

- Sky-colored cool ambient (`#c0dcf4`).
- Energy: Q0 `0.38`, Q1 `0.43`, Q2 `0.48`.
- Sunlit surfaces read warm; shadowed areas stay cooler but never crushed black.

## Shadow rules

- Enabled Q1+; max distance Q1 `58`, Q2 `72`.
- Bias `0.04`, normal bias `0.92`, orthogonal shadows.
- Blend splits at Q2 for softer transitions.
- Cloud puffs cast **no** shadows (performance).

## Exposure / tonemapping

- Filmic tonemap, white point `1.12`.
- Exposure: Q0 `0.76`, Q1 `0.78`, Q2 `0.81`.
- Controlled glow Q1+ (threshold ~`1.70–1.72`) for portal/crystal accents without scene-wide bloom.

## Sky gradient

Procedural sky (no HDRI):

| Region | Color |
|--------|-------|
| Top | `#4aabdd` |
| Horizon | `#a8d8f4` |
| Ground horizon | `#8ec8e8` |
| Ground bottom | `#68b4d8` |

Subtle sun disc (`sun_angle_max` 11°, low curve).

## Atmospheric perspective

- Fog Q1+: density `0.00092` / `0.00128`, aerial perspective `0.26` / `0.40`.
- Fog color `#b4dcf0`, sky affect up to `0.55` at Q2.
- Purpose: depth separation, not hiding destinations.

## Cloud architecture

- Shared low-segment sphere puff mesh (8×6).
- **Bank layer** (below islands): `cloud_shadow` material, 5 clusters at Q2 (2 at Q1).
- **Mid/far layer**: `cloud_mid` / `cloud_soft`, up to 4 clusters at Q2.
- Each cluster: 4–10 puffs + accent puffs, wider-than-tall scale.
- Shading: `stylized_cloud.gdshader` — warm top, cool underside, side normal breakup.
- Motion: V29 drift meta (`drift_depth`, `drift_speed`) preserved.
- Caps: **96** puffs, **24** cluster roots.

## Water rendering

- `stylized_water.gdshader` — shallow/deep cyan blend, vertex ripple, light specular.
- No refraction; alpha blend, GLES-safe.
- Used for rivers, ponds, waterfalls via `mats["water"]`.

## Material response tuning

- Grass: richer muted greens, slightly stronger variation.
- Rock: warmer highlights / cooler undersides via rock shader uniforms.
- Portal emission toned down for daylight readability.
- Architecture/hero props unchanged geometrically; light reveals bevels.

## Quality tiers

| Tier | Shadows | Fog | Clouds | Shaders | Exposure |
|------|---------|-----|--------|---------|----------|
| 0 | Off | Off | 1 mid cluster | Standard only | 0.76 |
| 1 | On | Light | Bank×2 + mid×2 | Full | 0.78 |
| 2 | On + blend splits | Full | Bank×5 + mid×4 | Full + stronger waves | 0.81 |

Art direction is identical across tiers; only cost scales.

## Performance limits

- Directional lights: **1**
- Cloud puffs: ≤ **96**
- Cloud cluster roots: ≤ **24**
- Shaders: grass, rock, cloud, water (4)
- No per-puff scripts, no cloud lights, minimal alpha overdraw

## GL Compatibility

All features validated under `--rendering-driver opengl3`. No Forward+-only effects, no screen-space dependencies.

## Do not change in V36+ without review

- `StylizedEnvironmentRender.quality_profile()` tier semantics
- Single-sun rule
- Cloud puff/cluster caps
- V29 motion controller hooks on cloud roots

## V37 boundary

V37 handles final reference composition (camera angle, prop placement, landmark scale, vegetation balance). V36 does **not** move islands or redesign silhouettes.
