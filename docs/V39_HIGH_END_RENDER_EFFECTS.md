# V39 — High-End Stylized Render & Effects

V39 upgrades presentation of the V38 surface system: lighting hierarchy, depth grading, clouds, water, restrained VFX, and ambient motion. No geometry or gameplay changes.

## Central SSOT

| File | Role |
|------|------|
| `stylized_render_effects.gd` | Sky 4.0, fog/depth, sun/shadow polish, glow tiers, validation |
| `stylized_lighting.gd` | Delegates to `StylizedRenderEffects` |
| `stylized_cloud_generator.gd` | Low / mid / far cloud layers |
| `stylized_vfx_controller.gd` | Particle caps, waterfall mist, cannon smoke |
| `stylized_motion_controller.gd` | Async wind, cloud drift, pickup motion |

## Lighting hierarchy

- **One sun** — warm `#fff2d4`, rotation `-36°, -46°`.
- Energy: Q0 `0.72`, Q1 `0.80`, Q2 `0.88`.
- Ambient cool fill `#c4dcf4` — Q0 `0.40`, Q1 `0.46`, Q2 `0.50`.
- Foreground reads via sun key; background softened via fog/aerial perspective.

## Shadow polish

| Tier | Max distance | Notes |
|------|--------------|-------|
| Q0 | off | Performance |
| Q1 | 64 | Bias `0.048`, normal bias `1.06` |
| Q2 | 84 | Blend splits, angular distance `0.38` |

Cloud puffs cast no shadows.

## Sky 4.0

| Region | Color |
|--------|-------|
| Zenith | `#2a8ec8` |
| Mid horizon | `#9ad8f0` |
| Ground horizon | `#d4f0fc` |
| Ground bottom | `#78b8dc` |

Sun disc influence via `sun_angle_max` 11.5–13°.

## Depth grading

- Fog Q1+: density `0.00082` / `0.00105`, aerial `0.34` / `0.48`.
- Fog color `#b0d8f0`, sky affect up to `0.62` at Q2.
- Far clouds use `cloud_far` with higher `depth_fade`.
- Filmic exposure Q0–Q2: `0.78` → `0.84`.

## Cloud architecture (3 layers)

| Layer | Material | Drift speed | Scale |
|-------|----------|-------------|-------|
| Low bank | `cloud_shadow` | 0.05 | Largest, underside |
| Mid | `cloud_mid` / `cloud_soft` | 0.09 | Medium clusters |
| Far | `cloud_far` | 0.13 | Soft, desaturated |

Caps: **96** puffs, **28** cluster roots. Improved puff scale jitter and accent puffs.

## Water 4.0

`stylized_water.gdshader` additions:
- Moving highlight bands
- Bank foam via `foam_strength`
- Waterfall mode: dual streak layers, lateral ripple
- `mats["waterfall"]` for falls; `mats["water"]` for rivers/ponds

## Portal / crystal VFX

- Crystal shader: TIME pulse + sparkle on hero crystals
- Portal rings: counter-rotation (`portal_counter` meta)
- Restrained glow threshold ~`1.74–1.78` at Q1+

## Cannon / collectibles

- Muzzle: violet + brass burst + optional smoke puff (Q1+)
- Recoil easing via `StylizedMotionController.play_cannon_recoil`
- Ring pickups: restrained bob/rotation

## Vegetation motion

- Grass: higher wind response
- Leaves: `TREE_WIND_SCALE` 0.42 of grass amplitude
- Async phases per material key hash

## Particle budget (Q2)

| Effect | Cap |
|--------|-----|
| Cannon burst | 20 |
| Cannon smoke | 6 |
| Portal motes | 14 |
| Collect burst | 12 |
| Waterfall mist | 10 |
| Ambient | 12 |
| **Hard ceiling** | 48 active |

## Shader budget

- **8** shared shaders (unchanged from V38)
- **3** procedural textures (~192 KB)
- **1** directional light
- No screen-space effects

## Quality tiers

| Tier | Render |
|------|--------|
| Q0 | Base colors, no fog/glow/shadows |
| Q1 | Full V39 lighting, reduced particles |
| Q2 | Full clouds, foam, mist, sparkle |

## Performance rules

- Prefer macro atmosphere over per-pixel effects
- No cloud shadow projection
- No fluid simulation
- GLES Compatibility only
