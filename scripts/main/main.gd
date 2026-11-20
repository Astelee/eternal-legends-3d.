extends Node2D

const TOWN_MAP := preload("res://scripts/world/town_map.gd")
const DUNGEON_MAP := preload("res://scripts/world/dungeon_map.gd")
const TUTORIAL_MAP := preload("res://scripts/world/tutorial_map.gd")
const CARD_ART: Texture2D = preload("res://assets/ui/dungeon_cards.png")

# Imagem mostrada na tela de transição (recorte de 128x128 do dungeon_cards.png).
const CARDS := {
	"town": {"region": Rect2(128, 256, 128, 128), "title": "Vila Inicial"},
	"dungeon": {"region": Rect2(384, 256, 128, 128), "title": "Masmorra Esquecida"},
	"tutorial": {"region": Rect2(384, 256, 128, 128), "title": "Ruínas Esquecidas"}
}

@onready var _player: Player = $Player
@onready var _world: Node2D = $World
@onready var _joystick: VirtualJoystick = $UI/Joystick
@onready var _info: Label = $UI/InfoLabel
@onready var _hud: Hud = $UI/Hud

var _map: GameMap
var _tutorial: TutorialController
var _busy: bool = false
var _fade: ColorRect
var _card: TextureRect
var _card_label: Label


func _ready() -> void:
	# O mundo só abre com a classe confirmada pela conta (ou entrada de debug).
	if not Game.class_confirmed:
		set_process(false)
		get_tree().change_scene_to_file.call_deferred("res://scenes/login/login_screen.tscn")
		return
	_player.joystick = _joystick
	_player.set_character_frame(Game.class_frame)
	# Estilo de combate pela classe da conta (permanente): Guerreiro, Arqueiro ou Mago.
	var combat_id := Game.combat_class_id()
	_player.set_combat_class(combat_id)
	_hud.setup_class(combat_id)

	_hud.attack_pressed.connect(_player.attack)
	_hud.skill_pressed.connect(_player.use_skill)
	_hud.revive_pressed.connect(_on_revive_pressed)
	_hud.profile_opened.connect(_joystick.reset_input)

	_player.hp_changed.connect(_hud.set_hp)
	_player.state_changed.connect(_on_player_state_changed)
	_hud.set_hp(_player.hp, _player.max_hp)

	_build_fade()
	get_viewport().size_changed.connect(_on_viewport_resized)
	# Quem ainda não fez o tutorial começa nele; a vila só abre depois de concluí-lo.
	_load_map("tutorial" if not Game.is_tutorial_done() else "town", "default")


func _process(_delta: float) -> void:
	var state_name: String = Player.State.keys()[_player.state]
	_info.text = "%s v%s | %s | FPS: %d" % [Game.GAME_NAME, Game.VERSION, state_name, Engine.get_frames_per_second()]
	_hud.set_skill_cooldown(_player.skill_cooldown_left(), _player.skill_cooldown_total())


# ------------------------------------------------------------------ mapas

func _make_map(id: String) -> GameMap:
	if id == "tutorial":
		return TUTORIAL_MAP.new()
	if id == "dungeon":
		return DUNGEON_MAP.new()
	return TOWN_MAP.new()


func _load_map(id: String, from_id: String) -> void:
	# Trava de segurança: sem tutorial concluído, a vila e a masmorra ficam fechadas.
	if id != "tutorial" and not Game.is_tutorial_done():
		id = "tutorial"
	var map := _make_map(id)
	_world.add_child(map)
	_player.reparent(map, false)
	_player.set_world(map.world_limit)
	_apply_camera(map)
	_player.teleport(map.get_spawn(from_id))
	if _map != null:
		_map.queue_free()
	_map = map
	map.portal_used.connect(_on_portal_used)
	_hud.set_location(map.title)

	if _tutorial != null:
		_tutorial.queue_free()
		_tutorial = null
	if id == "tutorial":
		_tutorial = TutorialController.new()
		add_child(_tutorial)
		_tutorial.setup(_player, _hud, map as TutorialMap, _joystick)


# Ajusta o zoom da câmera ao mapa. Mapas de tela única (tutorial) ficam com a câmera parada,
# centralizada na sala, mesmo em telas mais largas ou mais altas.
func _apply_camera(map: GameMap) -> void:
	var cam := _player.get_node("Camera2D") as Camera2D
	if cam == null:
		return
	cam.zoom = Vector2(map.camera_zoom, map.camera_zoom)
	if not map.camera_fixed:
		return
	var rect := map.world_limit
	var view := get_viewport_rect().size / map.camera_zoom
	var extra_x := maxf(view.x - rect.size.x, 0.0) / 2.0
	var extra_y := maxf(view.y - rect.size.y, 0.0) / 2.0
	cam.limit_left = int(floor(rect.position.x - extra_x))
	cam.limit_right = int(ceil(rect.end.x + extra_x))
	cam.limit_top = int(floor(rect.position.y - extra_y))
	cam.limit_bottom = int(ceil(rect.end.y + extra_y))


func _on_viewport_resized() -> void:
	if _map != null and is_instance_valid(_map):
		_apply_camera(_map)


func _on_portal_used(target: String, from_id: String) -> void:
	if _busy:
		return
	_busy = true
	_player.set_physics_process(false)
	var card: Dictionary = CARDS.get(target, CARDS["town"])
	var atlas := AtlasTexture.new()
	atlas.atlas = CARD_ART
	atlas.region = card["region"]
	_card.texture = atlas
	_card_label.text = card["title"]
	await _fade_to(true)
	_load_map(target, from_id)
	await get_tree().create_timer(0.9).timeout
	await _fade_to(false)
	_player.set_physics_process(true)
	_busy = false


func _fade_to(on: bool) -> void:
	_fade.visible = true
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0 if on else 0.0, 0.3)
	await tw.finished
	if not on:
		_fade.visible = false


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_fade = ColorRect.new()
	_fade.color = Color("#0c0910")
	_fade.visible = false
	_fade.modulate.a = 0.0
	layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_fade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	_card = TextureRect.new()
	_card.custom_minimum_size = Vector2(384, 384)
	_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_card)

	_card_label = Label.new()
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.add_theme_font_size_override("font_size", 34)
	_card_label.add_theme_color_override("font_color", Color("#f2dc94"))
	_card_label.add_theme_color_override("font_outline_color", Color("#14101a"))
	_card_label.add_theme_constant_override("outline_size", 6)
	box.add_child(_card_label)


# ------------------------------------------------------------------ jogador

func _on_revive_pressed() -> void:
	_player.revive()
	_player.teleport(_map.get_spawn("default"))


func _on_player_state_changed(new_state: int) -> void:
	_hud.set_dead(new_state == Player.State.DEAD)