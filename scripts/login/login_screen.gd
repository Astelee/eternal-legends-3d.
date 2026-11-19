class_name LoginScreen
extends Control
# Tela de entrada do Eternal Legends.
# Orquestra o fundo, o logotipo, o painel de login, as atualizações, o rodapé
# e as janelas (cadastro, recuperação, termos, política, histórico, detalhes).
# Layout, animações e navegação ficam aqui; cada janela é um componente próprio.

const GAME_SCENE := "res://scenes/main/main.tscn"
# Atalho de desenvolvimento: só aparece em builds de debug e é claramente rotulado.
# Ele NÃO autentica nada; apenas pula a tela enquanto não há servidor. Ponha false para remover.
const ALLOW_DEBUG_SKIP := true

const BG_TEXTURE: Texture2D = preload("res://assets/ui/login/login_bg.png")
const BG_SIZE := Vector2(1672.0, 941.0)
const HERO_TOP_IN_BG := 603.0   # topo dos três heróis na imagem de fundo (px da imagem)
const WIDE_MIN_WIDTH := 1000.0
const LOGIN_WIDTH := 390.0
const NEWS_WIDTH := 330.0

var auth: AuthService
var news_repo: NewsRepository

var _bg: TextureRect
var _vignette: TextureRect
var _particles: CPUParticles2D
var _logo: TextureRect
var _tagline: Label
var _login_holder: Control
var _login_form: LoginForm
var _news_holder: Control
var _news_panel: NewsPanel
var _bottom: PanelContainer
var _motion_btn: LinkButton
var _news_link: LinkButton
var _version_label: Label
var _separators: Array[Label] = []
var _modal_layer: Control

var _modals: Array[ModalWindow] = []
var _news_items: Array = []
var _compact: bool = false
var _t: float = 0.0
var _login_slide: float = 0.0
var _news_slide: float = 0.0
var _logo_drop: float = 0.0
var _logo_base: Vector2 = Vector2.ZERO
var _layout_queued: bool = false
var _entering: bool = false
var _prev_scale_size: Vector2i = Vector2i(1280, 720)
var _bg_tween: Tween


func _ready() -> void:
	LoginPrefs.load_prefs()
	theme = LoginTheme.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_content_scale()

	auth = AuthService.new()
	add_child(auth)
	news_repo = NewsRepository.new()
	add_child(news_repo)

	_build_background()
	_build_logo()
	_build_login()
	_build_news()
	_build_bottom()

	_modal_layer = Control.new()
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)

	resized.connect(_queue_layout)
	_layout()
	set_process(Motion.on())
	_start_intro()
	_load_news()


func _exit_tree() -> void:
	var win: Window = get_window()
	if win == null:
		return
	if win.size_changed.is_connected(_update_content_scale):
		win.size_changed.disconnect(_update_content_scale)
	# O jogo espera a resolução base 1280x720.
	win.content_scale_size = _prev_scale_size


func _process(delta: float) -> void:
	_t += delta
	_apply_offsets()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _modals.is_empty():
		_modals.back().close()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ construção

func _build_background() -> void:
	_bg = TextureRect.new()
	_bg.texture = BG_TEXTURE
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.resized.connect(func() -> void: _bg.pivot_offset = _bg.size / 2.0)
	add_child(_bg)
	_start_bg_drift()

	# Escurece de leve as bordas para dar profundidade e leitura à interface.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.45, 1.0])
	grad.colors = PackedColorArray([Color(0.03, 0.02, 0.08, 0.0), Color(0.03, 0.02, 0.08, 0.6)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	gt.width = 128
	gt.height = 128
	_vignette = TextureRect.new()
	_vignette.texture = gt
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	# Partículas mágicas sutis subindo do chão.
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_particles = CPUParticles2D.new()
	_particles.texture = ImageTexture.create_from_image(img)
	_particles.amount = 36
	_particles.lifetime = 10.0
	_particles.preprocess = 10.0
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(640, 10)
	_particles.direction = Vector2(0, -1)
	_particles.spread = 25.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 14.0
	_particles.initial_velocity_max = 34.0
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 1.8
	var pg := Gradient.new()
	pg.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	pg.colors = PackedColorArray([
		Color(0.7, 0.9, 1.0, 0.0), Color(0.7, 0.9, 1.0, 0.8),
		Color(0.95, 0.9, 0.6, 0.8), Color(0.95, 0.9, 0.6, 0.0)])
	_particles.color_ramp = pg
	_particles.emitting = Motion.on()
	add_child(_particles)


func _start_bg_drift() -> void:
	if _bg_tween != null:
		_bg_tween.kill()
		_bg_tween = null
	_bg.scale = Vector2.ONE
	if not Motion.on():
		return
	# Aproximação lenta e quase imperceptível, em vai-e-volta.
	_bg_tween = create_tween().set_loops()
	_bg_tween.tween_property(_bg, "scale", Vector2(1.025, 1.025), 40.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bg_tween.tween_property(_bg, "scale", Vector2.ONE, 40.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _build_logo() -> void:
	_logo = TextureRect.new()
	_logo.texture = LoginTheme.tex("logo")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)

	_tagline = LoginTheme.label("Seu destino começa aqui.", 22, LoginTheme.GOLD_LIGHT)
	_tagline.add_theme_font_override("font", LoginTheme.title_font())
	_tagline.add_theme_constant_override("outline_size", 7)
	_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_tagline)


func _build_login() -> void:
	_login_holder = Control.new()
	_login_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_login_holder)

	_login_form = LoginForm.new(auth)
	_login_holder.add_child(_login_form)
	_login_form.minimum_size_changed.connect(_queue_layout)
	_login_form.login_succeeded.connect(_on_login_succeeded)
	_login_form.register_requested.connect(_open_register)
	_login_form.recovery_requested.connect(_open_recovery)


func _build_news() -> void:
	_news_holder = Control.new()
	_news_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_news_holder)

	_news_panel = NewsPanel.new()
	_news_holder.add_child(_news_panel)
	_news_panel.minimum_size_changed.connect(_queue_layout)
	_news_panel.details_requested.connect(_open_details)
	_news_panel.history_requested.connect(_open_history)


func _build_bottom() -> void:
	_bottom = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.03, 0.09, 0.62)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	_bottom.add_theme_stylebox_override("panel", sb)
	add_child(_bottom)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_bottom.add_child(row)

	_news_link = _bottom_link("Atualizações")
	_news_link.pressed.connect(_open_history)
	_news_link.visible = false
	row.add_child(_news_link)

	var terms := _bottom_link("Termos de Serviço")
	terms.pressed.connect(_open_legal.bind("terms"))
	row.add_child(terms)
	row.add_child(_separator())

	var privacy := _bottom_link("Política de Privacidade")
	privacy.pressed.connect(_open_legal.bind("privacy"))
	row.add_child(privacy)
	row.add_child(_separator())

	_motion_btn = _bottom_link("")
	_motion_btn.pressed.connect(_toggle_motion)
	row.add_child(_motion_btn)
	_refresh_motion_label()

	_version_label = LoginTheme.label("v" + Game.VERSION, 15, LoginTheme.PARCHMENT_DIM)
	row.add_child(_separator())
	row.add_child(_version_label)

	if ALLOW_DEBUG_SKIP and OS.is_debug_build():
		row.add_child(_separator())
		var dbg := _bottom_link("[DEBUG] entrar sem servidor")
		dbg.add_theme_color_override("font_color", Color("#c9a4ff"))
		dbg.pressed.connect(_debug_skip)
		row.add_child(dbg)


func _bottom_link(text: String) -> LinkButton:
	var b := LoginTheme.link(text, 16)
	b.add_theme_color_override("font_color", LoginTheme.PARCHMENT_DIM)
	return b


func _separator() -> Label:
	var l := LoginTheme.label("•", 14, LoginTheme.GOLD_DARK)
	_separators.append(l)
	return l


# ------------------------------------------------------------------ layout

func _queue_layout() -> void:
	if _layout_queued:
		return
	_layout_queued = true
	_layout.call_deferred()


func _hero_top() -> float:
	var s: float = maxf(size.x / BG_SIZE.x, size.y / BG_SIZE.y)
	var oy: float = (size.y - BG_SIZE.y * s) / 2.0
	return HERO_TOP_IN_BG * s + oy


func _layout() -> void:
	_layout_queued = false
	var vw: float = size.x
	var vh: float = size.y
	if vw <= 0.0 or vh <= 0.0:
		return
	_compact = vw < WIDE_MIN_WIDTH

	_particles.position = Vector2(vw / 2.0, vh + 10.0)
	_particles.emission_rect_extents = Vector2(vw / 2.0, 10.0)

	# Rodapé
	_version_label.visible = not _compact
	for s in _separators:
		s.visible = true
	var bs: Vector2 = _bottom.get_combined_minimum_size()
	_bottom.size = bs
	_bottom.position = Vector2((vw - bs.x) / 2.0, vh - bs.y - 8.0)
	var bottom_limit: float = _bottom.position.y - 10.0

	# Logotipo e frase
	var logo_w: float = 360.0 if not _compact else minf(vw * 0.78, 340.0)
	var tex: Texture2D = _logo.texture
	var logo_h: float = logo_w * float(tex.get_height()) / float(tex.get_width())
	var logo_top: float = 8.0 if not _compact else 12.0
	_logo.size = Vector2(logo_w, logo_h)
	_logo_base = Vector2((vw - logo_w) / 2.0, logo_top)
	_tagline.add_theme_font_size_override("font_size", 22 if not _compact else 20)
	_tagline.size = Vector2(vw, 34.0)
	_tagline.position = Vector2(0.0, logo_top + logo_h - 2.0)
	var header_bottom: float = logo_top + logo_h + 32.0

	# Painel de login
	var w: float = LOGIN_WIDTH if not _compact else minf(LOGIN_WIDTH, vw - 24.0)
	_login_form.custom_minimum_size.x = w
	var ps: Vector2 = _login_form.get_combined_minimum_size()
	_login_form.size = ps
	_login_holder.size = ps
	var top_limit: float = 20.0 if not _compact else header_bottom + 4.0
	var avail: float = maxf(200.0, bottom_limit - top_limit)
	var k: float = minf(1.0, avail / ps.y)
	_login_holder.scale = Vector2(k, k)
	var lx: float
	var ly: float
	if _compact:
		lx = (vw - w * k) / 2.0
		ly = top_limit
	else:
		lx = vw - w * k - 36.0
		ly = top_limit + (avail - ps.y * k) / 2.0
	_login_holder.position = Vector2(lx, ly)

	# Atualizações
	var show_news: bool = true
	var nx: float
	var ny: float
	var nw: float
	var target_h: float
	if not _compact:
		nw = NEWS_WIDTH
		ny = 104.0
		nx = 28.0
		target_h = clampf(_hero_top() - 14.0 - ny, 230.0, 400.0)
	else:
		nw = w
		ny = ly + ps.y * k + 12.0
		nx = (vw - nw) / 2.0
		var room: float = bottom_limit - ny
		target_h = minf(room, 360.0)
		show_news = room >= 230.0
	_news_holder.visible = show_news
	_news_link.visible = not show_news
	if show_news:
		_news_panel.custom_minimum_size.x = nw
		_news_panel.set_target_height(target_h)
		var np: Vector2 = _news_panel.get_combined_minimum_size()
		_news_panel.size = np
		_news_holder.size = np
		_news_holder.position = Vector2(nx, ny)

	_apply_offsets()


# Flutuação suave + deslizamento da animação de abertura.
func _apply_offsets() -> void:
	var f1: float = 0.0
	var f2: float = 0.0
	var f3: float = 0.0
	if Motion.on():
		f1 = sin(_t * 1.25) * 3.0
		f2 = sin(_t * 1.1 + 1.7) * 2.5
		f3 = sin(_t * 0.9 + 0.6) * 2.0
	_login_form.position = Vector2(_login_slide, f1)
	_news_panel.position = Vector2(_news_slide, f2)
	_logo.position = _logo_base + Vector2(0.0, _logo_drop + f3)


# O jogo é paisagem (1280x720). Em janelas em pé (retrato), a tela de login usa 720x1280.
func _setup_content_scale() -> void:
	var win: Window = get_window()
	if win.content_scale_size.x > 0 and win.content_scale_size.y > 0:
		_prev_scale_size = win.content_scale_size
	win.size_changed.connect(_update_content_scale)
	_update_content_scale()


func _update_content_scale() -> void:
	var win: Window = get_window()
	var portrait: bool = win.size.x < win.size.y
	var target: Vector2i = Vector2i(720, 1280) if portrait else _prev_scale_size
	if win.content_scale_size != target:
		win.content_scale_size = target


# ------------------------------------------------------------------ animações

func _start_intro() -> void:
	await get_tree().process_frame
	_layout()
	if not Motion.on():
		_login_form.focus_first_empty()
		return

	var items: Array = _login_form.stagger_items()
	_login_slide = 48.0
	_news_slide = -48.0
	_logo_drop = -18.0
	_bg.modulate = Color(0.1, 0.1, 0.16)
	_login_holder.modulate.a = 0.0
	_news_holder.modulate.a = 0.0
	_logo.modulate.a = 0.0
	_tagline.modulate.a = 0.0
	_bottom.modulate.a = 0.0
	for it in items:
		(it as Control).modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bg, "modulate", Color.WHITE, 1.1)
	tw.tween_property(_logo, "modulate:a", 1.0, 0.7).set_delay(0.15)
	tw.tween_property(self, "_logo_drop", 0.0, 0.8).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_tagline, "modulate:a", 1.0, 0.6).set_delay(0.55)
	tw.tween_property(_login_holder, "modulate:a", 1.0, 0.5).set_delay(0.35)
	tw.tween_property(self, "_login_slide", 0.0, 0.8).set_delay(0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in items.size():
		tw.tween_property(items[i], "modulate:a", 1.0, 0.35).set_delay(0.65 + 0.07 * i)
	tw.tween_property(_news_holder, "modulate:a", 1.0, 0.5).set_delay(0.6)
	tw.tween_property(self, "_news_slide", 0.0, 0.8).set_delay(0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bottom, "modulate:a", 1.0, 0.5).set_delay(1.1)
	await tw.finished
	_login_form.focus_first_empty()


func _toggle_motion() -> void:
	LoginPrefs.set_reduced_motion(not LoginPrefs.reduced_motion)
	_refresh_motion_label()
	var on: bool = Motion.on()
	set_process(on)
	_particles.emitting = on
	_start_bg_drift()
	_login_form.start_glow()
	_news_panel.start_glow()
	if not on:
		_login_slide = 0.0
		_news_slide = 0.0
		_logo_drop = 0.0
	_apply_offsets()


func _refresh_motion_label() -> void:
	_motion_btn.text = "Animações: reduzidas" if LoginPrefs.reduced_motion else "Animações: normais"


# ------------------------------------------------------------------ janelas

func _open_modal(w: ModalWindow) -> void:
	_modal_layer.add_child(w)
	_modals.append(w)
	w.closed.connect(func() -> void: _modals.erase(w))
	w.open()


func _open_register() -> void:
	var w := RegisterWindow.new(auth)
	w.legal_requested.connect(_open_legal)
	w.enter_game_requested.connect(func(_response: Dictionary) -> void: _on_login_succeeded(_response))
	_open_modal(w)


func _open_recovery() -> void:
	_open_modal(RecoveryWindow.new(auth))


func _open_legal(kind: String) -> void:
	if kind == "privacy":
		_open_modal(LegalWindow.new("res://data/legal/privacy_policy.json", "Política de Privacidade"))
	else:
		_open_modal(LegalWindow.new("res://data/legal/terms_of_service.json", "Termos de Serviço"))


func _open_history() -> void:
	var w := NewsHistoryWindow.new(_news_items)
	w.details_requested.connect(_open_details)
	_open_modal(w)


func _open_details(item: Dictionary) -> void:
	_open_modal(NewsDetailWindow.new(item))


# ------------------------------------------------------------------ dados e fluxo

func _load_news() -> void:
	_news_panel.set_loading()
	var res: Dictionary = await news_repo.fetch()
	_news_items = res["items"]
	if _news_items.is_empty() and str(res["error"]) != "":
		_news_panel.set_error(str(res["error"]))
	else:
		_news_panel.set_items(_news_items)
	_queue_layout()


func _on_login_succeeded(_response: Dictionary) -> void:
	if Session.username != "":
		Game.player_name = Session.username
		Game.save_profile()
		Game.profile_changed.emit()
	_enter_game()


func _debug_skip() -> void:
	push_warning("LoginScreen: entrada de debug SEM autenticação.")
	_enter_game()


# A escolha de classe acontece dentro do jogo, depois de entrar na conta.
func _enter_game() -> void:
	if _entering:
		return
	_entering = true
	var overlay := ColorRect.new()
	overlay.color = Color("#0c0910")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.modulate.a = 0.0
	var msg := LoginTheme.label("Entrando no reino...", 34, LoginTheme.GOLD_LIGHT)
	msg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(msg)
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, Motion.dur(0.45))
	await tw.finished
	get_tree().change_scene_to_file(GAME_SCENE)