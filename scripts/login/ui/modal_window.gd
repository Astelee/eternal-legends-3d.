class_name ModalWindow
extends Control
# Janela temática sobre a tela: fundo escurecido, painel com moldura dourada,
# cabeçalho com botão de fechar, corpo rolável e rodapé.
# Subclasses adicionam conteúdo em `body` (e botões em `footer`).

signal closed

var panel: PixelPanel
var body: VBoxContainer
var footer: HBoxContainer
var window_width: float = 560.0
var title_text: String = ""
var close_on_dim: bool = true

var _dim: ColorRect
var _center: CenterContainer
var _scroll: ScrollContainer
var _header: HBoxContainer
var _title_label: Label
var _closing: bool = false
var _fit_queued: bool = false


func _init(title: String, width: float = 560.0) -> void:
	title_text = title
	window_width = width
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.01, 0.06, 0.66)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)

	panel = PixelPanel.new()
	panel.custom_minimum_size = Vector2(width, 0)
	_center.add_child(panel)
	panel.resized.connect(func() -> void: panel.pivot_offset = panel.size / 2.0)

	_header = HBoxContainer.new()
	panel.content.add_child(_header)
	_title_label = LoginTheme.label(title, 30, LoginTheme.GOLD_LIGHT)
	_title_label.add_theme_font_override("font", LoginTheme.title_font())
	_title_label.add_theme_constant_override("outline_size", 6)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_header.add_child(_title_label)

	var close_btn := PixelButton.new("", PixelButton.Kind.WOOD)
	close_btn.custom_minimum_size = Vector2(46, 46)
	close_btn.tooltip_text = "Fechar"
	var x_icon := LoginTheme.icon("close", 22, LoginTheme.PARCHMENT)
	x_icon.position = Vector2(12, 11)
	x_icon.size = Vector2(22, 22)
	close_btn.add_child(x_icon)
	close_btn.pressed.connect(close)
	_header.add_child(close_btn)

	panel.content.add_child(LoginTheme.divider())

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	panel.content.add_child(_scroll)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(body)

	footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	panel.content.add_child(footer)

	resized.connect(_queue_fit)
	body.minimum_size_changed.connect(_queue_fit)


# Altera o título exibido no cabeçalho.
func set_title(value: String) -> void:
	title_text = value
	_title_label.text = value


func open() -> void:
	Audio.play_sfx("open", 0.03)
	_dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	_fit()
	# Dois quadros para o texto com quebra de linha assumir a largura real.
	await get_tree().process_frame
	await get_tree().process_frame
	_fit()
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.94, 0.94) if Motion.on() else Vector2.ONE
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 1.0, Motion.dur(0.18))
	tw.tween_property(panel, "modulate:a", 1.0, Motion.dur(0.2))
	tw.tween_property(panel, "scale", Vector2.ONE, Motion.dur(0.22)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	on_opened()


# Gancho para subclasses (ex.: focar o primeiro campo).
func on_opened() -> void:
	pass


func close() -> void:
	if _closing:
		return
	_closing = true
	Audio.play_sfx("close", 0.03)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 0.0, Motion.dur(0.15))
	tw.tween_property(panel, "modulate:a", 0.0, Motion.dur(0.15))
	tw.tween_property(panel, "scale", Vector2(0.96, 0.96) if Motion.on() else Vector2.ONE, Motion.dur(0.15))
	await tw.finished
	closed.emit()
	queue_free()


func _on_dim_input(event: InputEvent) -> void:
	if not close_on_dim:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			close()


func _queue_fit() -> void:
	if _fit_queued:
		return
	_fit_queued = true
	_fit.call_deferred()


# Ajusta largura e altura máxima ao tamanho da tela; o corpo rola quando passa disso.
func _fit() -> void:
	_fit_queued = false
	if not is_inside_tree():
		return
	var w: float = minf(window_width, maxf(280.0, size.x - 24.0))
	panel.custom_minimum_size.x = w
	var avail_h: float = size.y - 32.0
	var chrome: float = _header.get_combined_minimum_size().y
	chrome += footer.get_combined_minimum_size().y + 3.0 * 12.0 + 18.0 + 2.0 * LoginTheme.PANEL_PAD
	var content_h: float = body.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = clampf(content_h, 60.0, maxf(120.0, avail_h - chrome))