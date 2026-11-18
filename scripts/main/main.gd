extends Node3D

@onready var _marker: MeshInstance3D = $Marker
@onready var _rig: IsoCameraRig = $CameraRig
@onready var _sun: DirectionalLight3D = $Sun
@onready var _info: Label = $UI/InfoLabel


func _ready() -> void:
	_sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	_rig.target = _marker


func _process(delta: float) -> void:
	_marker.rotate_y(delta)
	_info.text = "%s v%s | Etapa 1 | FPS: %d" % [Game.GAME_NAME, Game.VERSION, Engine.get_frames_per_second()]