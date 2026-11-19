class_name PixelField
extends VBoxContainer
# Campo de texto com rótulo, ícone temático, mensagem de erro e (opcional)
# botão de mostrar/ocultar senha.

signal submitted
signal edited

var edit: LineEdit

var _box: PanelContainer
var _eye: TextureButton
var _error: Label
var _sb_normal: StyleBoxTexture
var _sb_focus: StyleBoxTexture
var _sb_error: StyleBoxTexture
var _has_error: bool = false
var _shake_tw: Tween


func _init(label_text: String, placeholder: String, icon_id: String, secret: bool = false, keyboard: int = LineEdit.KEYBOARD_TYPE_DEFAULT) -> void:
	add_theme_constant_override("separation", 6)

	var lbl := LoginTheme.label(label_text, 18, LoginTheme.GOLD_LIGHT)
	add_child(lbl)

	_sb_normal = LoginTheme.nine("field_normal", 10, 12, 4, 8, 4)
	_sb_focus = LoginTheme.nine("field_focus", 10, 12, 4, 8, 4)
	_sb_error = LoginTheme.nine("field_error", 10, 12, 4, 8, 4)
	_box = PanelContainer.new()
	_box.custom_minimum_size = Vector2(0, 50)
	_box.add_theme_stylebox_override("panel", _sb_normal)
	add_child(_box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_box.add_child(row)

	var ic := LoginTheme.icon(icon_id, 24, LoginTheme.GOLD)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)

	edit = LineEdit.new()
	edit.placeholder_text = placeholder
	edit.secret = secret
	edit.virtual_keyboard_type = keyboard
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.caret_blink = true
	edit.context_menu_enabled = false
	edit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	edit.add_theme_stylebox_override("read_only", StyleBoxEmpty.new())
	edit.add_theme_color_override("font_color", LoginTheme.PARCHMENT)
	edit.add_theme_color_override("font_placeholder_color", Color(0.62, 0.57, 0.5, 0.75))
	edit.add_theme_color_override("caret_color", LoginTheme.GOLD_LIGHT)
	edit.add_theme_color_override("selection_color", Color(0.3, 0.5, 0.85, 0.5))
	edit.add_theme_font_size_override("font_size", 20)
	row.add_child(edit)

	if secret:
		_eye = TextureButton.new()
		_eye.texture_normal = LoginTheme.tex("icon_eye")
		_eye.ignore_texture_size = true
		_eye.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		_eye.custom_minimum_size = Vector2(36, 36)
		_eye.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_eye.self_modulate = LoginTheme.PARCHMENT_DIM
		_eye.focus_mode = Control.FOCUS_NONE
		_eye.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_eye.tooltip_text = "Mostrar ou ocultar a senha"
		_eye.pressed.connect(_toggle_secret)
		_eye.mouse_entered.connect(func() -> void: _eye.self_modulate = LoginTheme.GOLD_LIGHT)
		_eye.mouse_exited.connect(func() -> void: _eye.self_modulate = LoginTheme.PARCHMENT_DIM)
		row.add_child(_eye)

	_error = LoginTheme.label("", 16, LoginTheme.BLOOD)
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.visible = false
	add_child(_error)

	edit.focus_entered.connect(_refresh_style)
	edit.focus_exited.connect(_refresh_style)
	edit.text_changed.connect(_on_text_changed)
	edit.text_submitted.connect(func(_t: String) -> void: submitted.emit())


func get_value() -> String:
	return edit.text


func set_value(value: String) -> void:
	edit.text = value


func focus_edit() -> void:
	edit.grab_focus()


func set_error(message: String) -> void:
	_has_error = true
	_error.text = message
	_error.visible = true
	_refresh_style()
	_shake()


func clear_error() -> void:
	if not _has_error:
		return
	_has_error = false
	_error.visible = false
	_refresh_style()


func has_error() -> bool:
	return _has_error


func set_enabled(on: bool) -> void:
	edit.editable = on
	if _eye != null:
		_eye.disabled = not on


func _on_text_changed(_t: String) -> void:
	clear_error()
	edited.emit()


func _refresh_style() -> void:
	var sb: StyleBoxTexture = _sb_normal
	if _has_error:
		sb = _sb_error
	elif edit.has_focus():
		sb = _sb_focus
	_box.add_theme_stylebox_override("panel", sb)


func _toggle_secret() -> void:
	edit.secret = not edit.secret
	_eye.texture_normal = LoginTheme.tex("icon_eye" if edit.secret else "icon_eye_off")
	Audio.play_sfx("click", 0.04)


func _shake() -> void:
	if not Motion.on():
		return
	if _shake_tw != null:
		_shake_tw.kill()
	_shake_tw = create_tween()
	for dx in [-5.0, 5.0, -3.0, 3.0, 0.0]:
		_shake_tw.tween_property(_box, "position:x", dx, 0.045)