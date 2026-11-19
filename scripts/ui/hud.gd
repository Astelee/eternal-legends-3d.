class_name Hud
extends Control
# Interface do jogo: crachá de perfil (canto superior esquerdo), botões de ação
# redondos (canto inferior direito) e painel de perfil (abre ao tocar no crachá).

signal attack_pressed
signal revive_pressed
signal class_selected(frame: int)
signal profile_opened

const CHAR_TEX: Texture2D = preload("res://assets/characters/tiny_dungeon.png")
const ICON_ATTACK: Texture2D = preload("res://assets/ui/icon_attack.png")
const ICON_REVIVE: Texture2D = preload("res://assets/ui/icon_revive.png")
const COLS := 12

var _badge_avatar: TextureRect
var _badge_name: Label
var _badge_level: Label
var _hp_bar: ProgressBar
var _xp_bar: ProgressBar

var _attack_button: Button
var _revive_box: CenterContainer
var _location_label: Label

var _profile: Control
var _profile_avatar: TextureRect
var _name_edit: LineEdit
var _class_label: Label
var _stats_label: Label
var _class_buttons: Dictionary = {}
var _music_slider: HSlider
var _sfx_slider: HSlider
var _hp: int = 100
var _max_hp: int = 100


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # o painel de perfil funciona com o jogo pausado
	theme = GameTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_badge()
	_build_actions()
	_build_location()
	_build_profile_panel()
	Game.profile_changed.connect(_refresh_profile)
	_refresh_profile()


# ---------------------------------------------------------------- API pública

func set_hp(hp: int, max_hp: int) -> void:
	_hp = hp
	_max_hp = max_hp
	if _hp_bar:
		_hp_bar.max_value = max_hp
		_hp_bar.value = hp
	_update_stats_label()


func set_dead(dead: bool) -> void:
	if _revive_box:
		_revive_box.visible = dead
	if _attack_button:
		_attack_button.disabled = dead


func set_location(text: String) -> void:
	if _location_label == null:
		return
	_location_label.text = text
	_location_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(_location_label, "modulate:a", 0.35, 1.0)


# ---------------------------------------------------------------- crachá de perfil

func _build_badge() -> void:
	var badge := PanelContainer.new()
	badge.position = Vector2(16, 16)
	add_child(badge)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	badge.add_child(row)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.INK, GameTheme.GOLD_DARK, 3, 8, 4))
	row.add_child(frame)
	_badge_avatar = TextureRect.new()
	_badge_avatar.custom_minimum_size = Vector2(64, 64)
	_badge_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_badge_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_badge_avatar)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(210, 0)
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)

	_badge_name = Label.new()
	_badge_name.add_theme_font_size_override("font_size", 26)
	col.add_child(_badge_name)

	_badge_level = Label.new()
	_badge_level.add_theme_font_size_override("font_size", 18)
	_badge_level.add_theme_color_override("font_color", GameTheme.GOLD)
	col.add_child(_badge_level)

	_hp_bar = _make_bar(GameTheme.BLOOD, 16)
	col.add_child(_hp_bar)
	_xp_bar = _make_bar(GameTheme.MANA, 10)
	col.add_child(_xp_bar)

	_set_mouse_ignore(row)
	badge.mouse_filter = Control.MOUSE_FILTER_STOP
	badge.gui_input.connect(_on_badge_input)


func _make_bar(color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, height)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("fill", GameTheme.bar_fill(color))
	return bar


func _on_badge_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_profile()


func _set_mouse_ignore(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore(child)


# ---------------------------------------------------------------- botões de ação

func _build_actions() -> void:
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	box.offset_left = -260.0
	box.offset_top = -240.0
	box.offset_right = -20.0
	box.offset_bottom = -20.0
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN

	_attack_button = _make_round_button(box, ICON_ATTACK, GameTheme.GOLD, Vector2(70, 20), 150, 96, "Atacar")
	_attack_button.pressed.connect(func() -> void: attack_pressed.emit())

	_build_revive_overlay()


# Só aparece quando o personagem morre em luta.
func _build_revive_overlay() -> void:
	_revive_box = CenterContainer.new()
	_revive_box.visible = false
	_revive_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_revive_box)
	_revive_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GameTheme.box(Color(0.08, 0.04, 0.06, 0.94), GameTheme.BLOOD, 4, 12, 20))
	_revive_box.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = "VOCÊ CAIU EM BATALHA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#e0605a"))
	v.add_child(title)

	var b := Button.new()
	b.text = "Reviver"
	b.icon = ICON_REVIVE
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 48)
	b.custom_minimum_size = Vector2(320, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: revive_pressed.emit())
	v.add_child(b)


func _build_location() -> void:
	_location_label = Label.new()
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_location_label.add_theme_font_size_override("font_size", 28)
	_location_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	_location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_location_label)
	_location_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_location_label.offset_left = -220.0
	_location_label.offset_right = 220.0
	_location_label.offset_top = 56.0
	_location_label.offset_bottom = 96.0


func _make_round_button(parent: Control, icon: Texture2D, accent: Color, pos: Vector2, size: int, icon_px: int, caption: String) -> Button:
	var b := Button.new()
	b.position = pos
	b.custom_minimum_size = Vector2(size, size)
	b.size = Vector2(size, size)
	b.icon = icon
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_NONE
	parent.add_child(b)
	_style_round(b, accent, size, icon_px)

	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(pos.x - 20.0, pos.y + size + 2.0)
	label.size = Vector2(size + 40.0, 26.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	b.set_meta("caption", label)
	return b


func _style_round(b: Button, accent: Color, size: int, icon_px: int) -> void:
	var margin := (size - icon_px) / 2
	var styles := GameTheme.round_button_theme(accent, size, margin)
	for key in styles:
		b.add_theme_stylebox_override(key, styles[key])
	b.add_theme_stylebox_override("hover_pressed", styles["pressed"])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


# ---------------------------------------------------------------- painel de perfil

func _build_profile_panel() -> void:
	_profile = Control.new()
	_profile.visible = false
	_profile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_profile)
	_profile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	_profile.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_profile.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = "PERFIL DO HERÓI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	v.add_child(title)

	# Avatar + nome + resumo
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	v.add_child(top)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.INK, GameTheme.GOLD, 4, 10, 8))
	top.add_child(frame)
	_profile_avatar = TextureRect.new()
	_profile_avatar.custom_minimum_size = Vector2(128, 128)
	_profile_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_profile_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_profile_avatar)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 8)
	top.add_child(info)

	var name_title := Label.new()
	name_title.text = "Nome"
	name_title.add_theme_font_size_override("font_size", 18)
	name_title.add_theme_color_override("font_color", GameTheme.GOLD)
	info.add_child(name_title)

	_name_edit = LineEdit.new()
	_name_edit.max_length = 14
	_name_edit.placeholder_text = "Seu nome"
	_name_edit.text_submitted.connect(func(_t: String) -> void: _commit_name())
	_name_edit.focus_exited.connect(_commit_name)
	info.add_child(_name_edit)

	_class_label = Label.new()
	_class_label.add_theme_font_size_override("font_size", 22)
	info.add_child(_class_label)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 20)
	info.add_child(_stats_label)

	# Classes
	var class_title := Label.new()
	class_title.text = "Classe"
	class_title.add_theme_font_size_override("font_size", 18)
	class_title.add_theme_color_override("font_color", GameTheme.GOLD)
	v.add_child(class_title)

	var class_row := HBoxContainer.new()
	class_row.add_theme_constant_override("separation", 10)
	v.add_child(class_row)
	var group := ButtonGroup.new()
	var selected_style := GameTheme.box(Color("#4a3a1c"), GameTheme.GOLD_LIGHT, 4, 8, 12)
	for c in Game.CLASSES:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = c["name"]
		b.icon = _avatar_texture(c["frame"])
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 48)
		b.add_theme_font_size_override("font_size", 22)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("pressed", selected_style)
		b.add_theme_stylebox_override("hover_pressed", selected_style)
		b.toggled.connect(_on_class_toggled.bind(c["frame"]))
		class_row.add_child(b)
		_class_buttons[c["frame"]] = b

	# Áudio
	var audio_title := Label.new()
	audio_title.text = "Áudio"
	audio_title.add_theme_font_size_override("font_size", 18)
	audio_title.add_theme_color_override("font_color", GameTheme.GOLD)
	v.add_child(audio_title)

	_music_slider = _make_slider_row(v, "Música")
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider = _make_slider_row(v, "Efeitos")
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_sfx_slider.drag_ended.connect(func(_changed: bool) -> void: Audio.play_sfx("click"))

	var close := Button.new()
	close.text = "Fechar"
	close.custom_minimum_size = Vector2(0, 64)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_profile)
	v.add_child(close)


func _make_slider_row(parent: Control, label_text: String) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(110, 0)
	l.add_theme_font_size_override("font_size", 22)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(0, 36)
	row.add_child(s)
	return s


func open_profile() -> void:
	if _profile.visible:
		return
	Audio.play_sfx("open")
	_refresh_profile()
	_profile.visible = true
	get_tree().paused = true
	profile_opened.emit()


func close_profile() -> void:
	_commit_name()
	if not _profile.visible:
		return
	Audio.play_sfx("close")
	_profile.visible = false
	get_tree().paused = false


func _commit_name() -> void:
	var n := _name_edit.text.strip_edges()
	if n.is_empty():
		n = "Herói"
	if n != Game.player_name:
		Game.player_name = n
		Game.save_profile()
		Game.profile_changed.emit()
	else:
		_name_edit.text = n


func _on_class_toggled(pressed: bool, frame: int) -> void:
	if not pressed or frame == Game.class_frame:
		return
	Game.class_frame = frame
	Game.save_profile()
	Audio.play_sfx("click")
	class_selected.emit(frame)
	Game.profile_changed.emit()


func _on_music_changed(value: float) -> void:
	Game.music_volume = value
	Audio.apply_volumes()
	Game.save_profile()


func _on_sfx_changed(value: float) -> void:
	Game.sfx_volume = value
	Audio.apply_volumes()
	Game.save_profile()


# ---------------------------------------------------------------- atualização

func _refresh_profile() -> void:
	var tex := _avatar_texture(Game.class_frame)
	_badge_avatar.texture = tex
	_profile_avatar.texture = tex
	_badge_name.text = Game.player_name
	_badge_level.text = "Nv %d  %s" % [Game.level, Game.class_name_of(Game.class_frame)]
	_xp_bar.max_value = Game.xp_to_next()
	_xp_bar.value = Game.xp
	_hp_bar.max_value = _max_hp
	_hp_bar.value = _hp
	_class_label.text = "%s  •  Nível %d" % [Game.class_name_of(Game.class_frame), Game.level]
	if _name_edit.text != Game.player_name:
		_name_edit.text = Game.player_name
	if _class_buttons.has(Game.class_frame):
		(_class_buttons[Game.class_frame] as Button).set_pressed_no_signal(true)
	_music_slider.set_value_no_signal(Game.music_volume)
	_sfx_slider.set_value_no_signal(Game.sfx_volume)
	_update_stats_label()


func _update_stats_label() -> void:
	if _stats_label:
		_stats_label.text = "Vida %d/%d   XP %d/%d" % [_hp, _max_hp, Game.xp, Game.xp_to_next()]


func _avatar_texture(frame: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = CHAR_TEX
	at.region = Rect2((frame % COLS) * 16, (frame / COLS) * 16, 16, 16)
	return at