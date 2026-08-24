# V29 — VFX & Animation Standard

V29 adds motion and lightweight VFX only. V25 composition, V26 materials, V27 geometry, and V28 density remain locked.

## Principles

- **Visual roots only** — squash, bob, recoil, and sway must not move physics/collision roots.
- **Soft motion** — low amplitude, slow speeds, phase variation between instances.
- **Mobile-first** — shader wind over per-plant AnimationPlayer; strict particle caps.
- **Gameplay readability** — rings stay on route; effects never obscure landing or aim.

## Amplitude & Speed Rules

| System | Amplitude | Speed |
|--------|-----------|-------|
| Grass / leaf wind (shader) | Q1 0.038, Q2 0.055 vertex units | 0.95–1.12 rad/s |
| Flower sway (script) | ±0.08 rad Z, ±0.05 rad X | ~1.0–1.25 rad/s |
| Cloud drift | 1.0–1.9 m horizontal | 0.08–0.18 rad/s by depth |
| Gold rings | 0.11 m bob + slow Y spin | ~1.85 rad/s rotation |
| Portal rings | counter-rotating Y | 0.55 rad/s |
| Pad energy | Y spin + emission pulse | 0.42 rad/s |
| Hero crystals | 0.045 m hover + pulse | 0.35 rad/s Y |
| Lootling idle | 0.028 m breath, 2.5% squash | 2.6 rad/s |
| Lootling move | 0.06 m bob, lean ±0.08 rad | 10.5 rad/s step |
| Cannon recoil (visual pivot) | 0.26 m local kick | 0.07s out, 0.24s return |

## Wind Philosophy

- Shared `stylized_grass.gdshader` wind uniforms on grass and leaf materials.
- Height-masked sine sway: tips move, bases stay grounded.
- Q0: wind strength 0 (no vertex sway cost).
- Flowers use cheap root sway (few instances).

## Particle Budgets (visible caps)

| Tier | Portal ambient | Collect burst | Cannon burst |
|------|----------------|---------------|--------------|
| Q0 | 4 | 4 | 8 |
| Q1 | 12 | 8 | 16 |
| Q2 | 18 | 12 | 22 |

Bursts scale by `effect_density` and reuse pooled spark meshes.

## Quality Tiers

- **Q0** — cloud drift, simple ring motion, no wind shader, minimal particles.
- **Q1** — standard wind, limited particles.
- **Q2** — full V29 motion and restrained particles.

## Architecture

- `StylizedMotionController` — wind config, clouds, pickups, portal/pad/crystal, Lootling, recoil, collect pop.
- `StylizedVFXController` — tier caps for bursts and ambient particles.
- `wind_streamers` array — portal rings, pad nodes, hero crystals (meta-driven).

## Portal Motion

- Outer ring: `animate_portal` (+Y).
- Inner ring: `animate_portal` + `portal_counter` (−Y).
- Emission pulse on energy materials via `StandardMaterial3D.emission_energy_multiplier`.

## Ring Motion

- Flight route rings: Y rotation + height bob with per-ring `phase`.
- Collection: scale pop then shrink (`play_collect_pop`).

## Cannon Recoil

- Stylized: `AimPivot` local kick using `recoil_origin` meta — **not** `cannon_root`.
- Muzzle burst uses tier-capped violet + brass sparks.

## Lootling Procedural Motion

- `PlayerVisual` child of physics body; sprout `Sprout` node for leaf sway.
- Jump: stretch; land: squash + elastic return; walk: lean + step bob.

## Cloud Drift

- Cluster roots move as units (`StylizedCloudGenerator` sets `drift_depth`, `drift_speed`).
- No per-puff scripts.

## Deferred to V30

- Final camera micro-tuning
- Final prop screen-space balancing
- Final VFX density vs reference screenshot
- Final color/atmosphere micro-tuning
