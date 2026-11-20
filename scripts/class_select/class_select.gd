class_name ClassSelect
extends Control
# Tela "Escolha seu destino". Aparece depois do login e só deixa o jogador entrar
# no mundo quando o servidor confirmar a classe da conta.
#
# Fluxo: consulta a classe -> (já tem) entra | (vazia) mostra a seleção
#        -> confirmar -> confirmação final -> servidor grava -> entra.
# Falhas de rede ou de gravação nunca liberam a entrada: o jogador tenta de novo.

signal class_ready      # classe confirmada pelo servidor e aplicada em Game
signal cancelled        # jogador voltou ao login

const WARNING_TEXT := "ATENÇÃO: esta escolha é PERMANENTE. Depois de confirmada, a classe da sua conta não poderá ser alterada."

var _profile: ProfileService
var _selected_id: String = ""
var _busy: bool = false
var _finished: bool = false

var _cards: Dictionary = {}
var _card_row: BoxContainer
var _select_view: Control
var _loading_view: Control
var _error_view: Control
var _loading_label: Label
var _error_label: Label
var _retry_button: Button
var _confirm_button: Button
var _status_label: Label

var _modal: Control
var _modal_text: Label
var _modal_status: Label
var _modal_yes: Button
var _modal_no: Button
var _particles: CPUParticles2D


func _init(profile: ProfileService) -> void:
	_profile = profile


func _ready() -> void:
	theme = GameTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_background()
	_build_select_view()
	_build_loading_view()
	_build_error_view()
	_build_modal()
	resized.connect(_update_layout)
	_update_layout()
	_show_view(_loading_view)
	_load_class()


# Bloqueia ESC / voltar: a escolha é obrigatória.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ fluxo

func _load_class() -> void:
	_show_view(_loading_view)
	_loading_label.text = "Verificando seu herói..."
	var res: Dictionary = await _profile.fetch_class()
	if not is_inside_tree() or _finished:
		return
	if not res["ok"]:
		_show_error(str(res["message"]), str(res["code"]) != "unauthorized")
		return
	var gm: bool = await _profile.fetch_is_gm()
	if not is_inside_tree() or _finished:
		return
	Game.is_gm = gm
	var cid: String = str(res["class_id"])
	if cid != "":
		_finish(cid) # a conta já tem classe: não mostra a seleção
		return
	_show_view(_select_view)


func _finish(class_id: String) -> void:
	if _finished:
		return
	if not Game.apply_account_class(class_id):
		_show_error("O servidor devolveu uma classe desconhecida. Tente novamente.", true)
		return
	_finished = true
	class_ready.emit()


func _on_card_chosen(class_id: String) -> void:
	if _busy or _modal.visible:
		return
	_selected_id = class_id
	Audio.play_sfx("click")
	for id in _cards:
		var card: ClassCard = _cards[id]
		card.set_state(id == class_id, id != class_id)
	_confirm_button.disabled = false
	_status_label.text = ""


func _on_confirm_pressed() -> void:
	if _selected_id == "" or _busy:
		return
	_modal_text.text = "Você escolheu %s.\n\nEsta escolha é PERMANENTE e não poderá ser alterada depois, nem em outro aparelho. Deseja confirmar?" % _class_title(_selected_id)
	_modal_status.text = ""
	_set_modal_buttons(true)
	_modal.visible = true


func _on_modal_no() -> void:
	if _busy:
		return
	_modal.visible = false


func _on_modal_yes() -> void:
	if _busy or _selected_id == "":
		return
	_busy = true
	_set_modal_buttons(false)
	_modal_status.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	_modal_status.text = "Salvando sua escolha..."
	var res: Dictionary = await _profile.choose_class(_selected_id)
	_busy = false
	if not is_inside_tree() or _finished:
		return

	if res["ok"]:
		_finish(str(res["class_id"]))
		return

	if str(res["code"]) == "already_chosen":
		# Outra solicitação já gravou a classe: vale a do servidor.
		_modal_status.text = "Esta conta já tem personagem definido: %s." % _class_title(str(res["class_id"]))
		await get_tree().create_timer(1.4).timeout
		if is_inside_tree() and not _finished:
			_finish(str(res["class_id"]))
		return

	# Falha ao salvar: não entra no mundo; o jogador pode tentar novamente.
	_modal_status.add_theme_color_override("font_color", Color("#e0605a"))
	_modal_status.text = str(res["message"])
	_set_modal_buttons(true)
	if str(res["code"]) == "unauthorized":
		_modal_yes.disabled = true


func _on_retry_pressed() -> void:
	_load_class()


func _on_back_pressed() -> void:
	if _busy:
		return
	cancelled.emit()


func _class_title(class_id: String) -> String:
	for c in Game.CLASSES:
		if c["id"] == class_id:
			return str(c["name"])
	return "Aventureiro"


# ------------------------------------------------------------------ construção

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0c0910")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(0.22, 0.16, 0.30, 0.55), Color(0.03, 0.02, 0.08, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(1.0, 1.0)
	gt.width = 128
	gt.height = 128
	var glow := TextureRect.new()
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_particles = CPUParticles2D.new()
	_particles.texture = ImageTexture.create_from_image(img)
	_particles.amount = 28
	_particles.lifetime = 9.0
	_particles.preprocess = 9.0
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(640, 10)
	_particles.direction = Vector2(0, -1)
	_particles.spread = 25.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 14.0
	_particles.initial_velocity_max = 34.0
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 1.8
	_particles.color = Color(0.95, 0.86, 0.58, 0.55)
	_particles.emitting = Motion.on()
	add_child(_particles)


func _build_select_view() -> void:
	_select_view = MarginContainer.new()
	_select_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		_select_view.add_theme_constant_override("margin_" + side, 24)
	add_child(_select_view)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_select_view.add_child(col)

	var title := Label.new()
	title.text = "Escolha seu destino"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	col.add_child(title)

	var sub := Label.new()
	sub.text = "Toque em um herói para conhecê-lo. Você pode examinar as três opções antes de confirmar."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 20)
	col.add_child(sub)

	_card_row = BoxContainer.new()
	_card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_card_row.add_theme_constant_override("separation", 14)
	col.add_child(_card_row)
	for c in Game.CLASSES:
		var card := ClassCard.new(c)
		card.chosen.connect(_on_card_chosen)
		_card_row.add_child(card)
		_cards[str(c["id"])] = card

	var warn := PanelContainer.new()
	warn.add_theme_stylebox_override("panel", GameTheme.box(Color(0.22, 0.07, 0.08, 0.92), GameTheme.BLOOD, 3, 10, 10))
	col.add_child(warn)
	var warn_label := Label.new()
	warn_label.text = WARNING_TEXT
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn_label.add_theme_font_size_override("font_size", 20)
	warn_label.add_theme_color_override("font_color", Color("#ffb4ae"))
	warn.add_child(warn_label)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 20)
	col.add_child(_status_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons)

	var back := Button.new()
	back.text = "Voltar ao login"
	back.custom_minimum_size = Vector2(240, 68)
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(_on_back_pressed)
	buttons.add_child(back)

	_confirm_button = Button.new()
	_confirm_button.text = "Confirmar personagem"
	_confirm_button.disabled = true
	_confirm_button.custom_minimum_size = Vector2(340, 68)
	_confirm_button.focus_mode = Control.FOCUS_NONE
	_confirm_button.pressed.connect(_on_confirm_pressed)
	buttons.add_child(_confirm_button)


func _build_loading_view() -> void:
	_loading_view = CenterContainer.new()
	_loading_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_loading_view)
	_loading_label = Label.new()
	_loading_label.text = "Verificando seu herói..."
	_loading_label.add_theme_font_size_override("font_size", 34)
	_loading_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	_loading_view.add_child(_loading_label)


func _build_error_view() -> void:
	_error_view = CenterContainer.new()
	_error_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_error_view)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", GameTheme.box(Color(0.08, 0.04, 0.06, 0.95), GameTheme.BLOOD, 4, 12, 20))
	_error_view.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	var title := Label.new()
	title.text = "Não foi possível continuar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#e0605a"))
	v.add_child(title)

	_error_label = Label.new()
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.custom_minimum_size = Vector2(500, 0)
	_error_label.add_theme_font_size_override("font_size", 22)
	v.add_child(_error_label)

	_retry_button = Button.new()
	_retry_button.text = "Tentar novamente"
	_retry_button.custom_minimum_size = Vector2(0, 68)
	_retry_button.focus_mode = Control.FOCUS_NONE
	_retry_button.pressed.connect(_on_retry_pressed)
	v.add_child(_retry_button)

	var back := Button.new()
	back.text = "Voltar ao login"
	back.custom_minimum_size = Vector2(0, 68)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_on_back_pressed)
	v.add_child(back)


func _build_modal() -> void:
	_modal = Control.new()
	_modal.visible = false
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", GameTheme.box(Color(0.14, 0.10, 0.18, 0.98), GameTheme.GOLD, 4, 12, 22))
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	var title := Label.new()
	title.text = "Confirmação final"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	v.add_child(title)

	_modal_text = Label.new()
	_modal_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_text.custom_minimum_size = Vector2(500, 0)
	_modal_text.add_theme_font_size_override("font_size", 22)
	v.add_child(_modal_text)

	_modal_status = Label.new()
	_modal_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_status.custom_minimum_size = Vector2(500, 0)
	_modal_status.add_theme_font_size_override("font_size", 20)
	v.add_child(_modal_status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)

	_modal_no = Button.new()
	_modal_no.text = "Voltar"
	_modal_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_no.custom_minimum_size = Vector2(0, 68)
	_modal_no.focus_mode = Control.FOCUS_NONE
	_modal_no.pressed.connect(_on_modal_no)
	row.add_child(_modal_no)

	_modal_yes = Button.new()
	_modal_yes.text = "Sim, confirmar"
	_modal_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_yes.custom_minimum_size = Vector2(0, 68)
	_modal_yes.focus_mode = Control.FOCUS_NONE
	_modal_yes.pressed.connect(_on_modal_yes)
	row.add_child(_modal_yes)


# ------------------------------------------------------------------ apoio

func _show_view(view: Control) -> void:
	_select_view.visible = view == _select_view
	_loading_view.visible = view == _loading_view
	_error_view.visible = view == _error_view
	if view != _select_view:
		_modal.visible = false


func _show_error(message: String, can_retry: bool) -> void:
	_error_label.text = message
	_retry_button.visible = can_retry
	_show_view(_error_view)


func _set_modal_buttons(enabled: bool) -> void:
	_modal_yes.disabled = not enabled
	_modal_no.disabled = not enabled


# Retrato: cartões empilhados com arte ao lado do texto. Paisagem: três colunas.
func _update_layout() -> void:
	var portrait := size.x < size.y
	if _card_row:
		_card_row.vertical = portrait
		for id in _cards:
			(_cards[id] as ClassCard).set_compact(portrait)
	if _particles:
		_particles.position = Vector2(size.x / 2.0, size.y + 10.0)
		_particles.emission_rect_extents = Vector2(size.x / 2.0, 10.0)