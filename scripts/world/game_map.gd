class_name GameMap
extends Node2D
# Base de todos os mapas (vila, masmorra...). O Main troca de mapa por aqui.

signal portal_used(target: String, from_id: String)

var map_id: String = ""
var title: String = ""
var world_limit: Rect2 = Rect2(0, 0, 640, 480)
var spawn_points: Dictionary = {"default": Vector2(328, 272)}


func _init() -> void:
	y_sort_enabled = true


# Posição onde o jogador aparece. from_id = mapa de onde ele veio.
func get_spawn(from_id: String) -> Vector2:
	return spawn_points.get(from_id, spawn_points["default"])