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


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, radius + 20.0, Color(1, 1, 1, 0.12))
	draw_arc(center, radius + 20.0, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 3.0)
	draw_circle(center + _knob_offset, 46.0, Color(1, 1, 1, 0.55))