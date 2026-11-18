extends Node2D

const TILE := 16
const TILES := 80
const COLOR_A := Color(0.30, 0.55, 0.25)
const COLOR_B := Color(0.26, 0.49, 0.22)


func _draw() -> void:
	var half := TILES * TILE / 2
	draw_rect(Rect2(-half, -half, TILES * TILE, TILES * TILE), COLOR_A)
	for x in TILES:
		for y in TILES:
			if (x + y) % 2 == 1:
				draw_rect(Rect2(-half + x * TILE, -half + y * TILE, TILE, TILE), COLOR_B)