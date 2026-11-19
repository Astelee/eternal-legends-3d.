class_name Player
extends CharacterBody2D

signal state_changed(new_state: int)
signal hp_changed(hp: int, max_hp: int)

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEAD }

const FRAME_COLS := 12
const FRAME_SIZE := 16

# Arma de cada classe (índice da peça em assets/characters/tiny_dungeon.png) e alcance do golpe.
# 96 = guerreiro (espada), 112 = arqueiro (lança, o pacote não tem arco), 84 = mago (cajado).
const WEAPON_FRAMES := {96: 104, 112: 131, 84: 130}
const WEAPON_REACH := {96: 20.0, 112: 28.0, 84: 24.0}

@export var character_frame: int = 96
@export var walk_speed: float = 45.0
@export var run_speed: float = 80.0
@export var run_threshold: float = 0.85
@export var attack_time: float = 0.5
@export var hurt_time: float = 0.3
@export var base_hp: int = 100
@export var hp_per_level: int = 10
@export var world_limit: Rect2 = Rect2(0, 0, 640, 480)

var joystick: VirtualJoystick
var state: int = State.IDLE
var direction_index: int = 2
var max_hp: int = 100
var hp: int = 100

var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _facing_left: bool = false
var _step_timer: float = 0.0
var _hit_done: bool = false
var _invuln: float = 0.0
var _knock: Vector2 = Vector2.ZERO
var _last_level: int = 1

var _weapon: Node2D
var _weapon_sprite: Sprite2D

@onready var _visual: Node2D = $Visual
@onready var _body: Sprite2D = $Visual/Body
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	_build_weapon()
	_apply_frame()
	_last_level = Game.level
	max_hp = _max_hp_for(Game.level)
	hp = max_hp
	Game.profile_changed.connect(_on_profile_changed)
	hp_changed.emit(hp, max_hp)


func _process(delta: float) -> void:
	_update_visual(delta)


func _physics_process(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)
	match state:
		State.ATTACK:
			velocity = Vector2.ZERO
			_state_timer -= delta
			# O golpe acerta na metade do movimento da arma.
			if not _hit_done and _state_timer <= attack_time * 0.55:
				_hit_done = true
				_do_hit()
			if _state_timer <= 0.0:
				_set_state(State.IDLE)
		State.HURT:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, 500.0 * delta)
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


# ------------------------------------------------------------------ combate

func attack() -> void:
	if state == State.DEAD or state == State.ATTACK:
		return
	_auto_face()
	_set_state(State.ATTACK)
	Audio.play_sfx("attack", 0.08)


# Vira para o inimigo mais próximo (facilita o toque no celular).
func _auto_face() -> void:
	var best: Enemy = null
	var best_dist := 48.0
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null:
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	if best == null:
		return
	var to := best.global_position - global_position
	_facing = to.normalized()
	if to.x < -0.1:
		_facing_left = true
	elif to.x > 0.1:
		_facing_left = false


func attack_damage() -> int:
	return 8 + Game.level * 3


func _do_hit() -> void:
	var reach: float = WEAPON_REACH.get(character_frame, 20.0)
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null:
			continue
		var to := e.global_position - global_position
		var dist := to.length()
		if dist > reach + e.hit_radius:
			continue
		if dist > 8.0 and _facing.dot(to / dist) < 0.1:
			continue
		e.take_damage(int(attack_damage() * randf_range(0.85, 1.2)), global_position)


func take_hit(amount: int = 10, from: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD or _invuln > 0.0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	_invuln = 0.7
	if from != Vector2.ZERO:
		_knock = (global_position - from).normalized() * 110.0
	FloatText.spawn(get_parent(), global_position, str(amount), Color("#e0605a"))
	if hp == 0:
		die()
		return
	Audio.play_sfx("hurt", 0.05)
	_set_state(State.HURT)


func heal(amount: int) -> void:
	if state == State.DEAD:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


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
		_invuln = 1.2
		hp_changed.emit(hp, max_hp)
		Audio.play_sfx("revive")
		_set_state(State.IDLE)


# ------------------------------------------------------------------ mundo

func set_world(rect: Rect2) -> void:
	world_limit = rect
	_camera.limit_left = int(rect.position.x)
	_camera.limit_top = int(rect.position.y)
	_camera.limit_right = int(rect.end.x)
	_camera.limit_bottom = int(rect.end.y)


func teleport(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_camera.reset_smoothing()


func set_character_frame(frame: int) -> void:
	character_frame = frame
	if is_node_ready():
		_apply_frame()


func _max_hp_for(level: int) -> int:
	return base_hp + (level - 1) * hp_per_level


func _on_profile_changed() -> void:
	if Game.level == _last_level:
		return
	_last_level = Game.level
	max_hp = _max_hp_for(Game.level)
	if state != State.DEAD:
		hp = max_hp # subir de nível cura tudo
	hp_changed.emit(hp, max_hp)


func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	if state == State.ATTACK:
		_state_timer = attack_time
		_hit_done = false
	elif state == State.HURT:
		_state_timer = hurt_time
	state_changed.emit(state)


# ------------------------------------------------------------------ visual

func _build_weapon() -> void:
	_weapon = Node2D.new()
	_visual.add_child(_weapon)
	_weapon_sprite = Sprite2D.new()
	_weapon_sprite.texture = _body.texture
	_weapon_sprite.region_enabled = true
	_weapon_sprite.centered = false
	_weapon_sprite.offset = Vector2(-8, -12) # o "cabo" da arma fica no ponto de giro (a mão)
	_weapon.add_child(_weapon_sprite)


func _apply_frame() -> void:
	var col := character_frame % FRAME_COLS
	var row := character_frame / FRAME_COLS
	_body.region_rect = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	if _weapon_sprite:
		var wf: int = WEAPON_FRAMES.get(character_frame, 104)
		_weapon_sprite.region_rect = Rect2((wf % FRAME_COLS) * FRAME_SIZE, (wf / FRAME_COLS) * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)


func _attack_progress() -> float:
	return 1.0 - clampf(_state_timer / attack_time, 0.0, 1.0)


# O personagem tem uma pose só, então os movimentos são feitos por código:
# balanço ao andar, avanço e golpe de arma ao atacar, tremida ao levar dano e deitar ao morrer.
func _update_visual(delta: float) -> void:
	_anim_time += delta
	var offset := Vector2.ZERO
	var rot := 0.0
	var scl := Vector2.ONE
	var tint := Color.WHITE
	var weapon_rot := 0.35

	match state:
		State.IDLE:
			scl.y = 1.0 + sin(_anim_time * 2.5) * 0.03
		State.WALK:
			var s := sin(_anim_time * 10.0)
			offset.y = -absf(s) * 1.5
			rot = s * 0.06
			weapon_rot = 0.35 + s * 0.12
		State.RUN:
			var s := sin(_anim_time * 16.0)
			offset.y = -absf(s) * 2.5
			rot = s * 0.1
			weapon_rot = 0.5 + s * 0.2
		State.ATTACK:
			var p := _attack_progress()
			var k := sin(p * PI)
			offset = _facing * k * 4.0
			scl = Vector2(1.0 + k * 0.1, 1.0 - k * 0.06)
			var e := 1.0 - pow(1.0 - p, 3.0)
			weapon_rot = lerpf(-1.4, 1.8, e)
		State.HURT:
			offset.x = sin(_anim_time * 60.0) * 1.5
			tint = Color(1.0, 0.4, 0.4)
		State.DEAD:
			rot = PI / 2.0
			tint = Color(0.5, 0.5, 0.55)

	if _invuln > 0.0 and state != State.DEAD and int(_invuln * 25.0) % 2 == 0:
		tint.a = 0.5

	_visual.position = offset
	_visual.rotation = rot
	_visual.scale = scl
	_body.flip_h = _facing_left
	_body.modulate = tint

	_weapon.visible = state != State.DEAD
	_weapon.position = Vector2(-6.0 if _facing_left else 6.0, -6.0)
	_weapon.scale.x = -1.0 if _facing_left else 1.0
	_weapon.rotation = weapon_rot
	_weapon_sprite.modulate = tint
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Rastro do golpe
	if state == State.ATTACK:
		var p := _attack_progress()
		var e := 1.0 - pow(1.0 - p, 3.0)
		var a0 := -1.4 - PI / 2.0
		var a1 := lerpf(-1.4, 1.8, e) - PI / 2.0
		if a1 - a0 > 0.1:
			var center := Vector2(-6.0 if _facing_left else 6.0, -6.0)
			var col := Color(1, 1, 1, 0.7 * (1.0 - p))
			if _facing_left:
				draw_arc(center, 14.0, PI - a1, PI - a0, 12, col, 2.0)
			else:
				draw_arc(center, 14.0, a0, a1, 12, col, 2.0)