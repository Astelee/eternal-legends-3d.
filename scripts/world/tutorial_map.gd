class_name TutorialMap
extends GameMap
# Mapa exclusivo do tutorial: a "Clareira do Despertar", fora das muralhas da Vila Inicial.
# Uma estrada de oeste a leste liga as estações do tutorial. Quem comanda as etapas
# é o TutorialController; o mapa só oferece o cenário, o marcador e os inimigos.

const TILE := 16
const COLS := 12
const W := 40
const H := 26
const TOWN_TEXTURE: Texture2D = preload("res://assets/tiles/tiny_town.png")
const CHARACTER_TEXTURE: Texture2D = preload("res://assets/characters/tiny_dungeon.png")

# Mesmas peças bloqueantes da vila (árvores, casas, cercas, objetos).
const BLOCKED := [3, 4, 5, 15, 16, 27, 28, 48, 49, 50, 51, 52, 53, 54, 55, 60, 61, 62, 63, 64, 65, 66, 67, 72, 73, 74, 75, 76, 77, 78, 79, 84, 85, 86, 87, 88, 89, 90, 91, 80, 81, 82, 83, 94, 95, 104]

const ROAD_Y := 13
const ROAD_TILE := 43

# Estações do tutorial (em células do mapa).
const POINTS := {
	"start": Vector2i(3, 13),
	"mentor": Vector2i(6, 12),
	"move": Vector2i(12, 13),
	"fight": Vector2i(20, 13),
	"fight_a": Vector2i(21, 10),
	"fight_b": Vector2i(22, 16),
	"skill": Vector2i(28, 13),
	"skill_a": Vector2i(29, 10),
	"skill_b": Vector2i(30, 13),
	"skill_c": Vector2i(29, 16),
	"trial": Vector2i(34, 13),
	"trial_a": Vector2i(35, 10),
	"trial_b": Vector2i(35, 16),
	"potion": Vector2i(31, 13),
	"exit": Vector2i(37, 13)
}

var _marker_node: Node2D
var _has_marker: bool = false


func _ready() -> void:
	map_id = "tutorial"
	title = "Clareira do Despertar"
	world_limit = Rect2(0, 0, TILE * W, TILE * H)
	spawn_points = {"default": cell_pos(POINTS["start"])}

	var tile_set := _build_tile_set()
	var ground := _make_layer("Ground", tile_set)
	var objects := _make_layer("Objects", tile_set)
	_paint_ground(ground)
	_paint_objects(objects)
	_spawn_mentor()

	_marker_node = Node2D.new()
	_marker_node.z_index = 1
	_marker_node.draw.connect(_draw_marker)
	add_child(_marker_node)


func _process(_delta: float) -> void:
	if _has_marker:
		_marker_node.queue_redraw()


# Centro (pés) de uma célula.
func cell_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + 8, c.y * TILE + 16)


# ------------------------------------------------------------------ API do tutorial

func set_marker(pos: Vector2) -> void:
	_has_marker = true
	_marker_node.position = pos
	_marker_node.queue_redraw()


func clear_marker() -> void:
	_has_marker = false
	_marker_node.queue_redraw()


func spawn_enemy(kind: String, cell: Vector2i) -> Enemy:
	var e := Enemy.new()
	e.kind = kind
	e.position = cell_pos(cell)
	add_child(e)
	Fx.sparks(self, e.global_position + Vector2(0, -6), Color("#c9b6ff"), 14.0, 8, 0.35)
	return e


func spawn_potion(cell: Vector2i) -> void:
	var p := Pickup.new()
	p.texture = CHARACTER_TEXTURE
	p.position = cell_pos(cell)
	add_child(p)


# Abre a saída para a Vila Inicial (só depois de concluir o tutorial).
func open_exit() -> void:
	var portal := Portal.new()
	portal.texture = CHARACTER_TEXTURE
	portal.frame = 45
	portal.target = "town"
	portal.caption = "Vila"
	portal.position = cell_pos(POINTS["exit"])
	portal.used.connect(func(t: String) -> void: portal_used.emit(t, map_id))
	add_child(portal)
	Fx.ring(self, portal.global_position + Vector2(0, -6), Color("#f2dc94"), 26.0, 0.6)


# ------------------------------------------------------------------ construção

func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 100


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	var source := TileSetAtlasSource.new()
	source.texture = TOWN_TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, 0)
	var rows := int(TOWN_TEXTURE.get_height() / TILE)
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


func _paint_ground(layer: TileMapLayer) -> void:
	for y in H:
		for x in W:
			var roll := _hash(x, y)
			var id := 0
			if roll < 8:
				id = 1
			elif roll < 14:
				id = 2
			if y == ROAD_Y and x >= 2 and x <= W - 3:
				id = ROAD_TILE
			_set_tile(layer, Vector2i(x, y), id)


func _paint_objects(layer: TileMapLayer) -> void:
	# Borda de árvores (mesmo padrão da vila: 4 em cima, 16 embaixo).
	for x in W:
		_set_tile(layer, Vector2i(x, 0), 4)
		_set_tile(layer, Vector2i(x, 1), 16)
		_set_tile(layer, Vector2i(x, H - 2), 4)
		_set_tile(layer, Vector2i(x, H - 1), 16)
	for y in range(2, H - 2):
		var id := 4 if y % 2 == 0 else 16
		_set_tile(layer, Vector2i(0, y), id)
		_set_tile(layer, Vector2i(W - 1, y), id)
	# Detalhes espalhados (flores e arbustos), longe da faixa de combate.
	for y in range(2, H - 2):
		for x in range(2, W - 2):
			if absi(y - ROAD_Y) <= 4:
				continue
			var roll := _hash(x * 7, y * 3)
			if roll < 5:
				_set_tile(layer, Vector2i(x, y), [27, 28, 29][roll % 3])


func _spawn_mentor() -> void:
	var npc := Npc.new()
	npc.texture = CHARACTER_TEXTURE
	npc.frame = 86
	npc.wander_radius = 8.0
	npc.position = cell_pos(POINTS["mentor"])
	add_child(npc)


func _draw_marker() -> void:
	if not _has_marker:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	var gold := Color(0.95, 0.86, 0.58)
	_marker_node.draw_circle(Vector2.ZERO, 6.0, Color(gold.r, gold.g, gold.b, 0.2 + 0.2 * pulse))
	_marker_node.draw_arc(Vector2.ZERO, 9.0 + pulse * 3.0, 0.0, TAU, 24, Color(gold.r, gold.g, gold.b, 0.9), 1.5)
	var y := -24.0 - pulse * 3.0
	_marker_node.draw_colored_polygon(PackedVector2Array([Vector2(0, y + 8), Vector2(-5, y), Vector2(5, y)]), gold)