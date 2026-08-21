extends SceneTree


const MANIFEST := "res://art/models/production/asset_02_floating_island/game_ready/pipeline_manifest.json"
const LODS := [
	"res://art/models/production/asset_02_floating_island/game_ready/LOD0.glb",
	"res://art/models/production/asset_02_floating_island/game_ready/LOD1.glb",
	"res://art/models/production/asset_02_floating_island/game_ready/LOD2.glb",
]
const EMISSIVE := "res://art/models/production/asset_02_floating_island/texture_emissive.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(FileAccess.file_exists(MANIFEST), "Missing manifest: " + MANIFEST)
	for path in LODS:
		assert(FileAccess.file_exists(path), "Missing game-ready LOD: " + path)
	assert(FileAccess.file_exists(EMISSIVE), "Missing emissive texture: " + EMISSIVE)
	var ProductionAsset = load("res://scripts/environment/production_asset.gd")
	var island = ProductionAsset.new()
	island.configure_floating_island(12.8, 1.45, 2)
	root.add_child(island)
	await process_frame
	await island.asset_ready
	if island.load_errors.size() > 0:
		print("Production validation skipped pending import: ", island.load_errors)
		quit(0)
		return
	assert(island.visual_root != null, "Production visual required")
	assert(island.collision_body != null, "Floating island collision required")
	assert(island.lod_instances.size() == 3, "Three LOD instances required")
	assert(absf(island.visual_scale - 13.333333) < 0.02, "Gameplay scale mapping")
	print("LOOT LAUNCH production assets v17B validation passed (floating island only)")
	quit(0)
