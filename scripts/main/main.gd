extends Node2D

@onready var _player: Player = $Town/Player
@onready var _joystick: VirtualJoystick = $UI/Joystick
@onready var _info: Label = $UI/InfoLabel
@onready var _hud: Hud = $UI/Hud


func _ready() -> void:
	_player.joystick = _joystick
	_player.set_character_frame(Game.class_frame)

	_hud.attack_pressed.connect(_player.attack)
	_hud.hurt_pressed.connect(_player.take_hit)
	_hud.death_pressed.connect(_on_death_pressed)
	_hud.class_selected.connect(_player.set_character_frame)
	_hud.profile_opened.connect(_joystick.reset_input)

	_player.hp_changed.connect(_hud.set_hp)
	_player.state_changed.connect(_on_player_state_changed)
	_hud.set_hp(_player.hp, _player.max_hp)


func _process(_delta: float) -> void:
	var state_name: String = Player.State.keys()[_player.state]
	_info.text = "%s v%s | %s | FPS: %d" % [Game.GAME_NAME, Game.VERSION, state_name, Engine.get_frames_per_second()]


func _on_death_pressed() -> void:
	if _player.state == Player.State.DEAD:
		_player.revive()
	else:
		_player.die()


func _on_player_state_changed(new_state: int) -> void:
	_hud.set_dead(new_state == Player.State.DEAD)