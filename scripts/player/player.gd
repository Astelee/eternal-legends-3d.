class_name Player
extends CharacterBody2D

signal state_changed(new_state: int)
signal hp_changed(hp: int, max_hp: int)

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEAD }

const FRAME_COLS := 12
const FRAME_SIZE := 16

# Qual personagem de assets/characters/tiny_dungeon.png usar (índice da peça).
# 96 = guerreiro, 112 = arqueiro, 84 = mago.
@export var character_frame: int = 96
@export var walk_speed: float = 45.0
@export var run_speed: float = 80.0
@export var run_threshold: float = 0.85
@export var attack_time: float = 0.5
@export var hurt_time: float = 0.4
@export var max_hp: int = 100
@export var hit_damage: int = 15
@export var world_limit: Rect2 = Rect2(0, 0, 640, 480)

var joystick: VirtualJoystick
var state: int = State.IDLE
var direction_index: int = 2

var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _facing_left: bool = false
var _step_timer: float = 0.0

var hp: int = 100

@onready var _visual: Node2D = $Visual
@onready var _body: Sprite2D = $Visual/Body


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	_apply_frame()
	hp_changed.emit(hp, max_hp)


func _process(delta: float) -> void:
	_update_visual(delta)


func _physics_process(delta: float) -> void:
	match state:
		State.ATTACK, State.HURT:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_set_state(State.IDLE)
		State.DEAD:
			velocity = Vector2.ZERO
		_:
			_move()

	move_and_slide()
	position = position.clamp(world_limit.position, world_limit.end)


func _move() -> void:
	var input := Vector2.ZERO
	if joystick:
		input = joystick.output

	var strength := input.length()
	if strength < 0.01:
		velocity = Vector2.ZERO
		_set_state(State.IDLE)
		return

	# Oito direções: o ângulo do joystick é arredondado para múltiplos de 45 graus.
	direction_index = posmod(roundi(input.angle() / (PI / 4.0)), 8)
	var dir := Vector2.from_angle(direction_index * PI / 4.0)
	_facing = dir
	if dir.x < -0.1:
		_facing_left = true
	elif dir.x > 0.1:
		_facing_left = false

	var running := strength >= run_threshold
	velocity = dir * (run_speed if running else walk_speed)
	_set_state(State.RUN if running else State.WALK)

	_step_timer -= get_physics_process_delta_time()
	if _step_timer <= 0.0:
		_step_timer = 0.22 if running else 0.34
		Audio.play_sfx("step", 0.15)


func attack() -> void:
	if state == State.DEAD or state == State.ATTACK:
		return
	_set_state(State.ATTACK)
	Audio.play_sfx("attack", 0.08)
	# XP provisório até existirem inimigos: cada ataque rende um pouco.
	if Game.add_xp(3):
		Audio.play_sfx("levelup")


func take_hit() -> void:
	if state == State.DEAD:
		return
	hp = maxi(hp - hit_damage, 0)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		die()
		return
	Audio.play_sfx("hurt", 0.05)
	_set_state(State.HURT)


func die() -> void:
	if state == State.DEAD:
		return
	hp = 0
	hp_changed.emit(hp, max_hp)
	Audio.play_sfx("death")
	_set_state(State.DEAD)


func revive() -> void:
	if state == State.DEAD:
		hp = max_hp
		hp_changed.emit(hp, max_hp)
		Audio.play_sfx("revive")
		_set_state(State.IDLE)


func set_character_frame(frame: int) -> void:
	character_frame = frame
	if is_node_ready():
		_apply_frame()


func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	if state == State.ATTACK:
		_state_timer = attack_time
	elif state == State.HURT:
		_state_timer = hurt_time
	state_changed.emit(state)


func _apply_frame() -> void:
	var col := character_frame % FRAME_COLS
	var row := character_frame / FRAME_COLS
	_body.region_rect = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)


# O personagem tem uma pose só, então os movimentos são feitos por código:
# balanço ao andar e correr, avanço ao atacar, tremida ao levar dano e deitar ao morrer.
func _update_visual(delta: float) -> void:
	_anim_time += delta
	var offset := Vector2.ZERO
	var rot := 0.0
	var scl := Vector2.ONE
	var tint := Color.WHITE

	match state:
		State.IDLE:
			scl.y = 1.0 + sin(_anim_time * 2.5) * 0.03
		State.WALK:
			var s := sin(_anim_time * 10.0)
			offset.y = -absf(s) * 1.5
			rot = s * 0.06
		State.RUN:
			var s := sin(_anim_time * 16.0)
			offset.y = -absf(s) * 2.5
			rot = s * 0.1
		State.ATTACK:
			var p := 1.0 - clampf(_state_timer / attack_time, 0.0, 1.0)
			var k := sin(p * PI)
			offset = _facing * k * 6.0
			scl = Vector2(1.0 + k * 0.15, 1.0 - k * 0.1)
			tint = Color(1.25, 1.0, 0.75)
		State.HURT:
			offset.x = sin(_anim_time * 60.0) * 1.5
			tint = Color(1.0, 0.4, 0.4)
		State.DEAD:
			rot = PI / 2.0
			tint = Color(0.5, 0.5, 0.55)

	_visual.position = offset
	_visual.rotation = rot
	_visual.scale = scl
	_body.flip_h = _facing_left
	_body.modulate = tint


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))