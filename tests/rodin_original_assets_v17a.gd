extends SceneTree

## Phase 17A originals are archived outside res:// after Phase 17B.1 import hotfix.
## Git history and ../LOOT_LAUNCH_SOURCE_ASSETS/ retain the Rodin source exports.


const ARCHIVE_ROOT := "../LOOT_LAUNCH_SOURCE_ASSETS/rodin/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print(
		"Rodin original validation archived (Phase 17B.1). Sources live at %s — not imported under res://."
		% ARCHIVE_ROOT
	)
	quit(0)
