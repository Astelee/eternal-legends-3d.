class_name LoginTheme
extends RefCounted
# Identidade visual da tela de login: cores, texturas Pixel Art e estilos.
# As texturas são geradas por tools/gen_login_assets.py (assets/ui/login/).

const DIR := "res://assets/ui/login/"

const INK := Color("#14101a")
const GOLD := Color("#d4a94a")
const GOLD_LIGHT := Color("#f2dc94")
const GOLD_DARK := Color("#6e5224")
const PARCHMENT := Color("#f0e6c8")
const PARCHMENT_DIM := Color("#b9ad92")
const MAGIC := Color("#7cc0ff")
const BLOOD := Color("#ff8a80")
const LIFE := Color("#8be39a")
const BROWN_TEXT := Color("#2b1708")
const PANEL_FILL := Color(0.075, 0.055, 0.13, 0.86)

const FRAME_MARGIN := 18
const PANEL_PAD := 26

# Fonte pixelada opcional: coloque um .ttf/.otf livre (ex.: "Pixelify Sans" ou
# "m6x11", licença OFL) em um destes caminhos e ela passa a ser usada.
const PIXEL_FONT_PATHS := ["res://assets/fonts/pixel.ttf", "res://assets/fonts/pixel.otf"]

static var _cache: Dictionary = {}
static var _title_font: Font = null


static func tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var t: Texture2D = load(DIR + id + ".png")
	_cache[id] = t
	return t


static func icon(id: String, px: float = 24.0, tint: Color = Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex("icon_" + id)
	r.custom_minimum_size = Vector2(px, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate = tint
	return r


# StyleBox 9-patch a partir de uma textura. "margin" é em pixels da textura.
static func nine(id: String, margin: int, cl: float, ct: float, cr: float, cb: float, draw_center: bool = true) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(id)
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = cl
	sb.content_margin_top = ct
	sb.content_margin_right = cr
	sb.content_margin_bottom = cb
	sb.draw_center = draw_center
	return sb


static func custom_font() -> Font:
	for p in PIXEL_FONT_PATHS:
		if ResourceLoader.exists(p):
			return load(p)
	return null


# Fonte de títulos: a pixelada, se existir; senão a padrão em negrito.
static func title_font() -> Font:
	if _title_font != null:
		return _title_font
	var base: Font = custom_font()
	if base != null:
		_title_font = base
	else:
		var fv := FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.6
		_title_font = fv
	return _title_font


# Divisória ornamentada (linha - losango - linha).
static func divider() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		if i == 1:
			var d := TextureRect.new()
			d.texture = tex("diamond")
			d.custom_minimum_size = Vector2(18, 18)
			d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(d)
		else:
			var line := ColorRect.new()
			line.color = GOLD_DARK
			line.custom_minimum_size = Vector2(0, 3)
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(line)
	return row


# Link de texto com mudança de cor ao passar o mouse.
static func link(text: String, size: int = 18) -> LinkButton:
	var b := LinkButton.new()
	b.text = text
	b.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_color_override("font_color", MAGIC)
	b.add_theme_color_override("font_hover_color", GOLD_LIGHT)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD_LIGHT)
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 3)
	b.add_theme_font_size_override("font_size", size)
	return b


static func label(text: String, size: int = 20, color: Color = PARCHMENT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func build_theme() -> Theme:
	var t := Theme.new()
	var f: Font = custom_font()
	if f != null:
		t.default_font = f
	t.default_font_size = 20

	t.set_color("font_color", "Label", PARCHMENT)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 3)
	t.set_font_size("font_size", "Label", 20)

	t.set_color("default_color", "RichTextLabel", PARCHMENT)
	t.set_color("font_outline_color", "RichTextLabel", INK)
	t.set_constant("outline_size", "RichTextLabel", 3)
	t.set_font_size("normal_font_size", "RichTextLabel", 18)
	t.set_font_size("bold_font_size", "RichTextLabel", 18)

	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)

	# Barras de rolagem em madeira/ouro
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.38)
	track.content_margin_left = 6
	track.content_margin_right = 6
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var grab := StyleBoxFlat.new()
	grab.bg_color = GOLD_DARK
	grab.border_color = INK
	grab.set_border_width_all(2)
	grab.content_margin_left = 6
	grab.content_margin_right = 6
	var grab_hi := grab.duplicate() as StyleBoxFlat
	grab_hi.bg_color = GOLD
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, track)
		t.set_stylebox("scroll_focus", bar, track)
		t.set_stylebox("grabber", bar, grab)
		t.set_stylebox("grabber_highlight", bar, grab_hi)
		t.set_stylebox("grabber_pressed", bar, grab_hi)
	return t