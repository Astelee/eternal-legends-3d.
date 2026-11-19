class_name PixelCheck
extends VBoxContainer
# Caixa de seleção medieval. O texto aceita BBCode, inclusive links:
#   "Li e aceito os [url=terms]Termos de Serviço[/url]"
# O clique no link emite link_clicked(id) e NÃO alterna a caixa.

signal toggled(on: bool)
signal link_clicked(id: String)

var checked: bool = false : set = set_checked

var _row: HBoxContainer
var _box: TextureRect
var _text: RichTextLabel
var _error: Label
var _link_flag: bool = false
var _hover: bool = false
var _pop_tw: Tween


func _init(bbcode_text: String) -> void:
	add_theme_constant_override("separation", 4)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 12)
	_row.mouse_filter = Control.MOUSE_FILTER_STOP
	_row.focus_mode = Control.FOCUS_ALL
	_row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_row.gui_input.connect(_on_row_input)
	_row.focus_entered.connect(_refresh)
	_row.focus_exited.connect(_refresh)
	_row.mouse_entered.connect(_set_hover.bind(true))
	_row.mouse_exited.connect(_set_hover.bind(false))
	add_child(_row)

	_box = TextureRect.new()
	_box.texture = LoginTheme.tex("check_off")
	_box.custom_minimum_size = Vector2(28, 28)
	_box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_box.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_row.add_child(_box)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.text = bbcode_text
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_text.add_theme_font_size_override("normal_font_size", 18)
	_text.meta_clicked.connect(_on_meta)
	_row.add_child(_text)

	_error = LoginTheme.label("", 16, LoginTheme.BLOOD)
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.visible = false
	add_child(_error)
	_refresh()


func set_checked(value: bool) -> void:
	checked = value
	_box.texture = LoginTheme.tex("check_on" if checked else "check_off")
	if checked:
		clear_error()
	_refresh()


func set_error(message: String) -> void:
	_error.text = message
	_error.visible = true


func clear_error() -> void:
	_error.visible = false


func _set_hover(on: bool) -> void:
	_hover = on
	_refresh()


func _refresh() -> void:
	var lit: bool = _row.has_focus() or _hover or checked
	_box.modulate = Color.WHITE if lit else Color(0.85, 0.85, 0.85)


func _on_meta(meta: Variant) -> void:
	_link_flag = true
	Audio.play_sfx("click", 0.04)
	link_clicked.emit(str(meta))


func _on_row_input(event: InputEvent) -> void:
	var activate: bool = false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		activate = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event.is_action_pressed("ui_accept"):
		activate = true
	if not activate:
		return
	if _link_flag:
		_link_flag = false
		return
	_toggle()


func _toggle() -> void:
	checked = not checked
	Audio.play_sfx("click", 0.04)
	if Motion.on():
		if _pop_tw != null:
			_pop_tw.kill()
		_box.pivot_offset = _box.size / 2.0
		_box.scale = Vector2(1.25, 1.25)
		_pop_tw = create_tween()
		_pop_tw.tween_property(_box, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toggled.emit(checked)