class_name Npc
extends CharacterBody2D
# NPC com vida: respira parado, passeia perto do ponto inicial, quica ao andar
# e vira para o jogador (com um "!") quando ele chega perto.

const FRAME_COLS := 12
const FRAME_SIZE := 16

var texture: Texture2D
var frame: int = 85
var wander_radius: float = 28.0
var speed: float = 18.0
var greet_distance: float = 36.0

var _home: Vector2
var _target: Vector2
var _moving: bool = false
var _wait: float = 1.0
var _time: float = 0.0
var _phase: float = 0.0
var _facing_left: bool = false
var _player: Node2D

var _visual: Node2D
var _body: Sprite2D
var _alert: Label


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_home = position
	_phase = randf() * TAU
	_wait = randf_range(0.5, 3.0)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0, -4)
	add_child(shape)

	_visual = Node2D.new()
	add_child(_visual)
	_body = Sprite2D.new()
	_body.texture = texture
	_body.region_enabled = true
	_body.region_rect = Rect2((frame % FRAME_COLS) * FRAME_SIZE, (frame / FRAME_COLS) * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	_body.centered = false
	_body.offset = Vector2(-8, -16)
	_visual.add_child(_body)

	_alert = Label.new()
	_alert.text = "!"
	_alert.add_theme_font_size_override("font_size", 10)
	_alert.add_theme_color_override("font_color", Color("#f2dc94"))
	_alert.add_theme_color_override("font_outline_color", Color("#14101a"))
	_alert.add_theme_constant_override("outline_size", 3)
	_alert.position = Vector2(-2, -30)
	_alert.visible = false
	add_child(_alert)


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D

	var near := _player != null and global_position.distance_to(_player.global_position) < greet_distance
	if near:
		velocity = Vector2.ZERO
		_moving = false
		_wait = maxf(_wait, 1.0)
		_face(_player.global_position.x - global_position.x)
	elif _moving:
		var to := _target - position
		if to.length() < 2.0:
			_stop()
		else:
			velocity = to.normalized() * speed
			_face(to.x)
	else:
		velocity = Vector2.ZERO
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()

	move_and_slide()
	if _moving and get_slide_collision_count() > 0:
		_stop()

	_alert.visible = near


func _process(delta: float) -> void:
	_time += delta
	var offset := Vector2.ZERO
	var rot := 0.0
	var scl := Vector2.ONE
	if _moving:
		var s := sin(_time * 9.0 + _phase)
		offset.y = -absf(s) * 1.2
		rot = s * 0.05
	elif _alert.visible:
		offset.y = -absf(sin(_time * 8.0)) * 2.0
	else:
		scl.y = 1.0 + sin(_time * 2.2 + _phase) * 0.035
	_visual.position = offset
	_visual.rotation = rot
	_visual.scale = scl
	_body.flip_h = _facing_left
	queue_redraw()


func _face(dx: float) -> void:
	if dx < -0.1:
		_facing_left = true
	elif dx > 0.1:
		_facing_left = false


func _pick_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(8.0, wander_radius)
	_target = _home + Vector2.from_angle(angle) * dist
	_moving = true


func _stop() -> void:
	_moving = false
	velocity = Vector2.ZERO
	_wait = randf_range(1.5, 4.5)


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))