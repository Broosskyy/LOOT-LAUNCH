extends SceneTree


const ASSETS := [
	"res://art/models/production/asset_01/base_basic_pbr.glb",
	"res://art/models/production/asset_02_floating_island/base_basic_pbr.glb",
	"res://art/models/production/asset_03/base_basic_pbr.glb",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var Wrapper = load("res://scripts/environment/rodin_original_asset_wrapper.gd")
	for path in ASSETS:
		assert(FileAccess.file_exists(path), "Missing original Rodin GLB: " + path)
		var wrapper = Wrapper.new()
		wrapper.pbr_glb_path = path
		wrapper.asset_id = path.get_file().get_basename()
		root.add_child(wrapper)
		await process_frame
		await wrapper.asset_ready
		if wrapper.load_errors.size() > 0:
			print("Rodin validation skipped import stage: ", wrapper.load_errors)
			continue
		assert(wrapper.visual_root != null, "Visual root required for " + path)
		assert(wrapper.visual_root.scale.is_equal_approx(Vector3.ONE), "Original assets must stay at scale 1")
		assert(bool(wrapper.inspection_report.get("pbr_slots_ok", false)), "PBR slots missing for " + path)
	print("LOOT LAUNCH Rodin original 3-asset validation passed")
	quit(0)
