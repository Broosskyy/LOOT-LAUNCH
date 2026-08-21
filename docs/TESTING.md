# Testing

## v15 multi-expedition regression

Run `tests/multi_expedition_v15.gd`. It selects Kristallschmiede through the same saved state used by the UI, obtains a server-shaped local session, constructs the second route, naturally lands all five flights, clears all contracts and chests, submits the result once and verifies per-world mastery. Then run the v14 art and legacy regressions below.

## v14 production-art regression

Run `tests/production_artpass_v14.gd` first. It verifies the imported crystal HUD, nine-patch integration, expanded biome palette, layered cannon and chest assemblies, flowers and aether lanterns. Then run the v13 route regression and the ballistics, camera, UI, balance and backend checks below.

## v13 Wolkengarten regression

Run `tests/wolkengarten_artpass_v13.gd` first. It verifies six irregular island meshes, six distinct landmarks, two animated airships, direct touch selection for every Lootling/cannon and all thirteen contract targets. Then run `tests/platform_route_v9.gd`, `tests/all_hops_ballistics_v9.gd`, `tests/loadout_objectives_v12.gd`, `tests/performance_balance_v10.gd`, `tests/aim_camera_occlusion_v11.gd` and the legacy backend/UI suite.

The current automated environment uses Godot's headless renderer. It validates scene construction, input state, ballistics, collision, UI state, economy evidence and persistence, but not subjective Android framebuffer quality.

## Automated checks

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/aim_camera_occlusion_v11.gd
godot --headless --path . --script res://tests/loadout_objectives_v12.gd
godot --headless --path . --script res://tests/performance_balance_v10.gd
godot --headless --path . --script res://tests/loadout_ballistics_v10.gd
godot --headless --path . --script res://tests/result_ui_v10.gd
godot --headless --path . --script res://tests/joystick_v9.gd
godot --headless --path . --script res://tests/platform_route_v9.gd
godot --headless --path . --script res://tests/island_hopping_ballistics.gd
godot --headless --path . --script res://tests/all_hops_ballistics_v9.gd
godot --headless --path . --script res://tests/main_v7_ui_smoke.gd
godot --headless --path . --script res://tests/camera_controls_v8.gd
godot --headless --path . --script res://tests/island_hopping_acceptance.gd
godot --headless --path . --script res://tests/local_backend_smoke.gd
godot --headless --path . --script res://tests/launch_world_smoke.gd
godot --headless --path . --script res://tests/launch_world_gesture_matrix.gd
godot --headless --path . --script res://tests/vertical_slice_acceptance.gd
```

On read-only CI hosts, set writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME` and `XDG_CACHE_HOME` paths.

## Manual mobile acceptance

1. Confirm portrait safe areas and all four quality labels.
2. Compare Akku and Ultra: Akku must render fewer clouds/no shadows; UI stays native resolution.
3. Open preflight, cycle all four Lootlings and all three cannons, then confirm the HUD shows the same locked route loadout.
4. Walk, orbit and jump over every side-lane glowing conduit; verify none blocks the cannon sight line.
5. In every cannon, confirm right/up swipes move right/up and the green/red landing marker reacts correctly.
6. Rotate 360 degrees on every island; no grey background edge may appear and the camera must not zoom into the Lootling.
7. Complete 2 + 2 + 3 island targets and verify each chest stays locked until its contract is done.
8. Fly the central safe line, then deliberately steer through risk halos, boosters and moving bars.
9. Confirm Magneto pulls from farther away, Blink teleports and Portal provides exactly two charges.
10. Trigger a Blasto collision and observe the larger first-impact effect.
11. Miss/fall and retry; verify no unexpected island landing and no second energy charge.
12. Complete all three hops and compare visible tally, result grade and credited wallet.
13. Restart and verify persistence; resubmission must not duplicate rewards.

## Environment boundary

Headless tests genuinely run parser, physics, UI wiring, economy and persistence. They do not substitute for an Android framebuffer, GPU profiling, safe-area inspection or live Supabase two-user acceptance.
