# V40 — Visual Master Lock

**Canonical summary** of the Godot-native Wolkengarten art direction. Supersedes V30–V39 docs for production decisions. Future work must preserve values documented here unless explicitly revising the master lock.

## Reference role

The supplied Wolkengarten reference image is the visual authority. V40 tuned position, scale, density, camera, color, light, material, and effect intensity — no new geometry systems.

## Master SSOT

| File | Role |
|------|------|
| `stylized_visual_master.gd` | Camera, motion caps, validation, performance |
| `stylized_world_composition.gd` | Island layout, vista culling, spawn offsets |
| `stylized_render_effects.gd` | Sky, sun, fog, glow (V39 base, V40 polish) |
| `stylized_surface_library.gd` | Material family macro/vertex caps |
| `stylized_material_library.gd` | Final palette wiring |

## Camera master values

| Parameter | Value |
|-----------|-------|
| FOV | 52.5° |
| Pitch | 18.5° |
| Look height | 0.54 |
| Look ahead | 6.35 |
| Follow distance | 11.15 |
| Follow height | 2.74 |
| Route blend | 0.48 |

V31 gameplay orbit limits preserved. Spawn → walk → swipe → aim → flight → land validated.

## Terrain language

- Hero start island radius 9.0, thickness 1.42
- Path stones via `stylized_start_composition.gd`
- Edge grass coverage ~30% (reduced from 34%)
- Cliff/rock/grass edge via V34 terrain surface + V38 rock shader

## Surface language

- Q2 macro strength cap: **0.78** (was 1.0)
- Q2 vertex variation cap: **0.10**
- Palette: fresh green `#4a9454`, warm grey stone, gold brass, violet portal, peach bouncer

## Architecture language

- Start: path, chest, pad, corner ruin, sign, pillar — no jump gate clutter
- Midground (island 1): portal monument scale 1.22, stair + lookout ruin
- Hero landmark vista: index 22 at `(26, 10.4, -42)` radius 9.4
- Micro vistas 34/35: **hidden** from build

## Vegetation language

- Trees frame spawn (left cluster + right singles)
- Path corridor protected via exclusion zones
- Removed redundant mid-lawn flower clusters
- Leaves wind at 42% of grass amplitude

## Rendering

- Sun: `-38°, -42°`, warm `#fff4dc`
- Sky zenith `#2890c4`, horizon `#96d4ec`
- Fog density Q2: `0.00098`, aerial `0.46`
- Glow restrained: intensity `0.078`, threshold `1.76` at Q2

## Clouds

- Three layers: bank / mid / far
- Far clusters shifted to frame open sky over landmark corridor
- Drift scale: 0.88 of V39 amplitude

## Water

- River/pond: `mats["water"]`
- Waterfall: `mats["waterfall"]`
- Mega-island waterfall + mist at Q1+
- Spawn shot does not force water into frame

## VFX & animation

| Effect | Production cap |
|--------|----------------|
| Portal rotation | 0.38 rad/s |
| Ring bob | 0.016 amplitude |
| Cannon smoke | Q1+ only |
| Particle ceiling Q2 | 48 |

## Performance (Q2 typical)

| Resource | Budget |
|----------|--------|
| Shaders | 8 |
| Procedural textures | 3 (~192 KB) |
| Directional lights | 1 |
| Cloud puffs | ≤96 |
| Vista islands visible | 4 |
| Renderer | GL Compatibility |

## Things future work MUST preserve

1. Single sun, GLES-safe shaders
2. Camera master table in `stylized_visual_master.gd`
3. Wolkengarten route island positions (unless gameplay requires change)
4. Hidden micro vistas — do not re-add without composition review
5. Start island exclusion zones for path/cannon/player
6. Macro strength cap ≤0.78 at Q2
7. No external texture packs in stylized path

## Native art limit (honest)

| Gap type | Examples |
|----------|----------|
| Implementation weakness | Procedural puff clouds vs painted sky bands; blocky tree silhouettes |
| Procedural limitation | No hand-painted albedo; limited PBR response on mobile |
| Authored-asset advantage | Reference uses illustrated sky bands, painterly cloud shapes, bespoke hero mesh detail |

V40 closes the prototype gap to **PARTIALLY** — readable commercial stylized mobile look, not full illustrated parity.

## Version

- Visual version: **40**
- Commit message: `feat(art): finalize Wolkengarten production visual polish v40`
