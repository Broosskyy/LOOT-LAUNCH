# Archived scenes — Phase 17B.1 import hotfix

These scenes reference Rodin originals, deprecated broken LODs, or multi-asset previews that were removed from active `res://` import to speed up Godot startup.

They are kept for historical reference only. Opening them in Godot will show missing-resource errors until source assets are restored from:

`../LOOT_LAUNCH_SOURCE_ASSETS/` (see `art/models/SOURCE_ARCHIVE_LOCATION.md`)

## Archived files

| Scene | Reason |
|-------|--------|
| `rodin_original_assets_preview_v17a.tscn` | Loads three 120k Rodin originals |
| `glb_island_preview_v17a.tscn` | Loads deprecated broken external LOD island |
| `floating_island_base01.tscn` | Phase 17A broken LOD wrapper |
| `production_asset_01/02/03.tscn` | Rodin original single-asset wrappers |
| `production_tall_prop.tscn` | Asset 1 production preview (not needed for island 0 gameplay) |
| `production_compact_prop.tscn` | Asset 3 production preview |

## Active preview (production only)

`res://scenes/preview/production_assets_preview_v17b.tscn` — floating island production LODs only.

## Active gameplay production scene

`res://scenes/environment/production_floating_island.tscn`
