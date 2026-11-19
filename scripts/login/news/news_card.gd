class_name NewsCard
extends PanelContainer
# Cartão de uma notícia: faixa colorida da categoria, selo, data, título,
# resumo e botão "Ver detalhes". Não conhece a origem dos dados.

signal details_requested(item: Dictionary)

var item: Dictionary
var _sb: StyleBoxFlat


func _init(p_item: Dictionary, compact: bool = true) -> void:
	item = p_item
	var info: Dictionary = NewsCategories.info(str(item["category"]))
	var accent: Color = info["color"]

	_sb = StyleBoxFlat.new()
	_sb.bg_color = Color(0.04, 0.03, 0.09, 0.74)
	_sb.border_color = LoginTheme.GOLD_DARK
	_sb.set_border_width_all(2)
	add_theme_stylebox_override("panel", _sb)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_on_exit)
	gui_input.connect(_on_gui_input)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	add_child(row)

	var stripe := ColorRect.new()
	stripe.color = accent
	stripe.custom_minimum_size = Vector2(6, 0)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(stripe)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	var top := HFlowContainer.new()
	top.add_theme_constant_override("h_separation", 8)
	top.add_theme_constant_override("v_separation", 4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(category_chip(str(item["category"])))
	if bool(item["is_demo"]):
		top.add_child(demo_chip())
	var date_label := LoginTheme.label(NewsRepository.format_date(str(item["published_at"])), 15, LoginTheme.PARCHMENT_DIM)
	top.add_child(date_label)
	col.add_child(top)

	var title := LoginTheme.label(str(item["title"]), 19, LoginTheme.GOLD_LIGHT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if compact:
		title.max_lines_visible = 2
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(title)

	var summary_text: String = str(item["summary"])
	if summary_text != "":
		var summary := LoginTheme.label(summary_text, 16, LoginTheme.PARCHMENT)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if compact:
			summary.max_lines_visible = 3
			summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(summary)

	var more := LoginTheme.link("Ver detalhes", 16)
	more.size_flags_horizontal = Control.SIZE_SHRINK_END
	more.pressed.connect(func() -> void:
		Audio.play_sfx("click", 0.04)
		details_requested.emit(item))
	col.add_child(more)


static func category_chip(category: String) -> PanelContainer:
	var info: Dictionary = NewsCategories.info(category)
	var accent: Color = info["color"]
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 0.95)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.content_margin_left = 6
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(h)
	var ic := LoginTheme.icon(str(info["icon"]), 16, accent)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	h.add_child(LoginTheme.label(str(info["label"]), 14, accent))
	return chip


# Selo que identifica conteúdo demonstrativo (nunca mostrar como notícia real).
static func demo_chip() -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.2, 0.05, 0.95)
	sb.border_color = LoginTheme.GOLD
	sb.set_border_width_all(2)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", sb)
	chip.add_child(LoginTheme.label("EXEMPLO", 14, LoginTheme.GOLD_LIGHT))
	return chip


func _set_hover(on: bool) -> void:
	_sb.bg_color = Color(0.09, 0.07, 0.17, 0.86) if on else Color(0.04, 0.03, 0.09, 0.74)
	_sb.border_color = LoginTheme.GOLD if on else LoginTheme.GOLD_DARK


func _on_exit() -> void:
	# O botão interno "Ver detalhes" também dispara mouse_exited; ignora esse caso.
	if get_global_rect().has_point(get_global_mouse_position()):
		return
	_set_hover(false)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			Audio.play_sfx("click", 0.04)
			details_requested.emit(item)