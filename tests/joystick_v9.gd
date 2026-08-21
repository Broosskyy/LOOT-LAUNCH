extends SceneTree

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var Joystick = load("res://scripts/ui/virtual_joystick.gd")
	var joystick = Joystick.new()
	joystick.size = Vector2(560, 475)
	root.add_child(joystick)
	var latest := {"value": Vector2.ZERO}
	joystick.vector_changed.connect(func(value): latest.value = value)
	await process_frame
	var press := InputEventScreenTouch.new(); press.index = 2; press.position = Vector2(180, 230); press.pressed = true
	joystick._gui_input(press)
	var drag := InputEventScreenDrag.new(); drag.index = 2; drag.position = Vector2(275, 180)
	joystick._gui_input(drag)
	assert(latest.value.x > 0.5 and latest.value.y < -0.2, "Analog joystick reports continuous direction and magnitude")
	var release := InputEventScreenTouch.new(); release.index = 2; release.position = drag.position; release.pressed = false
	joystick._gui_input(release)
	assert(latest.value == Vector2.ZERO, "Analog joystick recenters on release")
	print("LOOT LAUNCH v10 analog joystick passed")
	quit(0)
