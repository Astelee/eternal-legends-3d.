class_name PixelButton
extends Button
# Botão medieval. GOLD = ação principal, WOOD = secundário, CHIP = filtro (toggle).
# Hover: brilho + varredura de luz + leve ampliação. Clique: pressionamento.
# Carregamento: set_loading(true, "ENTRANDO...") mostra a runa girando.

enum Kind { GOLD, WOOD, CHIP }

var kind: int = Kind.GOLD
var _shine: TextureRect
var _spinner: TextureRect
var _scale_tw: Tween
var _shine_tw: Tween
var _loading: bool = false
var _text_before_loading: String = ""
var _spin_time: float = 0.0
var _sb_normal: StyleBox


func _init(label: String = "", p_kind: int = Kind.GOLD) -> void:
	text = label
	kind = p_kind
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(0, 54 if kind != Kind.CHIP else 38)
	_apply_style()
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	focus_entered.connect(_on_hover.bind(true))
	focus_exited.connect(_on_hover.bind(false))
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)
	resized.connect(_on_resized)


func _ready() -> void:
	_shine = TextureRect.new()
	_shine.texture = LoginTheme.tex("shine")
	_shine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shine.stretch_mode = TextureRect.STRETCH_SCALE
	_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shine.modulate = Color(1, 1, 1, 0.7)
	_shine.visible = false
	add_child(_shine)

	_spinner = LoginTheme.icon("check", 28)
	_spinner.texture = LoginTheme.tex("spinner")
	_spinner.modulate = LoginTheme.BROWN_TEXT if kind == Kind.GOLD else LoginTheme.PARCHMENT
	_spinner.visible = false
	add_child(_spinner)
	set_process(false)
	_on_resized()


func _apply_style() -> void:
	var pad_x: float = 18.0 if kind != Kind.CHIP else 12.0
	var top: float = 8.0 if kind != Kind.CHIP else 4.0
	var bot: float = 12.0 if kind != Kind.CHIP else 8.0
	var prefix: String = "btn_gold" if kind == Kind.GOLD else "btn_wood"
	_sb_normal = LoginTheme.nine(prefix + "_normal", 10, pad_x, top, pad_x, bot)
	add_theme_stylebox_override("normal", _sb_normal)
	add_theme_stylebox_override("hover", LoginTheme.nine(prefix + "_hover", 10, pad_x, top, pad_x, bot))
	add_theme_stylebox_override("pressed", LoginTheme.nine(prefix + "_pressed", 10, pad_x, top + 4.0, pad_x, bot - 4.0))
	add_theme_stylebox_override("disabled", LoginTheme.nine("btn_gold_disabled" if kind == Kind.GOLD else prefix + "_pressed", 10, pad_x, top, pad_x, bot))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if kind == Kind.CHIP:
		# Filtro ativo = placa dourada.
		add_theme_stylebox_override("pressed", LoginTheme.nine("btn_gold_normal", 10, pad_x, top, pad_x, bot))
		add_theme_stylebox_override("hover_pressed", LoginTheme.nine("btn_gold_hover", 10, pad_x, top, pad_x, bot))
		toggle_mode = true

	var dark: bool = kind == Kind.GOLD
	var c_normal: Color = LoginTheme.BROWN_TEXT if dark else LoginTheme.PARCHMENT
	add_theme_color_override("font_color", c_normal)
	add_theme_color_override("font_hover_color", Color("#1b0e04") if dark else LoginTheme.GOLD_LIGHT)
	add_theme_color_override("font_pressed_color", Color("#3a2008") if dark else LoginTheme.PARCHMENT)
	add_theme_color_override("font_hover_pressed_color", Color("#1b0e04"))
	add_theme_color_override("font_focus_color", Color("#1b0e04") if dark else LoginTheme.GOLD_LIGHT)
	add_theme_color_override("font_disabled_color", Color("#5a4a30") if dark else LoginTheme.PARCHMENT_DIM)
	add_theme_color_override("font_outline_color", LoginTheme.INK)
	add_theme_constant_override("outline_size", 0 if dark else 4)
	if kind == Kind.CHIP:
		add_theme_color_override("font_color", LoginTheme.PARCHMENT)
		add_theme_color_override("font_pressed_color", LoginTheme.BROWN_TEXT)
		add_theme_constant_override("outline_size", 0)
	add_theme_font_override("font", LoginTheme.title_font())
	add_theme_font_size_override("font_size", 22 if kind != Kind.CHIP else 16)


func _on_resized() -> void:
	pivot_offset = size / 2.0
	if _shine != null:
		_shine.size = Vector2(maxf(34.0, size.x * 0.14), size.y)
	_place_spinner()


func _on_hover(on: bool) -> void:
	if disabled and not _loading:
		return
	_tween_scale(1.03 if on else 1.0, 0.12)
	if on:
		sweep_shine()


func _on_down() -> void:
	_tween_scale(0.96, 0.06)
	sweep_shine()


func _on_up() -> void:
	_tween_scale(1.03 if is_hovered() else 1.0, 0.1)


func _on_pressed() -> void:
	Audio.play_sfx("click", 0.04)


func _tween_scale(target: float, duration: float) -> void:
	if not Motion.on():
		scale = Vector2.ONE
		return
	if _scale_tw != null:
		_scale_tw.kill()
	_scale_tw = create_tween()
	_scale_tw.tween_property(self, "scale", Vector2(target, target), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# Faixa de luz atravessando o botão da esquerda para a direita.
func sweep_shine() -> void:
	if not Motion.on() or _shine == null or kind == Kind.CHIP:
		return
	if _shine_tw != null:
		_shine_tw.kill()
	_shine.visible = true
	_shine.position = Vector2(-_shine.size.x, 0)
	_shine_tw = create_tween()
	_shine_tw.tween_property(_shine, "position:x", size.x, 0.5).set_trans(Tween.TRANS_SINE)
	_shine_tw.tween_callback(func() -> void: _shine.visible = false)


func set_loading(on: bool, busy_text: String = "") -> void:
	if on == _loading:
		return
	_loading = on
	if on:
		_text_before_loading = text
		text = busy_text
		disabled = true
		# Mantém a aparência normal (dourada) durante o carregamento.
		add_theme_stylebox_override("disabled", _sb_normal)
		add_theme_color_override("font_disabled_color", get_theme_color("font_color"))
		_spin_time = 0.0
		_spinner.visible = true
		_place_spinner()
	else:
		text = _text_before_loading
		disabled = false
		_apply_style()
		_spinner.visible = false
	set_process(on)


func is_loading() -> bool:
	return _loading


func _process(delta: float) -> void:
	# Giro em 8 passos: mantém o aspecto Pixel Art e é leve.
	_spin_time += delta
	_spinner.rotation = floorf(_spin_time / 0.09) * (PI / 4.0)


func _place_spinner() -> void:
	if _spinner == null:
		return
	var font: Font = get_theme_font("font")
	var fs: int = get_theme_font_size("font_size")
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_spinner.size = Vector2(28, 28)
	_spinner.pivot_offset = Vector2(14, 14)
	_spinner.position = Vector2((size.x - tw) / 2.0 - 40.0, (size.y - 28.0) / 2.0 - 2.0)