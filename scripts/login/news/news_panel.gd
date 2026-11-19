class_name NewsPanel
extends PixelPanel
# Painel "ÚLTIMAS ATUALIZAÇÕES" da tela inicial. Recebe os itens por
# set_items(); não sabe de onde vêm (arquivo local hoje, API depois).

signal details_requested(item: Dictionary)
signal history_requested

const MAX_ITEMS := 6
const CHROME_HEIGHT := 190.0  # cabeçalho + divisória + botão + margens

var _body: VBoxContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _status: Label
var _toggle: TextureButton
var _collapsed: bool = false
var _total_items: int = 0


func _init() -> void:
	super(22)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	content.add_child(header)
	var ic := LoginTheme.icon("sparkle", 22, LoginTheme.GOLD)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(ic)
	var title := LoginTheme.label("ÚLTIMAS ATUALIZAÇÕES", 18, LoginTheme.GOLD_LIGHT)
	title.add_theme_font_override("font", LoginTheme.title_font())
	title.add_theme_constant_override("outline_size", 5)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(title)

	_toggle = TextureButton.new()
	_toggle.texture_normal = LoginTheme.tex("icon_chevron_up")
	_toggle.ignore_texture_size = true
	_toggle.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_toggle.custom_minimum_size = Vector2(32, 32)
	_toggle.self_modulate = LoginTheme.PARCHMENT_DIM
	_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_toggle.tooltip_text = "Recolher ou expandir"
	_toggle.pressed.connect(toggle_collapsed)
	_toggle.mouse_entered.connect(func() -> void: _toggle.self_modulate = LoginTheme.GOLD_LIGHT)
	_toggle.mouse_exited.connect(func() -> void: _toggle.self_modulate = LoginTheme.PARCHMENT_DIM)
	header.add_child(_toggle)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	content.add_child(_body)

	_body.add_child(LoginTheme.divider())

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, 160)
	_body.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)

	var all_btn := PixelButton.new("Ver todas as atualizações", PixelButton.Kind.WOOD)
	all_btn.custom_minimum_size = Vector2(0, 44)
	all_btn.add_theme_font_size_override("font_size", 18)
	all_btn.pressed.connect(func() -> void: history_requested.emit())
	_body.add_child(all_btn)

	_status = LoginTheme.label("", 17, LoginTheme.PARCHMENT_DIM)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.visible = false
	_list.add_child(_status)


# Altura total desejada do painel (a lista rola dentro dela).
func set_target_height(total: float) -> void:
	if _collapsed:
		return
	_scroll.custom_minimum_size.y = maxf(110.0, total - CHROME_HEIGHT)


func set_loading() -> void:
	_clear_cards()
	_status.text = "Carregando novidades..."
	_status.visible = true


func set_error(message: String) -> void:
	_clear_cards()
	_status.text = message
	_status.visible = true


func set_items(items: Array) -> void:
	_clear_cards()
	_total_items = items.size()
	if items.is_empty():
		_status.text = "Nenhuma novidade por enquanto. Volte em breve!"
		_status.visible = true
		return
	_status.visible = false
	var shown: int = mini(items.size(), MAX_ITEMS)
	for i in shown:
		var card := NewsCard.new(items[i], true)
		card.details_requested.connect(func(it: Dictionary) -> void: details_requested.emit(it))
		_list.add_child(card)


func toggle_collapsed() -> void:
	set_collapsed(not _collapsed)


func set_collapsed(value: bool) -> void:
	if value == _collapsed:
		return
	_collapsed = value
	Audio.play_sfx("close" if value else "open", 0.03)
	_toggle.texture_normal = LoginTheme.tex("icon_chevron_down" if value else "icon_chevron_up")
	if value:
		if Motion.on():
			var tw := create_tween()
			tw.tween_property(_body, "modulate:a", 0.0, 0.12)
			await tw.finished
		_body.visible = false
	else:
		_body.visible = true
		_body.modulate.a = 0.0
		var tw2 := create_tween()
		tw2.tween_property(_body, "modulate:a", 1.0, Motion.dur(0.18))


func is_collapsed() -> bool:
	return _collapsed


func _clear_cards() -> void:
	for c in _list.get_children():
		if c != _status:
			c.queue_free()