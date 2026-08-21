# LOOT LAUNCH v16 — Functionality Audit

## Executed with Godot 4.7.1

| Area | Result |
| --- | --- |
| Project import/GDScript parser | Passed |
| Direct preflight loadout UI | Passed; four named Lootling buttons, three named cannon buttons and explicit start action |
| Wolkengarten route | Passed; six larger playable islands and five destination chests |
| Island geometry | Passed structurally; closed generated ArrayMesh plateaus/cliffs replace visible stacked cylinders and open undersides |
| Solid material pipeline | Passed; grass, stone, moss, metal and characters explicitly disable transparency and write opaque depth |
| Production asset preparation | Six-asset original concept sheet, GLB slots, UV foundation and mobile budgets included |
| Island identity | Passed; six biome palettes, moss/rock rims, six named landmarks, flowers, lanterns, paths and animated airships |
| Cannon/chest/portal art | Passed structurally; layered assemblies replace their former primitive silhouettes |
| Gameplay HUD | Passed; original crystal-and-brass nine-patch frame imported and integrated without corner stretching |
| World selection | Passed; Wolkengarten and Kristallschmiede are direct preflight choices and persist locally |
| Kristallschmiede route | Passed; six playable islands, five steeper natural flights and five contract-gated chests |
| Kristallschmiede identity | Passed structurally; separate palette, sky lighting, landmarks, names and task copy |
| Expedition mastery | Passed; authoritative completion increments only the submitted world once |
| Multi-world launch security | Three-argument RPC restricts input to two known server level configurations; legacy RPC remains compatible |
| Island contracts | Passed; thirteen targets split 2/3/2/3/3 |
| Chest contract gate | Passed; locked before target completion, opens afterward |
| Seeded route variants | Three safe/risk arrangements with identical disclosed reward totals |
| Optional flight features | Five boosters and five moving risk obstacles |
| Route tracker | Passed; six HUD nodes update with checkpoint progress |
| Cannon sight corridor | Passed; central aim line remains clear and camera collision solver is active |
| Aim direction and touch state | Passed; right/up gestures, deadzone, single release and UI exclusion retained |
| Flight preview | Passed; eight initial dots and deterministic target-plane marker |
| Natural ballistics | Passed for all five hops; measured 1.2–1.8 seconds per hop in headless regression |
| All three cannons | Passed; distinct charge/speed/control values remain naturally landable |
| Analog movement, orbit camera and jump | Passed |
| Miss/fall and checkpoint retry | Passed |
| Audio architecture | Layered procedural music and multi-layer SFX compiled and ran without external licenses |
| Pooled effects | Passed; bounded trail/spark pools, no flight-time node allocation |
| Battery/Ultra quality bounds | Passed; 12/32 and 40/88 trail/spark pools |
| Scenic range culling | Passed; small meshes fade beyond 118 m while island silhouettes remain available |
| Authoritative local rewards | Passed; 1,500 coin / 10 crystal session ceilings and 160-event validation |
| Duplicate result protection | Passed |
| Existing backend/vertical-slice tests | Preserved and re-executed |
| Android hardware/framebuffer | Not available in this environment |
| Live two-account Supabase | Requires deployment credentials |

## Known limitations

- The world is now a substantially denser and fully closed procedural production-art pass, but characters and secondary architecture are still generated low-poly assemblies rather than the finished authored GLB pack shown in the v16 reference sheet.
- Runtime screenshots cannot be captured with the available headless dummy renderer; visual output still needs final Android-device review.
- Synthesized audio is more varied than v12 but production release should use professionally recorded or licensed sound design.
- Wolkengarten remains the most detailed environment; Kristallschmiede is fully playable and visually distinct but still reuses the shared procedural prop toolkit. Additional worlds are not marked complete.
