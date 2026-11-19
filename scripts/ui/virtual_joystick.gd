class_name VirtualJoystick
extends Control

@export var radius: float = 110.0
@export var deadzone: float = 0.15

var output: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and get_global_rect().has_point(event.position):
			_touch_index = event.index
			_update_from(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_from(event.position)


func _update_from(touch_position: Vector2) -> void:
	var center := get_global_rect().get_center()
	_knob_offset = (touch_position - center).limit_length(radius)
	var value := _knob_offset / radius
	output = Vector2.ZERO if value.length() < deadzone else value
	queue_redraw()


func _reset() -> void:
	_touch_index = -1
	_knob_offset = Vector2.ZERO
	output = Vector2.ZERO
	queue_redraw()


func reset_input() -> void:
	_reset()


func _draw() -> void:
	var center := size / 2.0
	var ring := radius + 20.0
	# Base: pedra escura com anel dourado
	draw_circle(center, ring, Color(0.08, 0.06, 0.10, 0.45))
	draw_arc(center, ring, 0.0, TAU, 64, Color(0.83, 0.66, 0.29, 0.75), 4.0, true)
	draw_arc(center, ring - 8.0, 0.0, TAU, 64, Color(0.43, 0.32, 0.14, 0.6), 2.0, true)
	# Marcas nos quatro cantos
	for i in 4:
		var a := i * PI / 2.0
		draw_circle(center + Vector2.from_angle(a) * (ring - 4.0), 5.0, Color(0.95, 0.86, 0.58, 0.8))
	# Manopla
	var knob := center + _knob_offset
	draw_circle(knob + Vector2(0, 4), 46.0, Color(0, 0, 0, 0.35))
	draw_circle(knob, 46.0, Color(0.23, 0.19, 0.27, 0.95))
	draw_arc(knob, 44.0, 0.0, TAU, 48, Color(0.83, 0.66, 0.29, 1.0), 5.0, true)
	draw_circle(knob, 14.0, Color(0.95, 0.86, 0.58, 0.9))