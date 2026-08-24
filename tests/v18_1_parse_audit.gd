extends SceneTree

## Loads every V18 stylized script to surface parser / strict-inference errors.


const SCRIPT_PATHS: Array[String] = [
	"res://scripts/environment/stylized/stylized_typed_access.gd",
	"res://scripts/environment/stylized/stylized_material_library.gd",
	"res://scripts/environment/stylized/stylized_shader_library.gd",
	"res://scripts/environment/stylized/stylized_lighting.gd",
	"res://scripts/environment/stylized/stylized_island_generator.gd",
	"res://scripts/environment/stylized/stylized_vegetation_generator.gd",
	"res://scripts/environment/stylized/stylized_vegetation_density.gd",
	"res://scripts/environment/stylized/stylized_ruin_generator.gd",
	"res://scripts/environment/stylized/stylized_crystal_generator.gd",
	"res://scripts/environment/stylized/stylized_hero_models.gd",
	"res://scripts/environment/stylized/stylized_mesh_library.gd",
	"res://scripts/environment/stylized/stylized_ground_ruins_kit.gd",
	"res://scripts/environment/stylized/stylized_cloud_generator.gd",
	"res://scripts/environment/stylized/stylized_mesh_validator.gd",
	"res://scripts/environment/stylized/stylized_portal_generator.gd",
	"res://scripts/environment/stylized/stylized_world_decorator.gd",
	"res://scripts/environment/stylized/stylized_world_composition.gd",
	"res://scripts/gameplay/island_hopping_world.gd",
	"res://tests/stylized_world_v18_smoke.gd",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in SCRIPT_PATHS:
		var script: GDScript = load(path)
		assert(script != null, "Failed to load script: " + path)
	print("V18.1A parse audit passed: scripts=", SCRIPT_PATHS.size())
	quit(0)
