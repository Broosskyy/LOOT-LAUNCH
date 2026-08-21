# Source asset archive (outside Godot project)

Phase **17B.1** moved heavy Rodin originals, shaded comparison GLBs, deprecated broken LODs, and non-gameplay production copies **out of `res://`** so Godot only imports assets required for active gameplay.

## Location

```
c:\Users\manue\Downloads\LOOT_LAUNCH_SOURCE_ASSETS\
```

Relative to the Godot project root:

```
../LOOT_LAUNCH_SOURCE_ASSETS/
```

**This folder is NOT part of the Git repository.** All files were committed under `res://` on branch `main` at commit `1ddd6c3` (`feat: Phase 17B UV-safe production asset pipeline`) before archival.

## Layout

```
LOOT_LAUNCH_SOURCE_ASSETS/
├── rodin/
│   ├── asset_01/              # original PBR + shaded + emissive + game_ready LODs
│   ├── floating_island/       # original PBR + shaded + rodin_metadata.json
│   └── asset_03/              # original PBR + shaded + emissive + game_ready LODs
└── deprecated/
    └── broken_external_lods/
        └── floating_island_base01/   # UV-broken external decimation (Phase 17A)
```

## Restore into project (when needed)

Copy the desired subfolder back under `res://art/models/production/` (or `_deprecated/`) and re-open Godot to re-import. Do **not** delete this archive when cleaning the Godot `.godot/` cache.

See also: `docs/PHASE_17B1_GODOT_IMPORT_HOTFIX.md`
