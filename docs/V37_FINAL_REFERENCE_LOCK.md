# V37 — Final Reference Lock (Wolkengarten)

Canonical Godot-native visual baseline after V33–V37. The supplied Wolkengarten reference image is the primary visual authority. Future passes must not casually undo these values.

## Camera (SSOT: `stylized_world_composition.gd`)

| Parameter | V37 value |
|---|---|
| FOV | 54.0° |
| Pitch | 16.5° |
| Look height | 0.60 |
| Look ahead | 5.85 |
| Follow distance | 10.65 |
| Follow height | 2.78 |
| Route blend | 0.50 |

Portrait spawn targets (1080×1920):

- Player: ~48–52% x, ~70–82% y
- Cannon: ~68–74% x, ~50–56% y
- Chest/pad: left foreground (~18–30% x)
- Primary destination + portal: upper-mid (~38–55% x, ~15–22% y)
- Hero landmark: upper-right (~74–82% x, ~10–16% y)

V37 reduces top-down feel: lower follow height, lower pitch, wider FOV, longer look-ahead.

## Composition hierarchy

1. **Foreground:** start island grass + cliff edge, player, cannon, chest, pad, path
2. **Midground:** gold ring arc, first destination, portal monument, vista 20/33
3. **Background:** hero landmark island 22, distant vista 21/34/35, cloud bank
4. **Sky:** procedural cyan gradient with intentional negative space around landmark

## Start-island props (`stylized_start_composition.gd`)

- Cannon: `CANNON_OFFSET (1.32, 0.92, -2.22)` + scale `1.06`
- Chest: `(-2.65, 0, 0.72)`
- Pad: `(-2.05, 0, 0.42)`
- Left tree anchor at `(-6.4, 0, 1.0)` frames player without blocking cannon

## Island hierarchy

- Route island 1 nudged to `(5.0, 2.85, -13.8)` for clearer midground read
- Hero landmark 22 raised to `(24.0, 8.8, -39.5)` radius `8.4`
- Micro islands 34/35 pushed to edges — silhouette support only

## Vegetation

V28 density system unchanged. V37 rules:

- No vegetation directly behind player/cannon
- Path corridor stays readable
- Edge trees frame composition; midground portal gets tree cluster

## Architecture

V35 generators unchanged. Portal monument scale `1.22` on destination island (was `1.35`).

## Rendering (V36 SSOT + V37 micro-tune)

- Exposure Q2: `0.82`
- Single sun, tiered fog, cloud depth layers — see `V36_ENVIRONMENT_RENDERING_STANDARD.md`

## Cloud placement

V36 cloud bank + mid clusters. V37: slower drift, smaller amplitude — must not cover destination, landmark, or ring arc.

## VFX restraint (V29)

- Ring bob amplitude reduced
- Wind strength Q2: `0.042`
- Portal/crystal motion preserved but subtler at spawn frame

## Performance rules

- One directional light
- Cloud puff cap 96
- No per-frame screenshot-only worlds
- All final QC at 1080×1920 portrait, GL Compatibility

## Do not change without explicit visual pass

- V37 camera constants
- Route island centers (gameplay ballistics)
- Ring arc hop-0 trajectory truth
- AimPivot / cannon collision hierarchy
- Material shader architecture

## Reference image role

`art/concept/loot-launch-key-art.png` defines target framing, hierarchy, and palette intent. V37 converges runtime gameplay toward that image using procedural Godot-native systems only.

## Recommended next work (not V38)

- Gameplay/combat integration on mega islands
- UI polish (separate pass)
- Optional selected external hero assets after manual art review
- Additional biomes using same V33–V37 stack
