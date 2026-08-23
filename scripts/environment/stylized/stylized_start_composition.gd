extends RefCounted
class_name StylizedStartComposition

## Deterministic Wolkengarten start-frame layout (seed-independent).


const PATH_STONES: Array[Dictionary] = [
	{"pos": Vector3(-1.15, 0.12, 1.35), "size": Vector3(0.82, 0.1, 0.72), "rot_y": 8.0},
	{"pos": Vector3(-0.45, 0.12, 0.45), "size": Vector3(0.9, 0.1, 0.78), "rot_y": -12.0},
	{"pos": Vector3(0.2, 0.12, -0.35), "size": Vector3(0.86, 0.1, 0.7), "rot_y": 16.0},
	{"pos": Vector3(0.75, 0.12, -1.15), "size": Vector3(0.92, 0.1, 0.8), "rot_y": -8.0},
	{"pos": Vector3(0.35, 0.12, -2.05), "size": Vector3(0.88, 0.1, 0.74), "rot_y": 22.0},
	{"pos": Vector3(-0.25, 0.12, -2.85), "size": Vector3(0.84, 0.1, 0.7), "rot_y": -18.0},
]

const PAD_POS := Vector3(-2.35, 0.0, 0.35)
const CHEST_POS := Vector3(-3.4, 0.0, 0.6)
const RUIN_POS := Vector3(-5.4, 0.0, 4.0)
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
