extends RefCounted
class_name V41RuinKit

## V41 — Modular low-poly ruins for benchmark composition.

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")
const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")

enum RuinKind {
	PILLAR_SHORT,
	PILLAR_BROKEN,
	WALL_SHORT,
	WALL_BROKEN,
	ARCH_SMALL,
	RUBBLE_A,
	RUBBLE_B,
	STONE_BLOCK_A,
	STONE_BLOCK_B,
}

static func kind_name(kind: int) -> String:
	var names := [
		"RuinPillar_Short", "RuinPillar_Broken", "RuinWall_Short", "RuinWall_Broken",
		"RuinArch_Small", "RubbleCluster_A", "RubbleCluster_B", "StoneBlock_A", "StoneBlock_B",
	]
	return names[clampi(kind, 0, names.size() - 1)]


static func all_kinds() -> Array:
	return [
		RuinKind.PILLAR_SHORT, RuinKind.PILLAR_BROKEN, RuinKind.WALL_SHORT, RuinKind.WALL_BROKEN,
		RuinKind.ARCH_SMALL, RuinKind.RUBBLE_A, RuinKind.RUBBLE_B, RuinKind.STONE_BLOCK_A, RuinKind.STONE_BLOCK_B,
	]


static func build(kind: int, seed: int) -> ArrayMesh:
	match kind:
		RuinKind.PILLAR_SHORT:
			return Toolkit.tapered_pillar(Toolkit.PillarKind.SHORT_COLUMN, 0.42, 0.34, 1.65, 7, seed, false, 1)
		RuinKind.PILLAR_BROKEN:
			return Toolkit.tapered_pillar(Toolkit.PillarKind.BROKEN_PILLAR, 0.46, 0.38, 2.1, 7, seed, true, 1)
		RuinKind.WALL_SHORT:
			return Toolkit.beveled_box(Vector3(1.8, 1.1, 0.55), 0.07, seed, 0.84, 0.04, 0.06, 0.05, 1, 1)
		RuinKind.WALL_BROKEN:
			return Toolkit.beveled_box(Vector3(1.4, 0.72, 0.48), 0.06, seed + 3, 0.78, 0.0, 0.08, 0.12, 1, 1)
		RuinKind.ARCH_SMALL:
			return Toolkit.arch(1.35, 1.05, 0.22, 7, seed, false, 0.06, 1)
		RuinKind.RUBBLE_A, RuinKind.RUBBLE_B:
			return _build_rubble_cluster(seed + kind)
		RuinKind.STONE_BLOCK_A:
			return Toolkit.beveled_box(Vector3(0.72, 0.58, 0.68), 0.05, seed, 0.8, 0.02, 0.04, 0.08, 1, 1)
		_:
			return Toolkit.beveled_box(Vector3(0.85, 0.42, 0.74), 0.05, seed + 11, 0.76, 0.0, 0.06, 0.1, 1, 1)


static func _build_rubble_cluster(seed: int) -> ArrayMesh:
	return Toolkit.beveled_box(Vector3(0.92, 0.38, 0.78), 0.06, seed, 0.76, 0.0, 0.06, 0.14, 1, 1)
