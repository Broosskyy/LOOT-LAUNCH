extends RefCounted
class_name StylizedTypedAccess

## Typed helpers for V18 stylized generators (Godot 4.7 strict inference).


static func material(mats: Dictionary, key: String, fallback_key: String) -> Material:
	return mats.get(key, mats.get(fallback_key)) as Material


static func opaque_material(
	material_fn: Callable,
	color: Color,
	roughness: float,
	metallic: float,
	emission: Color = Color.BLACK,
	energy: float = 0.0
) -> StandardMaterial3D:
	return material_fn.call(color, roughness, metallic, emission, energy) as StandardMaterial3D


static func transparent_material(transparent_fn: Callable, color: Color) -> StandardMaterial3D:
	return transparent_fn.call(color) as StandardMaterial3D
