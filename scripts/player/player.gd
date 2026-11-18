class_name Player
extends CharacterBody3D

signal state_changed(new_state: int)

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEAD }

const ANIM_NAMES := {
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

@export var walk_speed: float = 3.5
@export var run_speed: float = 6.5
@export var turn_speed: float = 14.0
@export var gravity: float = 25.0
@export var run_threshold: float = 0.85
@export var attack_time: float = 0.5
@export var hurt_time: float = 0.4

var joystick: VirtualJoystick
var camera_rig: IsoCameraRig
var state: int = State.IDLE

var _state_timer: float = 0.0
var _body_material := StandardMaterial3D.new()

@onready var _model: Node3D = $Model
@onready var _body: MeshInstance3D = $Model/Body
@onready var _anim: AnimationPlayer = get_node_or_null("AnimationPlayer")


func _ready() -> void:
	_body.material_override = _body_material
	_apply_state_visual()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	match state:
		State.ATTACK, State.HURT:
			velocity.x = 0.0
			velocity.z = 0.0
			_state_timer -= delta
			if _state_timer <= 0.0:
				_set_state(State.IDLE)
		State.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0
		_:
			_move(delta)

	move_and_slide()


func _move(delta: float) -> void:
	var input := Vector2.ZERO
	if joystick:
		input = joystick.output

	var strength := input.length()
	if strength < 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		_set_state(State.IDLE)
		return

	# Oito direções: o ângulo do joystick é arredondado para múltiplos de 45 graus.
	var snapped_angle := roundf(input.angle() / (PI / 4.0)) * (PI / 4.0)
	var dir2 := Vector2.from_angle(snapped_angle)
	var yaw := camera_rig.yaw_degrees if camera_rig else 0.0
	var dir := Vector3(dir2.x, 0.0, dir2.y).rotated(Vector3.UP, deg_to_rad(yaw))

	var running := strength >= run_threshold
	var speed := run_speed if running else walk_speed
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	var target_yaw := atan2(dir.x, dir.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

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
	_apply_state_visual()
	state_changed.emit(state)


func _apply_state_visual() -> void:
	var anim_name: String = ANIM_NAMES[state]
	if _anim and _anim.has_animation(anim_name):
		_anim.play(anim_name)
	_body_material.albedo_color = STATE_COLORS[state]
	if state == State.DEAD:
		_model.rotation.x = deg_to_rad(90.0)
		_model.position.y = 0.4
	else:
		_model.rotation.x = 0.0
		_model.position.y = 0.9