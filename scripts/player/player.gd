class_name Player
extends CharacterBody2D

signal state_changed(new_state: int)

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEAD }

# Índice 0 = direita, e segue no sentido horário (a tela tem o Y para baixo).
const DIRECTION_NAMES := ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]

const STATE_NAMES := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.RUN: "run",
	State.ATTACK: "attack",
	State.HURT: "hurt",
	State.DEAD: "death",
}

const STATE_COLORS := {
	State.IDLE: Color(0.25, 0.45, 0.9),
	State.WALK: Color(0.2, 0.75, 0.8),
	State.RUN: Color(0.7, 0.4, 0.95),
	State.ATTACK: Color(1.0, 0.55, 0.1),
	State.HURT: Color(0.9, 0.15, 0.15),
	State.DEAD: Color(0.3, 0.3, 0.3),
}

@export var walk_speed: float = 45.0
@export var run_speed: float = 80.0
@export var run_threshold: float = 0.85
@export var attack_time: float = 0.5
@export var hurt_time: float = 0.4
@export var world_limit: Rect2 = Rect2(-640, -640, 1280, 1280)

var joystick: VirtualJoystick
var state: int = State.IDLE
var direction_index: int = 2

var _state_timer: float = 0.0

# Quando existir um AnimatedSprite2D filho, ele é usado no lugar do desenho provisório.
# Nomes das animações: <estado>_<direção>, por exemplo walk_down_right.
@onready var _sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	_refresh_visual()


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
	var new_index := posmod(roundi(input.angle() / (PI / 4.0)), 8)
	var dir := Vector2.from_angle(new_index * PI / 4.0)

	var running := strength >= run_threshold
	velocity = dir * (run_speed if running else walk_speed)

	if new_index != direction_index:
		direction_index = new_index
		_refresh_visual()
	_set_state(State.RUN if running else State.WALK)


func attack() -> void:
	if state == State.DEAD or state == State.ATTACK:
		return
	_set_state(State.ATTACK)


func take_hit() -> void:
	if state == State.DEAD:
		return
	_set_state(State.HURT)


func die() -> void:
	_set_state(State.DEAD)


func revive() -> void:
	if state == State.DEAD:
		_set_state(State.IDLE)


func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	if state == State.ATTACK:
		_state_timer = attack_time
	elif state == State.HURT:
		_state_timer = hurt_time
	_refresh_visual()
	state_changed.emit(state)


func _refresh_visual() -> void:
	var anim_name: String = "%s_%s" % [STATE_NAMES[state], DIRECTION_NAMES[direction_index]]
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)
	queue_redraw()


# Desenho provisório (sem arte): corpo colorido pelo estado e uma bolinha amarela na direção do olhar.
func _draw() -> void:
	if _sprite:
		return
	var color: Color = STATE_COLORS[state]
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == State.DEAD:
		draw_rect(Rect2(-12, -8, 24, 10), color)
		return
	draw_rect(Rect2(-6, -22, 12, 22), color)
	var facing := Vector2.from_angle(direction_index * PI / 4.0)
	draw_circle(Vector2(0, -12) + facing * 5.0, 2.5, Color(1.0, 0.85, 0.2))