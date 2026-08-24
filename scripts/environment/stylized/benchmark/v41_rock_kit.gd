extends RefCounted
class_name V41RockKit

## V41 — Faceted low-poly rocks (not scaled primitives).

const Common = preload("res://scripts/environment/stylized/mesh/stylized_mesh_common.gd")
const Stones = preload("res://scripts/environment/stylized/mesh/stylized_stone_builder.gd")
const Toolkit = preload("res://scripts/environment/stylized/mesh/stylized_mesh_toolkit.gd")

enum RockKind { SMALL, MEDIUM, LARGE, RUBBLE, LANDMARK }


static func build(kind: int, seed: int) -> ArrayMesh:
	match kind:
		RockKind.SMALL:
			return Toolkit.irregular_stone(Stones.StoneKind.FLAT_STONE, 0.28, 0.32, 7, 0.12, 0.18, 0.62, seed, 1)
		RockKind.MEDIUM:
			return Toolkit.irregular_stone(Stones.StoneKind.TALL_ROCK, 0.42, 0.68, 8, 0.14, 0.28, 0.35, seed, 1)
		RockKind.LARGE:
			return Toolkit.irregular_stone(Stones.StoneKind.CLIFF_CHUNK, 0.62, 1.05, 9, 0.1, 0.22, 0.2, seed, 1)
		RockKind.RUBBLE:
			return Toolkit.irregular_stone(Stones.StoneKind.RUBBLE, 0.22, 0.24, 6, 0.16, 0.1, 0.5, seed, 1)
		_:
			return Toolkit.irregular_stone(Stones.StoneKind.TALL_ROCK, 0.78, 1.35, 10, 0.08, 0.32, 0.15, seed, 1)
