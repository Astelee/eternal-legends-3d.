class_name TutorialMap
extends GameMap
# Mapa do tutorial: as Ruínas Esquecidas, em seis salas ilustradas (assets/tutorial/room_01..06.png).
# Cada sala é uma tela só: a câmera fica parada e o jogador anda pela área marcada em ROOMS.
# Quem comanda as etapas é o TutorialController; o mapa oferece o cenário, as paredes,
# o portão de saída de cada sala, o marcador dourado e a criação de inimigos e frascos.
#
# As coordenadas de ROOMS seguem a imagem de 1456 x 819 pontos; K converte para o mundo (640 x 360).

signal room_changed(index: int)

const K := 640.0 / 1456.0
const BG_PATH := "res://assets/tutorial/room_%02d.png"
const CHARACTER_TEXTURE: Texture2D = preload("res://assets/characters/tiny_dungeon.png")
const FADE_COLOR := Color("#0c0910")

# walk = área onde se pode andar; holes = obstáculos dentro dela; gate = saída da sala;
# points = lugares usados pelo tutorial (marcador, inimigos, frascos).
const ROOMS := [
	{
		"title": "Entrada das Ruínas",
		"walk": [Vector2(655, 300), Vector2(805, 300), Vector2(812, 372), Vector2(880, 398), Vector2(1005, 398), Vector2(1060, 378), Vector2(1130, 400), Vector2(1165, 445), Vector2(1150, 495), Vector2(1080, 512), Vector2(1000, 535), Vector2(945, 545), Vector2(945, 560), Vector2(825, 570), Vector2(825, 819), Vector2(645, 819), Vector2(645, 570), Vector2(550, 560), Vector2(550, 540), Vector2(470, 525), Vector2(390, 500), Vector2(330, 470), Vector2(350, 430), Vector2(400, 405), Vector2(470, 395), Vector2(560, 396), Vector2(600, 372), Vector2(650, 372)],
		"holes": [],
		"spawn": Vector2(735, 760),
		"gate": {"pos": Vector2(730, 325), "size": Vector2(150, 44), "target": 2, "caption": "Portão"},
		"points": {"move": Vector2(735, 500), "mentor": Vector2(650, 455)}
	},
	{
		"title": "Pátio dos Primeiros Inimigos",
		"walk": [Vector2(560, 232), Vector2(655, 215), Vector2(655, 120), Vector2(745, 120), Vector2(745, 215), Vector2(815, 235), Vector2(900, 300), Vector2(1000, 320), Vector2(1090, 330), Vector2(1150, 345), Vector2(1230, 360), Vector2(1230, 560), Vector2(1000, 575), Vector2(955, 640), Vector2(950, 819), Vector2(705, 819), Vector2(700, 640), Vector2(660, 640), Vector2(612, 625), Vector2(600, 560), Vector2(570, 520), Vector2(540, 470), Vector2(450, 450), Vector2(400, 430), Vector2(330, 380), Vector2(300, 330), Vector2(340, 300), Vector2(420, 260)],
		"holes": [[Vector2(930, 420), Vector2(1060, 395), Vector2(1135, 395), Vector2(1135, 455), Vector2(1230, 455), Vector2(1230, 535), Vector2(1130, 535), Vector2(1100, 500), Vector2(930, 500)]],
		"spawn": Vector2(830, 775),
		"gate": {"pos": Vector2(700, 160), "size": Vector2(110, 44), "target": 3, "caption": "Passagem"},
		"points": {"fight": Vector2(780, 440), "fight_a": Vector2(600, 390), "fight_b": Vector2(900, 350), "skill": Vector2(780, 470), "skill_a": Vector2(560, 430), "skill_b": Vector2(780, 330), "skill_c": Vector2(960, 370), "potion": Vector2(700, 560), "potion2": Vector2(520, 380)}
	},
	{
		"title": "Corredores Subterrâneos",
		"walk": [Vector2(200, 150), Vector2(330, 150), Vector2(330, 350), Vector2(1050, 350), Vector2(1050, 300), Vector2(1400, 300), Vector2(1400, 430), Vector2(840, 430), Vector2(840, 575), Vector2(810, 575), Vector2(810, 665), Vector2(590, 665), Vector2(590, 575), Vector2(500, 575), Vector2(500, 430), Vector2(60, 430), Vector2(60, 350), Vector2(200, 350)],
		"holes": [],
		"spawn": Vector2(265, 210),
		"gate": {"pos": Vector2(700, 645), "size": Vector2(150, 40), "target": 4, "caption": "Portão"},
		"points": {"trial": Vector2(700, 500), "a": Vector2(500, 390), "b": Vector2(900, 385), "c": Vector2(700, 500), "potion": Vector2(640, 500), "potion2": Vector2(1000, 395)}
	},
	{
		"title": "Salão dos Guardiões",
		"walk": [Vector2(250, 500), Vector2(300, 455), Vector2(440, 440), Vector2(570, 435), Vector2(645, 430), Vector2(645, 300), Vector2(830, 300), Vector2(830, 430), Vector2(890, 435), Vector2(1020, 440), Vector2(1150, 455), Vector2(1210, 500), Vector2(1230, 560), Vector2(1190, 590), Vector2(1090, 585), Vector2(975, 590), Vector2(960, 640), Vector2(860, 640), Vector2(860, 819), Vector2(595, 819), Vector2(595, 640), Vector2(480, 640), Vector2(470, 590), Vector2(360, 585), Vector2(280, 570)],
		"holes": [],
		"spawn": Vector2(730, 775),
		"gate": {"pos": Vector2(738, 335), "size": Vector2(150, 44), "target": 5, "caption": "Portal"},
		"points": {"a": Vector2(500, 520), "b": Vector2(960, 520), "guardian": Vector2(730, 500), "center": Vector2(730, 520), "potion": Vector2(420, 510), "potion2": Vector2(1040, 510)}
	},
	{
		"title": "Arena do Chefe",
		"walk": [Vector2(1335, 515), Vector2(1333, 527), Vector2(1326, 539), Vector2(1315, 551), Vector2(1299, 563), Vector2(1279, 574), Vector2(1255, 585), Vector2(1226, 595), Vector2(1195, 605), Vector2(1159, 614), Vector2(1121, 622), Vector2(1079, 630), Vector2(1035, 636), Vector2(989, 642), Vector2(940, 647), Vector2(890, 650), Vector2(860, 650), Vector2(860, 819), Vector2(600, 819), Vector2(600, 650), Vector2(580, 650), Vector2(530, 647), Vector2(481, 642), Vector2(435, 636), Vector2(391, 630), Vector2(349, 622), Vector2(311, 614), Vector2(275, 605), Vector2(244, 595), Vector2(215, 585), Vector2(191, 574), Vector2(171, 563), Vector2(155, 551), Vector2(144, 539), Vector2(137, 527), Vector2(135, 515), Vector2(137, 503), Vector2(144, 491), Vector2(155, 479), Vector2(171, 467), Vector2(191, 456), Vector2(215, 445), Vector2(244, 435), Vector2(275, 425), Vector2(311, 416), Vector2(349, 408), Vector2(391, 400), Vector2(435, 394), Vector2(481, 388), Vector2(530, 383), Vector2(580, 380), Vector2(645, 385), Vector2(645, 290), Vector2(825, 290), Vector2(825, 385), Vector2(890, 380), Vector2(940, 383), Vector2(989, 388), Vector2(1035, 394), Vector2(1079, 400), Vector2(1121, 408), Vector2(1159, 416), Vector2(1195, 425), Vector2(1226, 435), Vector2(1255, 445), Vector2(1279, 456), Vector2(1299, 467), Vector2(1315, 479), Vector2(1326, 491), Vector2(1333, 503)],
		"holes": [],
		"spawn": Vector2(730, 770),
		"gate": {"pos": Vector2(735, 330), "size": Vector2(150, 44), "target": 6, "caption": "Câmara"},
		"points": {"boss": Vector2(735, 470), "center": Vector2(735, 540), "potion": Vector2(330, 550), "potion2": Vector2(1140, 550)}
	},
	{
		"title": "Câmara Final",
		"walk": [Vector2(610, 819), Vector2(610, 700), Vector2(560, 695), Vector2(545, 640), Vector2(470, 615), Vector2(430, 590), Vector2(420, 525), Vector2(450, 505), Vector2(610, 500), Vector2(615, 400), Vector2(845, 400), Vector2(850, 500), Vector2(1010, 505), Vector2(1040, 525), Vector2(1030, 590), Vector2(990, 615), Vector2(915, 640), Vector2(900, 695), Vector2(850, 700), Vector2(850, 819)],
		"holes": [],
		"spawn": Vector2(730, 775),
		"gate": null,
		"points": {"boss": Vector2(730, 510), "center": Vector2(730, 560), "exit": Vector2(730, 440), "potion": Vector2(500, 550), "potion2": Vector2(960, 550)}
	}
]

var room_index: int = 1
var transitioning: bool = false

var _room_nodes: Array = []
var _gate: RoomGate
var _points: Dictionary = {}
var _room_spawn: Vector2 = Vector2.ZERO
var _fade: ColorRect
var _marker_node: Node2D
var _has_marker: bool = false


func _ready() -> void:
	map_id = "tutorial"
	title = "Ruínas Esquecidas"
	world_limit = Rect2(0, 0, 640, 360)
	camera_zoom = 2.0
	camera_fixed = true

	# Fundo escuro para telas mais largas que a sala.
	var backdrop := Polygon2D.new()
	backdrop.color = FADE_COLOR
	backdrop.polygon = PackedVector2Array([Vector2(-1200, -900), Vector2(1840, -900), Vector2(1840, 1260), Vector2(-1200, 1260)])
	backdrop.z_index = -200
	add_child(backdrop)

	_marker_node = Node2D.new()
	_marker_node.z_index = 6
	_marker_node.draw.connect(_draw_marker)
	add_child(_marker_node)

	# Escurecimento usado na troca de sala.
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 9
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = FADE_COLOR
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	fade_layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_room(1)


func _process(_delta: float) -> void:
	if _has_marker:
		_marker_node.queue_redraw()


func _w(p: Vector2) -> Vector2:
	return p * K


# ------------------------------------------------------------------ API do tutorial

# Lugar nomeado da sala atual, em coordenadas do mundo.
func point(point_name: String) -> Vector2:
	var p: Vector2 = _points.get(point_name, Vector2.ZERO)
	return _w(p)


func gate_position() -> Vector2:
	if _gate != null and is_instance_valid(_gate):
		return _gate.position
	return Vector2.ZERO


func set_marker(pos: Vector2) -> void:
	_has_marker = true
	_marker_node.position = pos
	_marker_node.queue_redraw()


func clear_marker() -> void:
	_has_marker = false
	_marker_node.queue_redraw()


func spawn_enemy(kind: String, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.kind = kind
	e.position = pos
	add_child(e)
	_room_nodes.append(e)
	Fx.sparks(self, e.global_position + Vector2(0, -6), Color("#c9b6ff"), 14.0, 8, 0.35)
	return e


func spawn_potion(pos: Vector2) -> void:
	var p := Pickup.new()
	p.texture = CHARACTER_TEXTURE
	p.position = pos
	add_child(p)
	_room_nodes.append(p)


# Abre o portão da sala (o jogador pode seguir para a próxima).
func unlock_gate() -> void:
	if _gate != null and is_instance_valid(_gate):
		_gate.set_locked(false)
		Fx.ring(self, _gate.position, Color("#f2dc94"), 26.0, 0.6)
		Audio.play_sfx("open")


# Fim do tutorial: abre o portal para a Vila Inicial na última sala.
func open_exit() -> void:
	var gate := RoomGate.new()
	gate.gate_size = Vector2(54.0, 18.0)
	gate.target = "town"
	gate.caption = "Vila Inicial"
	gate.locked = false
	gate.position = point("exit")
	gate.used.connect(_on_gate_used)
	add_child(gate)
	_room_nodes.append(gate)
	_gate = gate
	Fx.ring(self, gate.position, Color("#f2dc94"), 30.0, 0.6)


# Troca de sala com escurecimento. O controlador espera por room_index e transitioning.
func change_room(index: int) -> void:
	if transitioning or index < 1 or index > ROOMS.size():
		return
	transitioning = true
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.set_physics_process(false)
	clear_marker()

	var fade_out := create_tween()
	fade_out.tween_property(_fade, "modulate:a", 1.0, 0.35)
	await fade_out.finished

	_clear_room()
	_build_room(index)
	await get_tree().process_frame
	if player != null:
		player.teleport(_room_spawn)
	await get_tree().create_timer(0.25).timeout

	var fade_in := create_tween()
	fade_in.tween_property(_fade, "modulate:a", 0.0, 0.35)
	await fade_in.finished

	if player != null:
		player.set_physics_process(true)
	transitioning = false
	room_changed.emit(index)


# ------------------------------------------------------------------ construção das salas

func _clear_room() -> void:
	for n in _room_nodes:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_room_nodes.clear()
	_gate = null


func _build_room(index: int) -> void:
	room_index = index
	var room: Dictionary = ROOMS[index - 1]
	title = str(room["title"])
	_points = room["points"]
	var sp: Vector2 = room["spawn"]
	_room_spawn = _w(sp)
	spawn_points = {"default": _room_spawn}

	# Fundo ilustrado (1280 x 720, mostrado na metade do tamanho: a câmera usa zoom 2).
	var bg := Sprite2D.new()
	var path := BG_PATH % index
	if ResourceLoader.exists(path):
		bg.texture = load(path) as Texture2D
	bg.centered = false
	bg.scale = Vector2(0.5, 0.5)
	bg.z_index = -100
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(bg)
	_room_nodes.append(bg)

	# Paredes invisíveis: o contorno da área andável e dos obstáculos.
	var wall := StaticBody2D.new()
	add_child(wall)
	_room_nodes.append(wall)
	var walk: Array = room["walk"]
	_add_loop(wall, walk)
	var holes: Array = room["holes"]
	for h in holes:
		var hole: Array = h
		_add_loop(wall, hole)

	# Portão de saída (trancado até o tutorial liberar).
	_gate = null
	if room["gate"] != null:
		var g: Dictionary = room["gate"]
		var gp: Vector2 = g["pos"]
		var gs: Vector2 = g["size"]
		var gate := RoomGate.new()
		gate.gate_size = gs * K
		gate.position = _w(gp)
		gate.target = "room:%d" % int(g["target"])
		gate.caption = str(g["caption"])
		gate.locked = true
		gate.used.connect(_on_gate_used)
		add_child(gate)
		_room_nodes.append(gate)
		_gate = gate

	if index == 1:
		_spawn_mentor()


func _add_loop(body: StaticBody2D, pts: Array) -> void:
	var poly := PackedVector2Array()
	for p in pts:
		var v: Vector2 = p
		poly.append(v * K)
	var shape := CollisionPolygon2D.new()
	shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	shape.polygon = poly
	body.add_child(shape)


func _spawn_mentor() -> void:
	var npc := Npc.new()
	npc.texture = CHARACTER_TEXTURE
	npc.frame = 86
	npc.wander_radius = 8.0
	npc.position = point("mentor")
	add_child(npc)
	_room_nodes.append(npc)


func _on_gate_used(target: String) -> void:
	if target.begins_with("room:"):
		change_room(int(target.substr(5)))
	else:
		portal_used.emit(target, map_id)


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