class_name DungeonMap
extends GameMap
# Masmorra montada com as peças do Tiny Dungeon (Kenney, CC0).
# Salas e corredores são retângulos; todo o resto vira parede (só aparece perto do chão).

const TILE := 16
const COLS := 12
const W := 36
const H := 28
const TEXTURE: Texture2D = preload("res://assets/characters/tiny_dungeon.png")

const FLOORS := [48, 48, 48, 48, 49, 42]
const WALL := 40
const WALL_WINDOW := 28
const WALL_BANNER := 29
const BLOCKED := [40, 28, 29, 63, 64, 66]

# Salas: inicial, oeste, centro, leste, sala do chefe.
const ROOMS := [Rect2i(3, 18, 9, 7), Rect2i(3, 5, 9, 8), Rect2i(15, 11, 9, 8), Rect2i(27, 15, 7, 9), Rect2i(22, 2, 12, 7)]
const HALLS := [Rect2i(6, 13, 3, 5), Rect2i(12, 9, 5, 3), Rect2i(24, 15, 4, 3), Rect2i(12, 20, 5, 3), Rect2i(16, 19, 3, 4), Rect2i(29, 9, 3, 6)]
const DOOR_CELL := Vector2i(7, 25)
const START_CELL := Vector2i(7, 22)

const MONSTERS := [
	["slime", Vector2i(5, 8)], ["slime", Vector2i(9, 11)], ["bat", Vector2i(8, 6)],
	["spider", Vector2i(17, 13)], ["slime", Vector2i(21, 14)], ["ghost", Vector2i(20, 17)],
	["bat", Vector2i(29, 17)], ["spider", Vector2i(31, 21)], ["ghost", Vector2i(28, 22)],
	["ogre", Vector2i(28, 5)], ["bat", Vector2i(24, 4)], ["bat", Vector2i(32, 7)]
]
const POTIONS := [Vector2i(10, 9), Vector2i(22, 12), Vector2i(32, 17), Vector2i(24, 6)]
const DECOR := [[66, Vector2i(4, 19)], [66, Vector2i(10, 23)], [63, Vector2i(4, 6)], [64, Vector2i(23, 3)], [64, Vector2i(32, 3)]]

var _floor_cells: Dictionary = {}


func _ready() -> void:
	map_id = "dungeon"
	title = "Masmorra Esquecida"
	world_limit = Rect2(0, 0, W * TILE, H * TILE)
	var start := Vector2(START_CELL.x * TILE + 8, START_CELL.y * TILE + 8)
	spawn_points = {"default": start, "town": start}

	_carve()
	var tile_set := _build_tile_set()
	var ground := _make_layer("Ground", tile_set)
	var objects := _make_layer("Objects", tile_set)
	_paint(ground, objects)
	_spawn_portal()
	_spawn_monsters()
	_spawn_potions()

	# Clima de masmorra: tudo um pouco mais escuro e azulado.
	var mood := CanvasModulate.new()
	mood.color = Color(0.76, 0.72, 0.9)
	add_child(mood)


func _carve() -> void:
	for r in ROOMS:
		_carve_rect(r)
	for h in HALLS:
		_carve_rect(h)
	_floor_cells[DOOR_CELL] = true


func _carve_rect(r: Rect2i) -> void:
	for y in range(r.position.y, r.position.y + r.size.y):
		for x in range(r.position.x, r.position.x + r.size.x):
			_floor_cells[Vector2i(x, y)] = true


func _is_floor(c: Vector2i) -> bool:
	return _floor_cells.has(c)


func _near_floor(c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _floor_cells.has(c + Vector2i(dx, dy)):
				return true
	return false


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 100


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	var source := TileSetAtlasSource.new()
	source.texture = TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, 0)
	var rows := int(TEXTURE.get_height() / TILE)
	for row in rows:
		for col in COLS:
			source.create_tile(Vector2i(col, row))
	var half := TILE / 2.0
	var square := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
	])
	for id in BLOCKED:
		var data := source.get_tile_data(Vector2i(id % COLS, id / COLS), 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	return tile_set


func _make_layer(layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	add_child(layer)
	return layer


func _set_tile(layer: TileMapLayer, cell: Vector2i, id: int) -> void:
	layer.set_cell(cell, 0, Vector2i(id % COLS, id / COLS))


func _paint(ground: TileMapLayer, objects: TileMapLayer) -> void:
	for y in H:
		for x in W:
			var cell := Vector2i(x, y)
			var roll := _hash(x, y)
			if _is_floor(cell):
				_set_tile(ground, cell, FLOORS[roll % FLOORS.size()])
			elif _near_floor(cell):
				var id := WALL
				if _is_floor(cell + Vector2i(0, 1)):
					if roll < 6:
						id = WALL_WINDOW
					elif roll < 12:
						id = WALL_BANNER
				_set_tile(objects, cell, id)
	for d in DECOR:
		_set_tile(objects, d[1], d[0])


func _cell_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + 8, c.y * TILE + 16)


func _spawn_portal() -> void:
	var portal := Portal.new()
	portal.texture = TEXTURE
	portal.frame = 45
	portal.target = "town"
	portal.caption = "Saída"
	portal.position = _cell_pos(DOOR_CELL)
	portal.used.connect(func(t: String) -> void: portal_used.emit(t, map_id))
	add_child(portal)


func _spawn_monsters() -> void:
	for m in MONSTERS:
		var e := Enemy.new()
		e.kind = m[0]
		e.position = _cell_pos(m[1])
		add_child(e)


func _spawn_potions() -> void:
	for c in POTIONS:
		var p := Pickup.new()
		p.texture = TEXTURE
		p.position = _cell_pos(c)
		add_child(p)