# Architecture

- `scripts/ui/main.gd` — portrait auth/meta shell, gameplay HUD, tally, combo and graded results.
- `scripts/ui/virtual_joystick.gd` — floating single-pointer analog joystick.
- `scripts/gameplay/island_hopping_world.gd` — active v12 Node3D route, seeded risk variants, island contracts, boosters/moving obstacles, 360 sky, camera collision avoidance, deterministic landing prediction, pooled effects and event capture.
- `scripts/gameplay/launch_world.gd` — preserved legacy board used only for regression coverage.
- `scripts/core/game_state.gd` — persistent state and replaceable backend boundary.
- `scripts/backend/local_development_backend.gd` — labelled development/training adapter.
- `scripts/backend/supabase_backend.gd` — Supabase Auth/Edge Function HTTPS adapter.
- `scripts/audio/audio_manager.gd` — generated audio, haptics, FPS/render scale/MSAA quality application.
- `supabase/migrations/202608200003_v10_balance_and_loadouts.sql` — authoritative `sky_route_v3` session definition.
- `tests/performance_balance_v10.gd` — economy, resource, quality and pool invariants.
- `tests/loadout_ballistics_v10.gd` — natural Standard/Thunder/Portal landing matrix.
- `tests/result_ui_v10.gd` — route grade/reward screen.
- `tests/aim_camera_occlusion_v11.gd` — sight-corridor placement, intuitive gesture direction, target prediction and physical camera obstruction test.
- `tests/loadout_objectives_v12.gd` — preflight loadout switching, 360 sky, seven objectives, chest lock/unlock and optional route-feature coverage.
- `supabase/migrations/202608200004_v12_route_contracts.sql` — authoritative `sky_route_v4` seed/config including booster evidence and island contract counts.

Gameplay never writes wallet, energy, trophies or upgrades directly. The world emits ordered evidence; `GameState` submits it to the configured backend. Android, iOS and Web share the same code and backend interface.
