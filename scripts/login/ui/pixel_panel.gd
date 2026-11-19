class_name PixelPanel
extends PanelContainer
# Painel "janela mágica": fundo escuro translúcido, sombra projetada,
# moldura dourada com placas de canto e brilho discreto nas bordas.
# Adicione o conteúdo em `content`, nunca direto no painel.

var content: VBoxContainer
var _frame: NinePatchRect
var _glow_tween: Tween


func _init(pad: int = LoginTheme.PANEL_PAD, fill: Color = LoginTheme.PANEL_FILL) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 8)
	add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", pad)
	margin.add_theme_constant_override("margin_right", pad)
	margin.add_theme_constant_override("margin_top", pad)
	margin.add_theme_constant_override("margin_bottom", pad)
	add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	# A moldura é o último filho: desenha por cima do conteúdo e do fundo.
	_frame = NinePatchRect.new()
	_frame.texture = LoginTheme.tex("frame")
	_frame.patch_margin_left = LoginTheme.FRAME_MARGIN
	_frame.patch_margin_top = LoginTheme.FRAME_MARGIN
	_frame.patch_margin_right = LoginTheme.FRAME_MARGIN
	_frame.patch_margin_bottom = LoginTheme.FRAME_MARGIN
	_frame.draw_center = false
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)


func _ready() -> void:
	start_glow()


# Pulso lento e discreto de brilho na moldura. Desligado com movimento reduzido.
func start_glow() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
	_frame.self_modulate = Color.WHITE
	if not Motion.on():
		return
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_frame, "self_modulate", Color(0.8, 0.78, 0.76), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(_frame, "self_modulate", Color.WHITE, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_glow() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
		_glow_tween = null
	_frame.self_modulate = Color.WHITE