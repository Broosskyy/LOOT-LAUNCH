extends Node

## Small procedural audio palette for the mobile prototype. It uses several
## short layers instead of the old single sine beep and stays license-safe.

const RATE := 22050.0
var music_player: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var music_time := 0.0


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = 0.7
	music_player.stream = generator
	music_player.play()
	music_playback = music_player.get_stream_playback()


func _process(_delta: float) -> void:
	if music_playback == null:
		return
	var available := music_playback.get_frames_available()
	var roots := [110.0, 130.81, 98.0, 146.83]
	for _i in available:
		var root: float = roots[int(music_time / 4.0) % roots.size()]
		var breath := 0.72 + sin(music_time * 0.42) * 0.18
		var pad := sin(TAU * root * music_time) * 0.012
		pad += sin(TAU * root * 1.5 * music_time + 0.7) * 0.008
		pad += sin(TAU * root * 2.0 * music_time + 1.4) * 0.005
		var bell_envelope := pow(maxf(0.0, 1.0 - fmod(music_time, 2.0) / 2.0), 3.0)
		var bell := sin(TAU * root * 4.0 * music_time) * bell_envelope * 0.008
		var air := sin(music_time * 31.7) * sin(music_time * 47.3) * 0.0025
		var sample := (pad * breath + bell + air) * 0.82
		music_playback.push_frame(Vector2(sample, sample))
		music_time += 1.0 / RATE


func play_ui() -> void:
	_play_sweep(560.0, 820.0, 0.06, 0.07, "triangle")
	_play_sweep(980.0, 1240.0, 0.035, 0.035)


func play_launch() -> void:
	_play_sweep(74.0, 42.0, 0.26, 0.30)
	_play_sweep(130.0, 520.0, 0.24, 0.14, "triangle")
	_play_noise(0.16, 0.14)
	_haptic(42)


func play_special() -> void:
	_play_sweep(210.0, 1320.0, 0.24, 0.14, "triangle")
	_play_sweep(760.0, 1680.0, 0.15, 0.065)
	_haptic(30)


func play_land(score: float) -> void:
	_play_sweep(145.0, 310.0, 0.15, 0.18)
	_play_noise(0.10, 0.075)
	if score >= 60.0:
		_play_sweep(440.0, 880.0, 0.22, 0.09, "triangle")
	_haptic(46 if score >= 60.0 else 26)


func play_failure() -> void:
	_play_sweep(340.0, 72.0, 0.38, 0.15, "triangle")
	_play_noise(0.20, 0.07)
	_haptic(72)


func play_chest() -> void:
	_play_sweep(180.0, 480.0, 0.20, 0.12, "triangle")
	_play_sweep(520.0, 1180.0, 0.36, 0.10)
	_play_sweep(790.0, 1580.0, 0.42, 0.055)
	_play_noise(0.09, 0.045)
	_haptic(58)


func play_reward(rare: bool) -> void:
	if rare:
		_play_sweep(360.0, 1120.0, 0.30, 0.11, "triangle")
		_play_sweep(720.0, 1760.0, 0.24, 0.06)
		_haptic(48)
	else:
		_play_sweep(720.0, 1040.0, 0.075, 0.055, "triangle")


func apply_settings(settings: Dictionary) -> void:
	var music_index := AudioServer.get_bus_index("Music")
	var sfx_index := AudioServer.get_bus_index("SFX")
	if music_index >= 0:
		var music_value := clampf(float(settings.get("music", 0.75)), 0.0, 1.0)
		AudioServer.set_bus_mute(music_index, music_value <= 0.001)
		AudioServer.set_bus_volume_db(music_index, linear_to_db(maxf(music_value, 0.001)))
	if sfx_index >= 0:
		var sound_value := clampf(float(settings.get("sound", 0.9)), 0.0, 1.0)
		AudioServer.set_bus_mute(sfx_index, sound_value <= 0.001)
		AudioServer.set_bus_volume_db(sfx_index, linear_to_db(maxf(sound_value, 0.001)))
	var quality := clampi(int(settings.get("quality", 2)), 0, 3)
	Engine.max_fps = 30 if quality == 0 else 60
	var viewport := get_viewport()
	if viewport:
		viewport.scaling_3d_scale = [0.72, 0.86, 1.0, 1.0][quality]
		viewport.msaa_3d = Viewport.MSAA_2X if quality >= 2 else Viewport.MSAA_DISABLED


func _play_sweep(from_hz: float, to_hz: float, duration: float, amplitude: float, waveform := "sine") -> void:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = maxf(0.12, duration + 0.06)
	player.stream = generator
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var frames := int(RATE * duration)
	var phase := 0.0
	for i in frames:
		var progress := float(i) / float(frames)
		var frequency := lerpf(from_hz, to_hz, progress)
		phase += TAU * frequency / RATE
		var wave := sin(phase)
		if waveform == "triangle":
			wave = asin(sin(phase)) * 0.63662
		var envelope := pow(1.0 - progress, 1.55)
		var sample := wave * amplitude * envelope
		playback.push_frame(Vector2(sample, sample))
	get_tree().create_timer(duration + 0.12).timeout.connect(player.queue_free)


func _play_noise(duration: float, amplitude: float) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = duration + 0.08
	player.stream = generator
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var frames := int(RATE * duration)
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec()
	var filtered := 0.0
	for i in frames:
		var progress := float(i) / float(frames)
		filtered = lerpf(filtered, rng.randf_range(-1.0, 1.0), 0.22)
		var sample := filtered * amplitude * pow(1.0 - progress, 2.2)
		playback.push_frame(Vector2(sample, sample))
	get_tree().create_timer(duration + 0.1).timeout.connect(player.queue_free)


func _haptic(milliseconds: int) -> void:
	if GameState != null and GameState.settings.get("vibration", true) and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)
