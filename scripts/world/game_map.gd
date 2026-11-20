class_name GameMap
extends Node2D
# Base de todos os mapas (vila, masmorra, tutorial...). O Main troca de mapa por aqui.

signal portal_used(target: String, from_id: String)

var map_id: String = ""
var title: String = ""
var world_limit: Rect2 = Rect2(0, 0, 640, 480)
var spawn_points: Dictionary = {"default": Vector2(328, 272)}

# Câmera: os mapas comuns seguem o jogador com zoom 3.
# Mapas de "tela única" (como o tutorial) usam zoom menor e câmera parada no meio da sala.
var camera_zoom: float = 3.0
var camera_fixed: bool = false


func _init() -> void:
	y_sort_enabled = true


# Posição onde o jogador aparece. from_id = mapa de onde ele veio.
func get_spawn(from_id: String) -> Vector2:
	return spawn_points.get(from_id, spawn_points["default"])