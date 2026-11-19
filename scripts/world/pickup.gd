class_name Pickup
extends Area2D
# Poção de cura: só é pega se o jogador estiver ferido.

var texture: Texture2D
var frame: int = 115
var heal: int = 35

var _time: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	shape.position = Vector2(0, -6)
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2((frame % 12) * 16, (frame / 12) * 16, 16, 16)
	_sprite.centered = false
	_sprite.offset = Vector2(-8, -16)
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * 3.0) * 1.5


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var p := body as Player
		if p != null and p.state != Player.State.DEAD and p.hp < p.max_hp:
			p.heal(heal)
			FloatText.spawn(get_parent(), global_position, "+%d HP" % heal, Color("#5ac86e"))
			Audio.play_sfx("revive")
			queue_free()
			return