class_name GameTheme
extends RefCounted
# Tema visual "fantasia sombria": pedra escura, bordas douradas, texto pergaminho.

const INK := Color("#14101a")
const STONE := Color("#2a2233")
const STONE_LIGHT := Color("#3b3046")
const GOLD := Color("#d4a94a")
const GOLD_DARK := Color("#6e5224")
const GOLD_LIGHT := Color("#f2dc94")
const PARCHMENT := Color("#f0e6c8")
const BLOOD := Color("#b23a34")
const LIFE := Color("#5ac86e")
const MANA := Color("#4a86d8")


static func box(fill: Color, border: Color, border_w: int = 4, radius: int = 10, margin: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func round_button_theme(accent: Color, size: int, margin: int) -> Dictionary:
	var r := size / 2
	var normal := box(STONE, accent, 5, r, margin)
	var hover := box(STONE_LIGHT, GOLD_LIGHT, 5, r, margin)
	var pressed := box(INK, accent, 5, r, margin)
	pressed.shadow_size = 0
	pressed.content_margin_top += 3
	pressed.content_margin_bottom -= 3
	var disabled := box(INK, GOLD_DARK, 5, r, margin)
	return {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled}


static func build() -> Theme:
	var t := Theme.new()

	# Botões retangulares
	var empty := StyleBoxEmpty.new()
	t.set_stylebox("normal", "Button", box(STONE, GOLD, 4, 8, 14))
	t.set_stylebox("hover", "Button", box(STONE_LIGHT, GOLD_LIGHT, 4, 8, 14))
	var pressed := box(INK, GOLD, 4, 8, 14)
	pressed.shadow_size = 0
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", box(INK, GOLD_DARK, 4, 8, 14))
	t.set_stylebox("focus", "Button", empty)
	t.set_color("font_color", "Button", PARCHMENT)
	t.set_color("font_hover_color", "Button", GOLD_LIGHT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_outline_color", "Button", INK)
	t.set_constant("outline_size", "Button", 4)
	t.set_font_size("font_size", "Button", 26)

	# Textos
	t.set_color("font_color", "Label", PARCHMENT)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 6)
	t.set_font_size("font_size", "Label", 24)

	# Painéis
	t.set_stylebox("panel", "PanelContainer", box(Color(STONE.r, STONE.g, STONE.b, 0.94), GOLD, 4, 12, 16))

	# Campo de texto
	var le := box(INK, GOLD_DARK, 3, 6, 10)
	le.shadow_size = 0
	t.set_stylebox("normal", "LineEdit", le)
	var le_focus := box(INK, GOLD, 3, 6, 10)
	le_focus.shadow_size = 0
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_color("font_color", "LineEdit", PARCHMENT)
	t.set_color("caret_color", "LineEdit", GOLD_LIGHT)
	t.set_font_size("font_size", "LineEdit", 26)

	# Sliders
	var track := StyleBoxFlat.new()
	track.bg_color = INK
	track.border_color = GOLD_DARK
	track.set_border_width_all(2)
	track.set_corner_radius_all(6)
	track.content_margin_top = 8
	track.content_margin_bottom = 8
	t.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.set_corner_radius_all(6)
	fill.content_margin_top = 8
	fill.content_margin_bottom = 8
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)

	# Barras
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = INK
	bar_bg.border_color = GOLD_DARK
	bar_bg.set_border_width_all(2)
	bar_bg.set_corner_radius_all(4)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	return t


static func bar_fill(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	return sb