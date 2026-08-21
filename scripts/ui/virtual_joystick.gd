extends Control

signal vector_changed(value: Vector2)

const RADIUS := 104.0
const KNOB_RADIUS := 48.0

var active_pointer := -999
var active := false
var base_center := Vector2(170, 225)
var knob_center := base_center
var current_vector := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pointer := -1
	var press := false
	var release := false
	var motion := false
	if event is InputEventScreenTouch:
		pos = event.position; pointer = event.index; press = event.pressed; release = not event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position; pointer = event.index; motion = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position; pointer = -1; press = event.pressed; release = not event.pressed
	elif event is InputEventMouseMotion and active_pointer == -1:
		pos = event.position; pointer = -1; motion = true
	else:
		return
	if press and active_pointer == -999:
		active_pointer = pointer
		active = true
		base_center = Vector2(clampf(pos.x, RADIUS + 12.0, size.x - RADIUS - 12.0), clampf(pos.y, RADIUS + 12.0, size.y - RADIUS - 12.0))
		_update_knob(pos)
		accept_event()
	elif pointer == active_pointer and motion:
		_update_knob(pos)
		accept_event()
	elif pointer == active_pointer and release:
		active_pointer = -999
		active = false
		current_vector = Vector2.ZERO
		knob_center = base_center
		vector_changed.emit(current_vector)
		queue_redraw()
		accept_event()


func _update_knob(pos: Vector2) -> void:
	var offset := pos - base_center
	current_vector = (offset / RADIUS).limit_length(1.0)
	if current_vector.length() < 0.12:
		current_vector = Vector2.ZERO
	knob_center = base_center + current_vector * RADIUS
	vector_changed.emit(current_vector)
	queue_redraw()


func reset() -> void:
	active_pointer = -999
	active = false
	current_vector = Vector2.ZERO
	knob_center = base_center
	vector_changed.emit(current_vector)
	queue_redraw()


func _draw() -> void:
	draw_circle(base_center, RADIUS + 8.0, Color(0.03, 0.05, 0.13, 0.38 if not active else 0.62))
	draw_circle(base_center, RADIUS, Color(0.17, 0.20, 0.36, 0.38 if not active else 0.58))
	draw_arc(base_center, RADIUS, 0.0, TAU, 48, Color(0.55, 0.72, 1.0, 0.62), 4.0)
	draw_circle(knob_center, KNOB_RADIUS + 5.0, Color(0.05, 0.07, 0.16, 0.76))
	draw_circle(knob_center, KNOB_RADIUS, Color(0.46, 0.31, 0.93, 0.88))
	draw_circle(knob_center - Vector2(10, 12), 10.0, Color(0.85, 0.91, 1.0, 0.55))
