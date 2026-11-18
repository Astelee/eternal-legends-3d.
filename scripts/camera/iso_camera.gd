class_name IsoCameraRig
extends Node3D

@export var target: Node3D
@export var distance: float = 18.0
@export_range(20.0, 80.0) var pitch_degrees: float = 50.0
@export var yaw_degrees: float = 45.0
@export var follow_speed: float = 8.0
@export var fov_degrees: float = 35.0

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_camera.fov = fov_degrees
	_camera.position = Vector3(0.0, 0.0, distance)
	rotation_degrees = Vector3(-pitch_degrees, yaw_degrees, 0.0)
	if target:
		global_position = target.global_position


func _process(delta: float) -> void:
	if target:
		var weight := clampf(follow_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(target.global_position, weight)