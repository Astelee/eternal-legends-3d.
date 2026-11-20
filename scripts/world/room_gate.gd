class_name RoomGate
extends Area2D
# Passagem entre as salas do tutorial. Fica escondida enquanto está trancada;
# ao abrir, brilha e leva o jogador à próxima sala (ou à vila, no fim).

signal used(target: String)

var target: String = ""
var caption: String = ""
var gate_size: Vector2 = Vector2(48.0, 16.0)
var locked: bool = true

var _time: float = 0.0
var _cooldown: float = 0.6
var _label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	z_index = 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = gate_size
	shape.shape = rect
	add_child(shape)

	_label = Label.new()
	_label.text = caption
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", Color("#f2dc94"))
	_label.add_theme_color_override("font_outline_color", Color("#14101a"))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(120.0, 12.0)
	_label.position = Vector2(-60.0, -gate_size.y / 2.0 - 14.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = not locked
	add_child(_label)


func set_locked(value: bool) -> void:
	locked = value
	_cooldown = 0.6
	if _label != null:
		_label.visible = not value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if not locked:
		queue_redraw()


func _physics_process(delta: float) -> void:
	if locked:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_cooldown = 2.0
			used.emit(target)
			return


func _draw() -> void:
	if locked:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	var r := Rect2(-gate_size / 2.0, gate_size)
	draw_rect(r, Color(0.5, 0.8, 1.0, 0.10 + 0.14 * pulse))
	draw_rect(r, Color(0.95, 0.86, 0.58, 0.55 + 0.35 * pulse), false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, gate_size.x * 0.32 + pulse * 3.0, 0.0, TAU, 32, Color(0.95, 0.86, 0.58, 0.8), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)