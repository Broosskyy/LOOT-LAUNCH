extends RefCounted
class_name StylizedProceduralTextures

## V38 — Cached Godot-generated stylized macro textures (no external files).

const MAX_SIZE := 256
const GRASS_SIZE := Vector2i(128, 128)
const ROCK_SIZE := Vector2i(128, 128)
const WOOD_SIZE := Vector2i(128, 128)

static var _grass_macro: ImageTexture
static var _rock_macro: ImageTexture
static var _wood_grain: ImageTexture
static var _baked := false


static func ensure_baked() -> void:
	if _baked:
		return
	_grass_macro = _make_grass_macro()
	_rock_macro = _make_rock_macro()
	_wood_grain = _make_wood_grain()
	_baked = true


static func grass_macro() -> Texture2D:
	ensure_baked()
	return _grass_macro


static func rock_macro() -> Texture2D:
	ensure_baked()
	return _rock_macro


static func wood_grain() -> Texture2D:
	ensure_baked()
	return _wood_grain


static func validate() -> Array[String]:
	ensure_baked()
	var errors: Array[String] = []
	for name in ["grass", "rock", "wood"]:
		var tex: ImageTexture = _grass_macro if name == "grass" else _rock_macro if name == "rock" else _wood_grain
		if tex == null or tex.get_image() == null:
			errors.append("missing procedural texture: %s" % name)
			continue
		var img: Image = tex.get_image()
		if img.get_width() > MAX_SIZE or img.get_height() > MAX_SIZE:
			errors.append("texture %s exceeds max size" % name)
	return errors


static func memory_estimate_kb() -> int:
	ensure_baked()
	var total := 0
	for tex in [_grass_macro, _rock_macro, _wood_grain]:
		if tex != null and tex.get_image() != null:
			var img: Image = tex.get_image()
			total += img.get_width() * img.get_height() * 4
	return int(total / 1024)


static func _make_grass_macro() -> ImageTexture:
	var img := Image.create(GRASS_SIZE.x, GRASS_SIZE.y, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 38001
	for y in GRASS_SIZE.y:
		for x in GRASS_SIZE.x:
			var nx: float = float(x) / float(GRASS_SIZE.x)
			var ny: float = float(y) / float(GRASS_SIZE.y)
			var blob: float = sin(nx * 9.2 + ny * 6.8) * 0.5 + sin(nx * 4.1 - ny * 5.3) * 0.5
			blob = blob * 0.5 + 0.5
			var speck: float = rng.randf_range(0.88, 1.0)
			var v: float = clampf(blob * speck, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v * 0.98, v * 0.92, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _make_rock_macro() -> ImageTexture:
	var img := Image.create(ROCK_SIZE.x, ROCK_SIZE.y, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 38002
	for y in ROCK_SIZE.y:
		for x in ROCK_SIZE.x:
			var nx: float = float(x) / float(ROCK_SIZE.x)
			var ny: float = float(y) / float(ROCK_SIZE.y)
			var strata: float = sin(ny * 14.0 + sin(nx * 8.0) * 0.6) * 0.5 + 0.5
			var speckle: float = rng.randf_range(0.82, 1.0)
			var v: float = clampf(strata * speckle, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v * 1.02, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _make_wood_grain() -> ImageTexture:
	var img := Image.create(WOOD_SIZE.x, WOOD_SIZE.y, false, Image.FORMAT_RGBA8)
	for y in WOOD_SIZE.y:
		for x in WOOD_SIZE.x:
			var ny: float = float(y) / float(WOOD_SIZE.y)
			var band: float = sin(ny * 28.0 + sin(float(x) * 0.18) * 2.4) * 0.5 + 0.5
			band = lerpf(0.72, 1.0, band)
			img.set_pixel(x, y, Color(band, band * 0.96, band * 0.88, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
