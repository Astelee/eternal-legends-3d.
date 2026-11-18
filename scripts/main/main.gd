extends Node3D

@onready var _player: Player = $Player
@onready var _rig: IsoCameraRig = $CameraRig
@onready var _sun: DirectionalLight3D = $Sun
@onready var _joystick: VirtualJoystick = $UI/Joystick
@onready var _info: Label = $UI/InfoLabel
@onready var _attack_button: Button = $UI/Actions/AttackButton
@onready var _hurt_button: Button = $UI/Actions/HurtButton
@onready var _death_button: Button = $UI/Actions/DeathButton


func _ready() -> void:
	_sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	_player.joystick = _joystick
	_player.camera_rig = _rig
	_rig.target = _player
	_attack_button.pressed.connect(_player.attack)
	_hurt_button.pressed.connect(_player.take_hit)
	_death_button.pressed.connect(_on_death_pressed)
	_player.state_changed.connect(_on_player_state_changed)


func _process(_delta: float) -> void:
	var state_name: String = Player.State.keys()[_player.state]
	_info.text = "%s v%s | Etapa 2 | %s | FPS: %d" % [Game.GAME_NAME, Game.VERSION, state_name, Engine.get_frames_per_second()]


func _on_death_pressed() -> void:
	if _player.state == Player.State.DEAD:
		_player.revive()
	else:
		_player.die()


func _on_player_state_changed(new_state: int) -> void:
	_death_button.text = "Reviver" if new_state == Player.State.DEAD else "Morrer"