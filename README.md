# LOOT LAUNCH v16 — Solid Island & Asset Pipeline Recovery

LOOT LAUNCH v16 is a portrait 3D action-platformer vertical slice:

**explore → jump → enter cannon → charge/aim → steer through safe or risky loot lanes → land or miss → open chest → continue → receive an authoritative graded result**

Open `project.godot` with Godot **4.7.x**, press Play and choose **LOKALES TRAINING STARTEN**. This mode is clearly labelled and is never presented as live multiplayer.

## v16 solid-world recovery

- Floating-island cliff meshes are now fully closed with a generated rocky tip; the former open underside cannot reveal the sky through the island.
- Every fixed world material explicitly uses the opaque depth pipeline. Stone, grass, moss and brass no longer depend on renderer defaults.
- Core island materials are two-sided as an Android Compatibility safety net while maintaining a genuinely closed mesh.
- Plateau, moss lip and cliff surfaces include UV coordinates and subtle vertex-colour variation in preparation for authored textures.
- Original six-asset production reference at `art/concept/loot-launch-asset-kit-v16.png`.
- Documented GLB replacement slots and mobile budgets in `docs/AI_3D_ASSET_PIPELINE.md`.
- `tests/island_solidity_v16.gd` verifies opaque materials and the closed 378-vertex cliff shell.

## v15 multi-expedition gameplay

- Kristallschmiede is a complete second six-island expedition, not a locked menu placeholder.
- Its steeper zigzag route has five independently validated natural cannon flights, a cooler crystal-forge palette and altered sky lighting.
- Six unique landmarks: calibration observatory, resonance forge, mining rig, prism array, mag-rail station and crown vault.
- Distinct island names and contracts make the route readable as a separate world.
- Preflight directly selects world, Lootling and cannon; the selected world persists locally and is passed to the authoritative launch RPC.
- Per-world mastery tracks completions without granting client-authored currency.
- The mission screen now combines daily rewards with 1/3/10-run expedition milestones and rank progression.
- New Supabase migration `202608200006_v15_multi_expedition.sql` authorizes only known level configurations.
- `tests/multi_expedition_v15.gd` completes all five crystal flights, all contracts/chests, server submission and mastery advancement.

## v14 visible design and object overhaul

- Six distinct biome palettes with hand-built moss lips, faceted edge rocks, flowers, lanterns and route paths.
- Reauthored cannon silhouette: layered carriage, wheels, crystal receiver, ornate muzzle and cannon-specific details.
- Reauthored treasure chests with rounded lids, brass straps, lock and aether core.
- Layered portal ruins, marked mushroom caps and richer animated airships.
- New original crystal-and-brass nine-patch gameplay HUD instead of the former flat debug panel.
- Small scenery uses distance culling while large island silhouettes remain visible.
- `tests/production_artpass_v14.gd` protects the new art hierarchy and HUD integration.

## v13 Wolkengarten art, route and audio pass

- Six larger playable islands and five natural cannon flights replace the former four-island route.
- Visible stacked cylinders were replaced by generated irregular ArrayMesh plateaus, faceted cliff walls, pointed undersides and offset rock formations. Simple cylinder collision remains hidden and mobile-friendly.
- Every island has a distinct readable landmark: windmill cliff, mushroom garden, crystal workshop, portal ruins, airship harbor and treasure fortress.
- Animated sky couriers, expanded cloud depth, three waterfalls and additional distant island silhouettes make the route feel inhabited.
- Thirteen island-contract targets and five chests create a longer expedition with named objectives and a visible six-node route tracker.
- Preflight selection now exposes all four Lootlings and all three cannons as direct touch buttons. No arrow carousel is required.
- Procedural audio was rebuilt as layered launch, impact, reward, chest, failure and ambient-music synthesis rather than single-tone beeps.
- The server-authoritative expedition budget is 1,500 coins and 10 crystals, enough to confirm every visible authored pickup without a client/server display mismatch.

## v12 gameplay, clarity and 3D foundation

- Preflight screen before every normal route compares all four Lootlings and three cannons, their roles, abilities and power/control ratings.
- The island home button, collection and in-game HUD always show the equipped Lootling and cannon. Equipment is intentionally locked after the server-authoritative session starts.
- Visible island-contract targets gate each destination chest until its local contract is complete.
- Five daily missions instead of three: route, pickups, island targets, all three chests and building upgrade.
- Three server-seeded risk-lane arrangements keep repeat runs less predictable without changing the disclosed safe/risk reward totals.
- Every hop adds an optional animated Aether booster and moving risk obstacle.
- True 360-degree procedural sky removes the grey void exposed by free camera rotation.
- Camera collision keeps a larger minimum distance, distant decoration was moved away from playable islands and striped island undersides were softened.
- Shorter shadow distance and bounded effects reduce mobile GPU work.

## v11 aim and perspective foundation

- High over-cannon camera at a wider 71° portrait field of view; muzzle, initial arc and destination remain readable together.
- Ray-based collision avoidance pulls the camera in front of solid scenery instead of clipping through it.
- Jump conduits, tall trees and destination arches were moved out of the central cannon sight corridor while remaining explorable.
- Intuitive shooter mapping: swipe right turns right; swipe upward raises the cannon.
- Separate responsive aim sensitivity for Standard, Thunder and Portal cannons.
- Only eight trajectory dots reveal the initial flight phase.
- The landing marker simulates the same origin, speed, pitch, yaw and gravity as the real shot. Green means a safe target-island contact; red warns of a miss.

All v10 graphics, balance, loadout, performance and result improvements remain included.

## v10 foundation

### Graphics and feedback

- New original 1024×1536 premium sky backdrop at `art/generated/sky_route_backdrop_v10.png` with layered clouds and distant floating settlements.
- Atmospheric fog on High/Ultra, quality-dependent shadows/glow, sunrise disc, animated aether beacons and waterfalls.
- Four differently coloured Lootling themes with character-specific accents.
- Pooled flight trail and reward/hit sparks, camera banking during steering, improved landing feedback and new action sounds/haptics.
- Animated combo punch, live coin/crystal tally, explicit flight-control hint and graded result screen.

### Earlier balance foundation

- Safe and risk lanes remain distinct. The six-island expedition totals 300 safe airborne coins, 250 optional risk coins and five risk crystals before island exploration and chests.
- Landing accuracy is recorded across all five hops. Results receive rank S/A/B/C based on precision and retries.
- Standard, Thunder and Portal cannons have different speed, charge and aim responsiveness while remaining landable with the same understandable gesture.

### Real loadouts

- **Bouncer:** stronger collision rebound.
- **Magneto:** larger pickup radius in air and on islands.
- **Blasto:** first strong world collision emits a validated destructible event and stronger impact burst.
- **Blink:** active ability teleports forward.
- **Portal cannon:** two weaker tactical impulses instead of one.
- **Thunder cannon:** fastest charge and strongest launch, with more sensitive aim.

### Mobile performance

- No trail or burst nodes are created/freed during flight; bounded pools are allocated once per route.
- Four quality tiers: **Akku**, **Balance**, **Hoch**, **Ultra**.
- Battery mode: 30 FPS, 72% 3D render scale, no realtime shadows, fewer procedural clouds, 12 trail and 32 spark nodes.
- High/Ultra: 60 FPS, full render scale, 2× MSAA, controlled fog and bounded detail pools.
- Realtime lights remain restricted; Ultra adds only small beacon lights.

## Controls

1. Drag anywhere inside the left analog area to move at variable speed.
2. Swipe the open right/centre view to orbit the camera.
3. Press **SPRUNG** to clear obstacles.
4. Near a cannon, press **IN KANONE STEIGEN**.
5. Touch the free sky, swipe in the desired direction and hold to charge. Swipe up to raise the barrel and right to turn right. A short tap cancels; valid release fires once.
6. Use the analog stick during flight to steer sideways and subtly lift/dive.
7. Use the contextual special button. The Portal cannon shows two charges.
8. A miss enters a real failure state; retry restores the latest checkpoint without consuming more energy.

Keyboard fallback: arrow keys. Mouse uses the same pointer state machine as touch.

## Supabase

Copy `config/backend.example.json` to ignored `config/backend.json` and enter only the project URL, publishable key and Functions URL. Apply all migrations through `202608200006_v15_multi_expedition.sql` and deploy the Edge Functions. Never place a service-role key in the game.

The world only records event evidence. Wallets, energy, trophies, upgrades and final rewards remain backend-authoritative and idempotent.

## Export

With matching Godot 4.7 export templates installed:

- Web: `Web Test` → `build/web/index.html`
- Android APK: `Android APK` → `build/android/loot-launch.apk`
- Android AAB: `Android AAB` → `build/android/loot-launch.aab`
- iOS: `iOS Xcode` → `build/ios/loot-launch.zip` on macOS

## Honest verification status

Godot 4.7.1 parser/runtime, closed opaque island shells, direct loadout selection, six irregular islands, thirteen contract targets, chest locking/unlocking, 360 sky, moving features, target prediction, camera obstruction solver, all five natural hops, every cannon, failure/retry, daily missions, authoritative local rewards, persistence and replay protection are executable tests in this project. Android framebuffer/touch hardware, subjective audio-device quality and live two-account Supabase require an external device/project and are not falsely claimed here.
