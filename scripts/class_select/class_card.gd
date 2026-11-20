class_name ClassCard
extends PanelContainer
# Cartão de uma classe na tela "Escolha seu destino": ilustração animada,
# nome em destaque, descrição curta e efeito visual quando selecionado.

signal chosen(class_id: String)

const CHAR_TEX: Texture2D = preload("res://assets/characters/tiny_dungeon.png")
const COLS := 12
const FRAME := 16

const DETAILS := {
	"warrior": {
		"tag": "Combate corpo a corpo",
		"desc": "Combatente especializado em combate corpo a corpo, com espada, armadura e grande resistência.",
		"accent": Color("#e0605a")
	},
	"archer": {
		"tag": "Ataque à distância",
		"desc": "Especialista em ataques à distância, utilizando arco e flechas, com agilidade e precisão.",
		"accent": Color("#5ac86e")
	},
	"mage": {
		"tag": "Poder mágico",
		"desc": "Especialista em magia, utilizando cajado e poderes mágicos para atacar os inimigos.",
		"accent": Color("#4a86d8")
	}
}

var class_id: String = ""
var class_title: String = ""
var frame: int = 0
var accent: Color = GameTheme.GOLD

var _compact: bool = false
var _selected: bool = false
var _dimmed: bool = false
var _glow: float = 0.0
var _time: float = 0.0
var _phase: float = 0.0

var _inner: BoxContainer
var _art: Control
var _name_label: Label
var _tag_label: Label
var _desc_label: Label
var _glow_tween: Tween
var _scale_tween: Tween


func _init(class_data: Dictionary) -> void:
	class_id = str(class_data["id"])
	class_title = str(class_data["name"])
	frame = int(class_data["frame"])
	var details: Dictionary = DETAILS.get(class_id, {})
	accent = details.get("accent", GameTheme.GOLD)
	_phase = float(frame % 7) * 0.9


func _ready() -> void:
	var details: Dictionary = DETAILS.get(class_id, {})
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_on_gui_input)
	resized.connect(func() -> void: pivot_offset = size / 2.0)

	_inner = BoxContainer.new()
	_inner.add_theme_constant_override("separation", 12)
	add_child(_inner)

	_art = Control.new()
	_art.custom_minimum_size = Vector2(120, 120)
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_art.draw.connect(_draw_art)
	_inner.add_child(_art)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override("separation", 6)
	_inner.add_child(texts)

	_name_label = Label.new()
	_name_label.text = class_title
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 40)
	_name_label.add_theme_color_override("font_color", accent.lightened(0.25))
	texts.add_child(_name_label)

	_tag_label = Label.new()
	_tag_label.text = str(details.get("tag", ""))
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag_label.add_theme_font_size_override("font_size", 20)
	_tag_label.add_theme_color_override("font_color", GameTheme.GOLD)
	texts.add_child(_tag_label)

	_desc_label = Label.new()
	_desc_label.text = str(details.get("desc", ""))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.custom_minimum_size = Vector2(0, 0)
	_desc_label.add_theme_font_size_override("font_size", 21)
	texts.add_child(_desc_label)

	_set_mouse_ignore(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_style()
	set_compact(_compact)


# Layout horizontal (retrato: arte à esquerda, texto à direita) ou vertical (paisagem).
func set_compact(compact: bool) -> void:
	_compact = compact
	if _inner == null:
		return
	_inner.vertical = not compact
	_art.custom_minimum_size = Vector2(130, 130) if compact else Vector2(120, 120)
	_desc_label.add_theme_font_size_override("font_size", 19 if compact else 21)
	_name_label.add_theme_font_size_override("font_size", 34 if compact else 40)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if compact else HORIZONTAL_ALIGNMENT_CENTER
	_tag_label.horizontal_alignment = _name_label.horizontal_alignment
	_desc_label.horizontal_alignment = _name_label.horizontal_alignment


# selected: este cartão está escolhido. dimmed: outro cartão está escolhido.
func set_state(selected: bool, dimmed: bool) -> void:
	_selected = selected
	_dimmed = dimmed
	_apply_style()
	modulate = Color(0.72, 0.72, 0.78) if dimmed else Color.WHITE

	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.tween_property(self, "_glow", 1.0 if selected else 0.0, Motion.dur(0.25))
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", Vector2.ONE * (1.03 if selected else 1.0), Motion.dur(0.18))
	if not Motion.on():
		_glow = 1.0 if selected else 0.0
	_art.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if Motion.on() or _glow > 0.0:
		_art.queue_redraw()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(class_id)


func _apply_style() -> void:
	var border := accent if _selected else GameTheme.GOLD_DARK
	var fill := Color("#2e2538") if _selected else Color("#1d1824")
	var sb := GameTheme.box(fill, border, 6 if _selected else 3, 14, 14)
	if _selected:
		sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.55)
		sb.shadow_size = 18
		sb.shadow_offset = Vector2.ZERO
	add_theme_stylebox_override("panel", sb)


func _set_mouse_ignore(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore(child)


# ------------------------------------------------------------------ ilustração

func _frame_rect(index: int) -> Rect2:
	return Rect2((index % COLS) * FRAME, (index / COLS) * FRAME, FRAME, FRAME)


func _draw_art() -> void:
	var sz := _art.size
	if sz.x < 10.0 or sz.y < 10.0:
		return
	var animate := Motion.on()
	var t := _time + _phase
	# Escala inteira para manter o pixel art nítido.
	var k := maxf(floorf(minf(sz.x, sz.y) / 22.0), 3.0)
	var feet := Vector2(sz.x / 2.0, sz.y / 2.0 + 8.0 * k)
	var bob := 0.0
	if animate:
		bob = -absf(sin(t * (4.0 if _selected else 1.6))) * k * (1.6 if _selected else 0.5)

	# Aura da classe (só quando selecionada)
	if _glow > 0.01:
		var center := feet + Vector2(0, -8.0 * k)
		for i in 3:
			var r := k * (11.0 + i * 3.0 + (sin(t * 3.0) * 1.2 if animate else 0.0))
			draw_circle_on_art(center, r, Color(accent.r, accent.g, accent.b, 0.10 * _glow))
		var spin := t * 1.2 if animate else 0.0
		for i in 6:
			var a := spin + i * TAU / 6.0
			_art.draw_arc(center, k * 12.5, a, a + 0.55, 10, Color(accent.r, accent.g, accent.b, 0.85 * _glow), maxf(k * 0.45, 2.0))

	# Sombra no chão
	_art.draw_set_transform(feet + Vector2(0, 1), 0.0, Vector2(1.0, 0.35))
	_art.draw_circle(Vector2.ZERO, 6.0 * k, Color(0, 0, 0, 0.4))

	# Corpo
	_art.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var body_pos := feet + Vector2(-8.0 * k, -16.0 * k + bob)
	_art.draw_texture_rect_region(CHAR_TEX, Rect2(body_pos, Vector2(FRAME, FRAME) * k), _frame_rect(frame))

	# Arma (mesmo ponto de giro usado no jogo)
	var weapon_frame: int = Player.WEAPON_FRAMES.get(frame, 104)
	var swing := 0.35
	if _selected and animate:
		swing = 0.35 + sin(t * 5.0) * 0.7
	elif animate:
		swing = 0.35 + sin(t * 1.6) * 0.08
	var pivot := feet + Vector2(6.0 * k, -6.0 * k + bob)
	_art.draw_set_transform(pivot, swing, Vector2.ONE)
	_art.draw_texture_rect_region(CHAR_TEX, Rect2(Vector2(-8.0, -12.0) * k, Vector2(FRAME, FRAME) * k), _frame_rect(weapon_frame))
	_art.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_circle_on_art(center: Vector2, radius: float, color: Color) -> void:
	_art.draw_circle(center, radius, color)