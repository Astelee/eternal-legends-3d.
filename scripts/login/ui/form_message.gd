class_name FormMessage
extends PanelContainer
# Faixa de mensagem (erro, sucesso ou informação) dentro de um formulário.

var _icon: TextureRect
var _label: Label
var _tween: Tween


func _init() -> void:
	visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	_icon = LoginTheme.icon("alert", 24)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_icon)
	_label = LoginTheme.label("", 17)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_label)


func show_error(message: String) -> void:
	_show(message, LoginTheme.BLOOD, "alert", Color(0.30, 0.07, 0.09, 0.9))


func show_success(message: String) -> void:
	_show(message, LoginTheme.LIFE, "check", Color(0.07, 0.22, 0.11, 0.9))


func show_info(message: String) -> void:
	_show(message, LoginTheme.MAGIC, "sparkle", Color(0.08, 0.14, 0.30, 0.9))


func clear_message() -> void:
	visible = false


func _show(message: String, accent: Color, icon_id: String, fill: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	_icon.texture = LoginTheme.tex("icon_" + icon_id)
	_icon.modulate = accent
	_label.text = message
	_label.add_theme_color_override("font_color", accent.lerp(LoginTheme.PARCHMENT, 0.45))
	visible = true
	if _tween != null:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, Motion.dur(0.2))