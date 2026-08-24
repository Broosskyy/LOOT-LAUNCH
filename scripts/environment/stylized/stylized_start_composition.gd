extends RefCounted
class_name StylizedStartComposition

## Deterministic Wolkengarten start-frame layout (seed-independent).


const PATH_STONES: Array[Dictionary] = [
	{"pos": Vector3(-0.75, 0.04, 1.35), "rot_y": 8.0},
	{"pos": Vector3(-0.15, 0.04, 0.48), "rot_y": -10.0},
	{"pos": Vector3(0.35, 0.04, -0.35), "rot_y": 14.0},
	{"pos": Vector3(0.72, 0.04, -1.18), "rot_y": -4.0},
	{"pos": Vector3(0.48, 0.04, -2.05), "rot_y": 18.0},
	{"pos": Vector3(0.05, 0.04, -2.82), "rot_y": -8.0},
]

const EDGE_STONES: Array[Vector3] = [
	Vector3(-4.2, 0.0, 2.8),
	Vector3(3.8, 0.0, 2.2),
	Vector3(-1.8, 0.0, -3.9),
]

const PAD_POS := Vector3(-2.2, 0.0, 0.35)
const CHEST_POS := Vector3(-2.9, 0.0, 0.55)
const RUIN_POS := Vector3(-5.2, 0.0, 3.8)
const CORNER_RUIN_POS := Vector3(-5.2, 0.0, 3.8)
const PILLAR_POS := Vector3(5.6, 0.0, 1.4)
const PLINTH_POS := Vector3(-1.2, 0.0, -4.2)
const SIGN_POS := Vector3(4.2, 0.0, 3.2)
const TREE_POS := Vector3(-6.2, 0.0, 1.2)
const CRYSTAL_POS := Vector3(-3.8, 0.0, -1.8)
const FLOWER_CLUSTERS: Array[Vector3] = [
	Vector3(-4.8, 0.0, 3.4),
	Vector3(-3.2, 0.0, 4.6),
	Vector3(2.8, 0.0, 3.8),
]
const GRASS_CLUSTERS: Array[Vector3] = [
	Vector3(-2.0, 0.0, 2.4),
	Vector3(1.4, 0.0, 1.8),
	Vector3(3.2, 0.0, 0.4),
	Vector3(-0.8, 0.0, -1.2),
]
