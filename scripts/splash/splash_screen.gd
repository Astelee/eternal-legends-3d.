class_name SplashScreen
extends Control
# Tela de carregamento (Splash). É a cena inicial do jogo.
#
# O progresso é REAL: usa ResourceLoader.load_threaded_request() /
# load_threaded_get_status() para carregar a tela de login, o jogo e as
# texturas da interface em segundo plano. A barra e a porcentagem mostram o
# progresso agregado desses carregamentos (cada recurso tem um peso, só para
# somar) e nunca passam do valor real. Ao chegar em 100%, vai para o login.

const NEXT_SCENE := "res://scenes/login/login_screen.tscn"
const GAME_SCENE := "res://scenes/main/main.tscn"
const UI_DIR := "res://assets/ui/login/"
const TIPS_PATH := "res://data/tips.json"
const BG_TEXTURE: Texture2D = preload("res://assets/ui/splash/splash_bg.png")

const HOLD_AFTER_DONE := 0.5      # pausa curta em 100% antes da transição
const TIP_INTERVAL := 3.8
const BAR_SPEED := 1.6            # suavização visual (fração/s); nunca ultrapassa o real

# Mantém os recursos carregados vivos no cache para o login/jogo abrirem instantaneamente.
static var kept: Array = []

var _jobs: Array = []
var _shown: float = 0.0
var _finishing: bool = false
var _failed: bool = false
var _tips: Array = []
var _tip_index: int = 0
var _tip_time: float = 0.0
var _t: float = 0.0

var _bg: TextureRect
var _particles: CPUParticles2D
var _column: VBoxContainer
var _logo: TextureRect
var _glow: TextureRect
var _sparkles: Array[TextureRect] = []
var _status: Label
var _bar: ProgressBar
var _shine: TextureRect
var _spark: TextureRect
var _pct: Label
var _tip_label: Label
var _error_box: VBoxContainer
var _fade: ColorRect


func _ready() -> void:
	LoginPrefs.load_prefs()
	theme = LoginTheme.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_load_tips()
	_start_jobs()
	resized.connect(_layout)
	_layout()
	_layout.call_deferred()
	_intro()


func _process(delta: float) -> void:
	_t += delta
	if _failed:
		return
	var real: float = _poll()
	_shown = move_toward(_shown, real, delta * BAR_SPEED)
	_bar.value = _shown * 100.0
	_pct.text = "%d%%" % int(floor(_shown * 100.0))
	_update_bar_fx()
	_rotate_tips(delta)
	if _failed:
		return
	if real >= 1.0 and _shown >= 1.0 and not _finishing:
		_finish()


# ------------------------------------------------------------------ carregamento real

func _start_jobs() -> void:
	_add_job(NEXT_SCENE, 6.0, true)
	_add_job(GAME_SCENE, 10.0, false)
	var seen: Dictionary = {}
	for f in DirAccess.get_files_at(UI_DIR):
		# Na exportação os arquivos aparecem como "x.png.import"/".remap".
		var n: String = f.trim_suffix(".import").trim_suffix(".remap")
		if n.ends_with(".png") and not seen.has(n):
			seen[n] = true
			_add_job(UI_DIR + n, 1.0, false)


func _add_job(path: String, weight: float, critical: bool) -> void:
	var job: Dictionary = {"path": path, "weight": weight, "critical": critical, "done": false, "resource": null}
	if not ResourceLoader.exists(path):
		job["done"] = true
		if critical:
			_fail("Arquivo do jogo não encontrado.")
	elif ResourceLoader.load_threaded_request(path, "", true) != OK:
		job["done"] = true
		if critical:
			_fail("Não foi possível iniciar o carregamento.")
	_jobs.append(job)


# Devolve o progresso real agregado (0..1).
func _poll() -> float:
	var total: float = 0.0
	var sum: float = 0.0
	for j in _jobs:
		var w: float = j["weight"]
		total += w
		if j["done"]:
			sum += w
			continue
		var prog: Array = []
		var status: int = ResourceLoader.load_threaded_get_status(j["path"], prog)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var p: float = float(prog[0]) if prog.size() > 0 else 0.0
			sum += w * clampf(p, 0.0, 1.0)
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			j["done"] = true
			j["resource"] = ResourceLoader.load_threaded_get(j["path"])
			kept.append(j["resource"])
			sum += w
		else:
			j["done"] = true
			push_error("Splash: falha ao carregar " + str(j["path"]))
			if j["critical"]:
				_fail("Falha ao carregar o jogo.")
			sum += w
	if total <= 0.0:
		return 1.0
	return clampf(sum / total, 0.0, 1.0)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	_status.text = message
	_error_box.visible = true


func _finish() -> void:
	_finishing = true
	await get_tree().create_timer(Motion.dur(HOLD_AFTER_DONE) + 0.05).timeout
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, Motion.dur(0.45))
	await tw.finished
	var packed: PackedScene = null
	for j in _jobs:
		if j["path"] == NEXT_SCENE and j["resource"] is PackedScene:
			packed = j["resource"]
	if packed != null:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(NEXT_SCENE)


# ------------------------------------------------------------------ construção da interface

func _build_ui() -> void:
	_bg = TextureRect.new()
	_bg.texture = BG_TEXTURE
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.resized.connect(func() -> void: _bg.pivot_offset = _bg.size / 2.0)
	add_child(_bg)
	if Motion.on():
		var tw := create_tween().set_loops()
		tw.tween_property(_bg, "scale", Vector2(1.025, 1.025), 30.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_bg, "scale", Vector2.ONE, 30.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_build_particles()

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 14)
	add_child(_column)

	_logo = TextureRect.new()
	_logo.texture = LoginTheme.tex("logo")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.resized.connect(_on_logo_resized)
	_column.add_child(_logo)
	_build_logo_fx()

	_column.add_child(_status_row())
	_column.add_child(_bar_row())
	_column.add_child(_tip_row())

	_error_box = VBoxContainer.new()
	_error_box.visible = false
	_error_box.add_theme_constant_override("separation", 10)
	var retry := PixelButton.new("TENTAR NOVAMENTE", PixelButton.Kind.GOLD)
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.custom_minimum_size = Vector2(280, 54)
	retry.pressed.connect(func() -> void: get_tree().reload_current_scene())
	_error_box.add_child(retry)
	_column.add_child(_error_box)

	_fade = ColorRect.new()
	_fade.color = Color("#05061a")
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _build_particles() -> void:
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_particles = CPUParticles2D.new()
	_particles.texture = ImageTexture.create_from_image(img)
	_particles.amount = 48
	_particles.lifetime = 9.0
	_particles.preprocess = 9.0
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(640, 10)
	_particles.direction = Vector2(0, -1)
	_particles.spread = 30.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 16.0
	_particles.initial_velocity_max = 40.0
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 2.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([
		Color(0.55, 0.8, 1.0, 0.0), Color(0.55, 0.8, 1.0, 0.85),
		Color(1.0, 0.85, 0.45, 0.85), Color(1.0, 0.85, 0.45, 0.0)])
	_particles.color_ramp = g
	_particles.emitting = Motion.on()
	add_child(_particles)


func _build_logo_fx() -> void:
	# Brilho suave atrás do logotipo (pulsa devagar).
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(1.0, 0.8, 0.4, 0.38), Color(0.3, 0.5, 1.0, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	_glow = TextureRect.new()
	_glow.texture = gt
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.show_behind_parent = true
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.add_child(_glow)
	if Motion.on():
		var tw := create_tween().set_loops()
		tw.tween_property(_glow, "modulate:a", 0.55, 2.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_glow, "modulate:a", 1.0, 2.2).set_trans(Tween.TRANS_SINE)

	# Brilhos que piscam sobre o logotipo.
	for i in 4:
		var s := LoginTheme.icon("sparkle", 22, Color(0.85, 0.95, 1.0))
		s.modulate.a = 0.0
		_logo.add_child(s)
		_sparkles.append(s)
		if Motion.on():
			var tw2 := create_tween().set_loops()
			tw2.tween_interval(0.5 + 0.9 * i)
			tw2.tween_property(s, "modulate:a", 1.0, 0.35)
			tw2.tween_property(s, "modulate:a", 0.0, 0.5)
			tw2.tween_interval(1.2)


func _on_logo_resized() -> void:
	_logo.pivot_offset = _logo.size / 2.0
	var pad: Vector2 = _logo.size * 0.35
	_glow.position = -pad
	_glow.size = _logo.size + pad * 2.0
	var spots: Array = [Vector2(0.08, 0.18), Vector2(0.92, 0.1), Vector2(0.78, 0.72), Vector2(0.3, 0.55)]
	for i in _sparkles.size():
		var p: Vector2 = spots[i]
		_sparkles[i].position = Vector2(_logo.size.x * p.x - 11.0, _logo.size.y * p.y - 11.0)
		_sparkles[i].size = Vector2(22, 22)


func _status_row() -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.1, 0.62)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	row.add_child(_ornament_line())
	_status = LoginTheme.label("Carregando seu mundo...", 26, LoginTheme.PARCHMENT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(_status)
	row.add_child(_ornament_line())
	return panel


func _ornament_line() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.color = LoginTheme.GOLD
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(line)
	var d := TextureRect.new()
	d.texture = LoginTheme.tex("diamond")
	d.custom_minimum_size = Vector2(18, 18)
	d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(d)
	return h


func _bar_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", LoginTheme.nine("bar_frame", 10, 10, 10, 10, 10))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(frame)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.step = 0.01
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 22)
	_bar.clip_contents = true
	_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_bar.add_theme_stylebox_override("fill", LoginTheme.nine("bar_fill", 4, 0, 0, 0, 0))
	frame.add_child(_bar)

	_shine = TextureRect.new()
	_shine.texture = LoginTheme.tex("shine")
	_shine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shine.stretch_mode = TextureRect.STRETCH_SCALE
	_shine.modulate = Color(1, 1, 1, 0.55)
	_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shine.visible = false
	_bar.add_child(_shine)

	_spark = LoginTheme.icon("sparkle", 26, Color(0.85, 0.95, 1.0))
	_spark.visible = false
	_bar.add_child(_spark)

	_pct = LoginTheme.label("0%", 24, LoginTheme.GOLD_LIGHT)
	_pct.custom_minimum_size = Vector2(72, 0)
	_pct.add_theme_font_override("font", LoginTheme.title_font())
	row.add_child(_pct)
	return row


func _tip_row() -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.1, 0.55)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	var ic := LoginTheme.icon("sparkle", 20, LoginTheme.GOLD)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	row.add_child(LoginTheme.label("Dica:", 19, LoginTheme.GOLD))
	_tip_label = LoginTheme.label("", 19, LoginTheme.PARCHMENT)
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_tip_label)
	return panel


# ------------------------------------------------------------------ layout e efeitos

func _layout() -> void:
	var vw: float = size.x
	var vh: float = size.y
	if vw <= 0.0 or vh <= 0.0:
		return
	_particles.position = Vector2(vw / 2.0, vh + 10.0)
	_particles.emission_rect_extents = Vector2(vw / 2.0, 10.0)

	var logo_w: float = clampf(vw * 0.42, 300.0, 540.0)
	if vw < 700.0:
		logo_w = vw * 0.8
	var tex: Texture2D = _logo.texture
	var logo_h: float = logo_w * float(tex.get_height()) / float(tex.get_width())
	_logo.custom_minimum_size = Vector2(logo_w, logo_h)

	var cw: float = clampf(vw * 0.62, minf(360.0, vw - 24.0), 760.0)
	_column.custom_minimum_size.x = cw
	var h: float = _column.get_combined_minimum_size().y
	_column.size = Vector2(cw, h)
	_column.position = Vector2((vw - cw) / 2.0, maxf(12.0, (vh - h) / 2.0 - 10.0))


func _update_bar_fx() -> void:
	var w: float = _bar.size.x
	var tip_x: float = w * _shown
	_spark.visible = Motion.on() and _shown > 0.01 and _shown < 1.0
	_spark.position = Vector2(tip_x - 13.0, (_bar.size.y - 26.0) / 2.0)
	_spark.size = Vector2(26, 26)
	if Motion.on() and _shown > 0.02:
		# Faixa de luz percorrendo a parte preenchida, em ciclos.
		var cycle: float = fmod(_t, 1.8) / 1.8
		_shine.visible = true
		_shine.size = Vector2(34, _bar.size.y)
		_shine.position = Vector2(-34.0 + (tip_x + 34.0) * cycle, 0.0)
	else:
		_shine.visible = false


func _rotate_tips(delta: float) -> void:
	if _tips.size() < 2:
		return
	_tip_time += delta
	if _tip_time < TIP_INTERVAL:
		return
	_tip_time = 0.0
	_tip_index = (_tip_index + 1) % _tips.size()
	var tw := create_tween()
	tw.tween_property(_tip_label, "modulate:a", 0.0, Motion.dur(0.25))
	tw.tween_callback(func() -> void: _tip_label.text = str(_tips[_tip_index]))
	tw.tween_property(_tip_label, "modulate:a", 1.0, Motion.dur(0.25))


func _load_tips() -> void:
	if FileAccess.file_exists(TIPS_PATH):
		var f := FileAccess.open(TIPS_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.get("tips") is Array:
				for t in parsed["tips"]:
					if str(t).strip_edges() != "":
						_tips.append(str(t))
	if _tips.is_empty():
		_tip_label.get_parent().get_parent().visible = false
		return
	_tip_label.text = str(_tips[0])


func _intro() -> void:
	_fade.modulate.a = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_fade, "modulate:a", 0.0, Motion.dur(0.6))
	if Motion.on():
		_logo.pivot_offset = _logo.size / 2.0
		_logo.scale = Vector2(0.92, 0.92)
		tw.tween_property(_logo, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
