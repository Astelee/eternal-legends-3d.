class_name Portal
extends Area2D
# Porta que leva a outro mapa quando o jogador encosta.

signal used(target: String)

var texture: Texture2D
var frame: int = 45
var target: String = ""
var caption: String = ""

var _cooldown: float = 0.6


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 10)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	add_child(shape)

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2((frame % 12) * 16, (frame / 12) * 16, 16, 16)
	sprite.centered = false
	sprite.offset = Vector2(-8, -16)
	add_child(sprite)

	if caption != "":
		var label := Label.new()
		label.text = caption
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color("#f2dc94"))
		label.add_theme_color_override("font_outline_color", Color("#14101a"))
		label.add_theme_constant_override("outline_size", 3)
		label.position = Vector2(-22, -28)
		label.size = Vector2(44, 10)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_cooldown = 2.0
			used.emit(target)
			return