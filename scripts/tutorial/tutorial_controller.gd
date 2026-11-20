class_name TutorialController
extends Node
# Conduz o tutorial: história de abertura, falas do Ancião Aldric, objetivos na tela e
# missões práticas (mover, atacar, habilidade, perfil, desafio final). As explicações de
# combate mudam conforme a classe da conta. Ao concluir, grava o progresso e abre o
# portal para a Vila Inicial.

signal finished

const MENTOR := "Ancião Aldric"

const STORY := [
	"Há mil anos, o Cristal Eterno mantinha o equilíbrio entre a luz e as trevas no reino de Aurelia.",
	"Então a Noite Sem Fim despertou. O cristal se partiu em fragmentos e criaturas sombrias começaram a surgir das ruínas.",
	"Heróis de todo o reino marcham para recuperar os fragmentos e reacender a Chama Eterna. Poucos retornam.",
	"%CLASS%",
	"Você acorda numa clareira diante das muralhas da Vila Inicial, ferido e sem lembranças. Um velho se aproxima..."
]

const STORY_CLASS := {
	"warrior": "Você é um Guerreiro: forjado em aço e coragem, sua espada abre caminho onde outros recuam.",
	"archer": "Você é um Arqueiro: seu olhar não erra, e cada flecha sua carrega a esperança do reino.",
	"mage": "Você é um Mago: as chamas arcanas obedecem ao seu cajado, e o cristal reconhece o seu poder."
}

const TEXT_ATTACK := {
	"warrior": "Slimes! Toque em ESPADA (botão grande, canto inferior direito) para golpear. A espada acerta quem está perto, na direção em que você olha. Aproxime-se e corte!",
	"archer": "Slimes! Toque em FLECHA (botão grande, canto inferior direito) para disparar o arco. A flecha voa reta e acerta de longe: mire e mantenha distância!",
	"mage": "Slimes! Toque em MAGIA (botão grande, canto inferior direito) para lançar uma esfera arcana. Ela explode ao atingir e fere quem estiver por perto. Lançar leva um instante: espere o brilho no cajado!"
}

const TEXT_SKILL := {
	"warrior": "Agora a habilidade GIRO: o botão azul, ao lado do de ataque. Você gira a espada e acerta todos ao redor. Depois de usar, ela precisa recarregar. Use o Giro e derrote os inimigos!",
	"archer": "Agora a habilidade RAJADA: o botão azul, ao lado do de ataque. Você dispara três flechas em leque, ótimo contra grupos. Depois de usar, ela precisa recarregar. Use a Rajada e derrote os inimigos!",
	"mage": "Agora a habilidade NOVA: o botão azul, ao lado do de ataque. Uma explosão arcana atinge todos ao seu redor. Depois de usar, ela precisa recarregar. Use a Nova e derrote os inimigos!"
}

var _player: Player
var _hud: Hud
var _map: TutorialMap
var _joystick: VirtualJoystick
var _cid: String = "warrior"
var _data: Dictionary = {}

var _layer: CanvasLayer
var _root: Control
var _tracker_label: Label
var _tracker: PanelContainer
var _story_box: Control
var _story_label: Label
var _dialog_box: Control
var _dialog_text: Label
var _tween: Tween

var _typing: bool = false
var _modal: bool = false
var _skip_story: bool = false
var _wave: Array = [] # inimigos da etapa (podem ser liberados ao morrer)
var _skill_flag: bool = false
var _profile_flag: bool = false
var _move_target: Vector2 = Vector2.ZERO

signal advance


func setup(player: Player, hud: Hud, map: TutorialMap, joystick: VirtualJoystick) -> void:
	_player = player
	_hud = hud
	_map = map
	_joystick = joystick
	_cid = Game.combat_class_id()
	_data = ClassCombat.get_data(_cid)
	process_mode = Node.PROCESS_MODE_ALWAYS # tweens e diálogos funcionam com o jogo pausado
	_build_ui()
	_player.skill_used.connect(func() -> void: _skill_flag = true)
	_hud.profile_opened.connect(func() -> void: _profile_flag = true)
	_run()


func _exit_tree() -> void:
	# Nunca deixa o jogo travado em pausa se o controlador for removido no meio de um diálogo.
	if _modal and get_tree() != null:
		get_tree().paused = false
	if _hud != null and is_instance_valid(_hud):
		_hud.input_blocked = false


func _alive() -> bool:
	return is_inside_tree() and _map != null and is_instance_valid(_map) and _map.is_inside_tree()


# ------------------------------------------------------------------ roteiro

func _run() -> void:
	await _story()
	if not _alive():
		return
	await _step_move()
	if not _alive():
		return
	await _step_attack()
	if not _alive():
		return
	await _step_skill()
	if not _alive():
		return
	await _step_profile()
	if not _alive():
		return
	await _step_trial()
	if not _alive():
		return
	await _step_finish()


func _step_move() -> void:
	_set_objective("Ande até o marcador dourado")
	await _say("Acorde, jovem herói! Use o JOYSTICK (canto inferior esquerdo) para andar. Quanto mais longe você arrasta, mais rápido corre. Vá até o marcador dourado.")
	if not _alive():
		return
	_move_target = _map.cell_pos(TutorialMap.POINTS["move"])
	_map.set_marker(_move_target)
	await _wait_until(_cond_move)
	if not _alive():
		return
	_map.clear_marker()
	Audio.play_sfx("levelup")


func _step_attack() -> void:
	await _say(str(TEXT_ATTACK[_cid]))
	if not _alive():
		return
	_wave.clear()
	_spawn("slime", TutorialMap.POINTS["fight_a"])
	_spawn("slime", TutorialMap.POINTS["fight_b"])
	_map.set_marker(_map.cell_pos(TutorialMap.POINTS["fight"]))
	await _wait_until(_cond_attack)
	if not _alive():
		return
	_map.clear_marker()
	Audio.play_sfx("levelup")


func _step_skill() -> void:
	await _say(str(TEXT_SKILL[_cid]))
	if not _alive():
		return
	_skill_flag = false
	_wave.clear()
	_spawn("slime", TutorialMap.POINTS["skill_a"])
	_spawn("bat", TutorialMap.POINTS["skill_b"])
	_spawn("slime", TutorialMap.POINTS["skill_c"])
	_map.set_marker(_map.cell_pos(TutorialMap.POINTS["skill"]))
	await _wait_until(_cond_skill)
	if not _alive():
		return
	_map.clear_marker()
	Audio.play_sfx("levelup")


func _step_profile() -> void:
	_profile_flag = false
	_set_objective("Toque no seu crachá (canto superior esquerdo) para abrir o perfil")
	await _say("Seu crachá, no canto superior esquerdo, mostra vida, experiência e nível. Toque nele para abrir o PERFIL, onde você muda o nome e o volume. Lembre-se: a sua classe é permanente e nunca muda.")
	if not _alive():
		return
	await _wait_until(_cond_profile)
	if not _alive():
		return
	Audio.play_sfx("levelup")


func _step_trial() -> void:
	await _say("Aranhas! São mais fortes que os slimes. Fique de olho na sua vida: frascos vermelhos no chão curam quando você está ferido. Derrote as duas para provar o seu valor!")
	if not _alive():
		return
	_wave.clear()
	_spawn("spider", TutorialMap.POINTS["trial_a"])
	_spawn("spider", TutorialMap.POINTS["trial_b"])
	_map.spawn_potion(TutorialMap.POINTS["potion"])
	_map.set_marker(_map.cell_pos(TutorialMap.POINTS["trial"]))
	await _wait_until(_cond_trial)
	if not _alive():
		return
	_map.clear_marker()
	Audio.play_sfx("levelup")


func _step_finish() -> void:
	Game.complete_tutorial()
	_map.open_exit()
	await _say("Você conseguiu, %s! Os portões da Vila Inicial estão abertos. Siga pela estrada até o portal dourado. Que a Chama Eterna guie os seus passos!" % Game.player_name)
	if not _alive():
		return
	_map.set_marker(_map.cell_pos(TutorialMap.POINTS["exit"]))
	_set_objective("Entre no portal para ir à Vila Inicial")
	finished.emit()


# ------------------------------------------------------------------ condições das missões

func _cond_move() -> bool:
	return _player.global_position.distance_to(_move_target) < 14.0


func _cond_attack() -> bool:
	var dead := _dead_count()
	_set_objective("Derrote os slimes com %s (%d/%d)" % [str(_data["attack_name"]), dead, _wave.size()])
	return dead >= _wave.size()


func _cond_skill() -> bool:
	var dead := _dead_count()
	if not _skill_flag:
		_set_objective("Use a habilidade %s (botão azul)" % str(_data["skill_name"]))
		# Se o jogador derrotou todos sem usar a habilidade, chegam reforços.
		if dead >= _wave.size():
			_spawn("slime", TutorialMap.POINTS["skill_a"])
			_spawn("slime", TutorialMap.POINTS["skill_c"])
		return false
	_set_objective("Derrote os inimigos (%d/%d)" % [dead, _wave.size()])
	return dead >= _wave.size()


func _cond_profile() -> bool:
	# Concluída quando o perfil foi aberto e já foi fechado de novo.
	return _profile_flag and not get_tree().paused


func _cond_trial() -> bool:
	var dead := _dead_count()
	_set_objective("Derrote as aranhas (%d/%d)" % [dead, _wave.size()])
	return dead >= _wave.size()


func _spawn(kind: String, cell: Vector2i) -> void:
	_wave.append(_map.spawn_enemy(kind, cell))


func _dead_count() -> int:
	var n := 0
	for e in _wave:
		if not is_instance_valid(e) or (e as Enemy).hp <= 0:
			n += 1
	return n


func _wait_until(cond: Callable) -> void:
	while _alive() and not cond.call():
		await get_tree().process_frame


# ------------------------------------------------------------------ interface

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 8
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_root = Control.new()
	_root.theme = GameTheme.build()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Painel de objetivo (topo, centro)
	_tracker = PanelContainer.new()
	_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tracker.visible = false
	_root.add_child(_tracker)
	_tracker.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_tracker.offset_left = -300.0
	_tracker.offset_right = 300.0
	_tracker.offset_top = 104.0
	_tracker.offset_bottom = 160.0
	_tracker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tracker_label = Label.new()
	_tracker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tracker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_label.add_theme_font_size_override("font_size", 22)
	_tracker_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	_tracker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tracker.add_child(_tracker_label)

	_build_dialog()
	_build_story()


func _build_dialog() -> void:
	_dialog_box = Control.new()
	_dialog_box.visible = false
	_dialog_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialog_box.gui_input.connect(_on_dialog_input)
	_root.add_child(_dialog_box)
	_dialog_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog_box.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 120.0
	panel.offset_right = -120.0
	panel.offset_top = -270.0
	panel.offset_bottom = -24.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)

	var who := Label.new()
	who.text = MENTOR
	who.add_theme_font_size_override("font_size", 28)
	who.add_theme_color_override("font_color", GameTheme.GOLD)
	who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(who)

	_dialog_text = Label.new()
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_text.custom_minimum_size = Vector2(0, 120)
	_dialog_text.add_theme_font_size_override("font_size", 24)
	_dialog_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_dialog_text)

	var hint := Label.new()
	hint.text = "Toque para continuar  ▶"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", GameTheme.GOLD_DARK)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hint)


func _build_story() -> void:
	_story_box = Control.new()
	_story_box.visible = false
	_story_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_story_box.gui_input.connect(_on_story_input)
	_root.add_child(_story_box)
	_story_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color("#0c0910")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_box.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_box.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_story_label = Label.new()
	_story_label.custom_minimum_size = Vector2(900, 0)
	_story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_label.add_theme_font_size_override("font_size", 34)
	_story_label.add_theme_color_override("font_color", GameTheme.PARCHMENT)
	_story_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_story_label)

	var hint := Label.new()
	hint.text = "Toque para continuar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", GameTheme.GOLD_DARK)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_box.add_child(hint)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -200.0
	hint.offset_right = 200.0
	hint.offset_top = -70.0
	hint.offset_bottom = -30.0
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH

	var skip := Button.new()
	skip.text = "Pular história  ▶▶"
	skip.focus_mode = Control.FOCUS_NONE
	skip.pressed.connect(_on_skip_story)
	_story_box.add_child(skip)
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -300.0
	skip.offset_right = -20.0
	skip.offset_top = 20.0
	skip.offset_bottom = 84.0
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _set_objective(text: String) -> void:
	if _tracker_label == null:
		return
	_tracker.visible = true
	if _tracker_label.text != text:
		_tracker_label.text = text


# Pausa o jogo e bloqueia os botões de ação enquanto um texto está na tela.
func _set_modal(on: bool) -> void:
	_modal = on
	_hud.input_blocked = on
	_joystick.reset_input()
	get_tree().paused = on


func _story() -> void:
	_set_modal(true)
	_story_box.visible = true
	_story_box.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(_story_box, "modulate:a", 1.0, 0.5)
	var pages: Array[String] = []
	for page in STORY:
		pages.append(str(STORY_CLASS[_cid]) if page == "%CLASS%" else str(page))
	for text in pages:
		if _skip_story:
			break
		_story_label.text = text
		_story_label.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(_story_label, "modulate:a", 1.0, 0.6)
		await advance
		if not is_inside_tree():
			return
	var out := create_tween()
	out.tween_property(_story_box, "modulate:a", 0.0, 0.4)
	await out.finished
	if not is_inside_tree():
		return
	_story_box.visible = false
	_set_modal(false)


func _on_story_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance.emit()


func _on_skip_story() -> void:
	_skip_story = true
	advance.emit()


# Mostra uma fala do Ancião (texto surge letra a letra; um toque completa, outro avança).
func _say(text: String) -> void:
	_set_modal(true)
	_dialog_text.text = text
	_dialog_text.visible_ratio = 0.0
	_dialog_box.visible = true
	_typing = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_dialog_text, "visible_ratio", 1.0, maxf(text.length() * 0.018, 0.3))
	_tween.finished.connect(func() -> void: _typing = false)
	Audio.play_sfx("open")
	await advance
	if not is_inside_tree():
		return
	_dialog_box.visible = false
	_set_modal(false)


func _on_dialog_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _typing:
		if _tween != null:
			_tween.kill()
		_dialog_text.visible_ratio = 1.0
		_typing = false
	else:
		advance.emit()