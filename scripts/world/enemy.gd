class_name Enemy
extends CharacterBody2D
# Inimigo: persegue o jogador, avisa o golpe (fica amarelo), ataca, leva dano,
# some ao morrer e dá XP.

const TEXTURE: Texture2D = preload("res://assets/characters/tiny_dungeon.png")
const COLS := 12
const TYPES := {
	"slime": {"name": "Slime", "frame": 108, "hp": 30, "damage": 8, "speed": 22.0, "xp": 12, "scale": 1.0},
	"bat": {"name": "Morcego", "frame": 120, "hp": 18, "damage": 6, "speed": 38.0, "xp": 10, "scale": 1.0},
	"spider": {"name": "Aranha", "frame": 122, "hp": 40, "damage": 10, "speed": 30.0, "xp": 16, "scale": 1.0},
	"ghost": {"name": "Fantasma", "frame": 121, "hp": 35, "damage": 9, "speed": 24.0, "xp": 15, "scale": 1.0},
	"ogre": {"name": "Ogro", "frame": 109, "hp": 120, "damage": 15, "speed": 22.0, "xp": 100, "scale": 1.5}
}

var kind: String = "slime"
var display_name: String = "Slime"
var frame: int = 108
var max_hp: int = 30
var hp: int = 30
var damage: int = 8
var speed: float = 22.0
var xp_reward: int = 12
var body_scale: float = 1.0
var hit_radius: float = 6.0
var aggro_radius: float = 80.0
var attack_range: float = 15.0
var attack_cooldown: float = 1.3

var _player: Player
var _visual: Node2D
var _body: Sprite2D
var _shape: CollisionShape2D
var _knock: Vector2 = Vector2.ZERO
var _cooldown: float = 0.5
var _windup: float = 0.0
var _flash: float = 0.0
var _time: float = 0.0
var _phase: float = 0.0
var _facing_left: bool = false
var _dying: bool = false


func _ready() -> void:
	var data: Dictionary = TYPES.get(kind, TYPES["slime"])
	display_name = data["name"]
	frame = data["frame"]
	max_hp = data["hp"]
	hp = max_hp
	damage = data["damage"]
	speed = data["speed"]
	xp_reward = data["xp"]
	body_scale = data["scale"]
	hit_radius = 6.0 * body_scale
	attack_range = 15.0 * body_scale
	_phase = randf() * TAU

	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemies")

	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0 * body_scale
	_shape.shape = circle
	_shape.position = Vector2(0, -4)
	add_child(_shape)

	_visual = Node2D.new()
	add_child(_visual)
	_body = Sprite2D.new()
	_body.texture = TEXTURE
	_body.region_enabled = true
	_body.region_rect = Rect2((frame % COLS) * 16, (frame / COLS) * 16, 16, 16)
	_body.centered = false
	_body.offset = Vector2(-8, -16)
	_visual.add_child(_body)


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player

	_cooldown = maxf(_cooldown - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	_knock = _knock.move_toward(Vector2.ZERO, 320.0 * delta)

	var move := Vector2.ZERO
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_strike()
	elif _player != null and _player.state != Player.State.DEAD:
		var to := _player.global_position - global_position
		var dist := to.length()
		if dist < aggro_radius:
			_face(to.x)
			if dist > attack_range:
				move = to.normalized() * speed
			elif _cooldown <= 0.0:
				_windup = 0.4
				_cooldown = attack_cooldown

	velocity = move + _knock
	move_and_slide()


func _strike() -> void:
	if _player == null or _player.state == Player.State.DEAD:
		return
	if global_position.distance_to(_player.global_position) <= attack_range + 6.0:
		_player.take_hit(damage, global_position)


func take_damage(amount: int, from: Vector2) -> void:
	if _dying:
		return
	hp -= amount
	_flash = 0.15
	_windup = 0.0
	_knock = (global_position - from).normalized() * 90.0
	Audio.play_sfx("hit", 0.1)
	FloatText.spawn(get_parent(), global_position, str(amount), Color.WHITE)
	if hp <= 0:
		_die()


func _die() -> void:
	_dying = true
	remove_from_group("enemies")
	_shape.set_deferred("disabled", true)
	Audio.play_sfx("enemy_die", 0.08)
	var parent := get_parent()
	if Game.add_xp(xp_reward):
		Audio.play_sfx("levelup")
	FloatText.spawn(parent, global_position, "+%d XP" % xp_reward, Color("#f2dc94"))
	if kind == "ogre":
		FloatText.spawn(parent, global_position + Vector2(0, -12), "Chefe derrotado!", Color("#e0605a"))
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_visual, "modulate:a", 0.0, 0.4)
	tw.tween_property(_visual, "scale", Vector2(0.2, 0.2) * body_scale, 0.4)
	tw.chain().tween_callback(queue_free)


func _face(dx: float) -> void:
	if dx < -0.1:
		_facing_left = true
	elif dx > 0.1:
		_facing_left = false


func _process(delta: float) -> void:
	_time += delta
	if _dying:
		return
	var offset := Vector2.ZERO
	var scl := Vector2.ONE * body_scale
	var tint := Color.WHITE
	if kind == "bat":
		offset.y = -4.0 + sin(_time * 9.0 + _phase) * 2.0
	elif velocity.length() > 2.0:
		offset.y = -absf(sin(_time * 10.0 + _phase)) * 1.5
	else:
		scl.y *= 1.0 + sin(_time * 2.5 + _phase) * 0.04
	if _windup > 0.0:
		tint = Color(1.6, 1.3, 0.5)
		scl *= 1.12
	if _flash > 0.0:
		tint = Color(2.0, 0.6, 0.6)
	_visual.position = offset
	_visual.scale = scl
	_body.flip_h = _facing_left
	_body.modulate = tint
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0 * body_scale, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not _dying and hp < max_hp:
		var w := 14.0 * body_scale
		var y := -17.0 * body_scale - 4.0
		draw_rect(Rect2(-w / 2.0, y, w, 2.0), Color(0.08, 0.06, 0.10, 0.9))
		draw_rect(Rect2(-w / 2.0, y, w * float(hp) / float(max_hp), 2.0), Color("#b23a34"))