extends RefCounted
class_name StylizedMaterialLibrary

## V18 stylized palette — flat colors, high roughness, emission only on magic.


static func apply_palette(
	mats: Dictionary,
	material_fn: Callable,
	transparent_fn: Callable
) -> void:
	mats["grass_main"] = material_fn.call(Color("5fd46a"), 0.88, 0.0)
	mats["grass_light"] = material_fn.call(Color("8fe878"), 0.82, 0.0)
	mats["grass_dark"] = material_fn.call(Color("3faa52"), 0.90, 0.0)
	mats["stone_main"] = material_fn.call(Color("6f6d78"), 0.92, 0.0)
	mats["stone_dark"] = material_fn.call(Color("4a4854"), 0.95, 0.0)
	mats["stone_light"] = material_fn.call(Color("8f8c98"), 0.86, 0.0)
	mats["dirt"] = material_fn.call(Color("7a5d45"), 0.94, 0.0)
	mats["wood"] = material_fn.call(Color("8a5530"), 0.84, 0.0)
	mats["wood_light"] = material_fn.call(Color("b87442"), 0.78, 0.0)
	mats["brass"] = material_fn.call(Color("dca64c"), 0.28, 0.78)
	mats["cannon_dark"] = material_fn.call(Color("2a2838"), 0.32, 0.68)
	mats["crystal_violet"] = material_fn.call(Color("9b5cff"), 0.18, 0.12, Color("7a42e8"), 0.55)
	mats["crystal_blue"] = material_fn.call(Color("5ec8ff"), 0.16, 0.10, Color("35a8f0"), 0.45)
	mats["portal"] = material_fn.call(Color("8f4dff"), 0.22, 0.14, Color("6b2fe8"), 0.62)
	mats["flower_pink"] = material_fn.call(Color("ff8cca"), 0.42, 0.0, Color("e34d9c"), 0.18)
	mats["flower_white"] = material_fn.call(Color("fff5ef"), 0.48, 0.0)
	mats["leaf_green"] = material_fn.call(Color("4fbf62"), 0.80, 0.0)
	mats["coin"] = material_fn.call(Color("ffd44d"), 0.18, 0.82, Color("ffba20"), 0.35)
	mats["cloud_soft"] = material_fn.call(Color("f4f8ff"), 1.0, 0.0)
	# Remap legacy keys used across world systems.
	mats["grass"] = mats["grass_main"]
	mats["grass_mint"] = mats["grass_light"]
	mats["grass_gold"] = mats["grass_light"]
	mats["grass_blue"] = mats["grass_light"]
	mats["grass_lilac"] = mats["grass_light"]
	mats["grass_amber"] = mats["grass_dark"]
	mats["grass_royal"] = mats["grass_main"]
	mats["rock"] = mats["stone_main"]
	mats["rock_mid"] = mats["stone_dark"]
	mats["rock_dark"] = mats["stone_dark"]
	mats["cliff_warm"] = mats["stone_light"]
	mats["edge_moss"] = mats["grass_dark"]
	mats["crystal"] = mats["crystal_violet"]
	mats["violet"] = mats["portal"]
	mats["white"] = mats["stone_light"]
	mats["wood_light"] = mats["wood_light"]
	mats["cannon"] = mats["cannon_dark"]
	mats["cloud"] = transparent_fn.call(Color(0.96, 0.98, 1.0, 0.55))
