class_name Backpack
extends Control
# Mochila: equipamentos, atributos e inventário. Abre pelo botão de mochila do HUD
# (liberado durante o tutorial) e pausa o jogo enquanto está aberta.

signal closed

const CHAR_TEX: Texture2D = preload("res://assets/characters/tiny_dungeon.png")
const COLS := 6
const EQUIP_PX := 78
const BAG_PX := 66
const LEFT_SLOTS := ["helmet", "chest", "necklace", "ring1"]
const RIGHT_SLOTS := ["weapon", "orn1", "orn2", "ring2"]
const FILTER_NAMES := ["Todos", "Equip.", "Itens", "Materiais", "Quest"]
const FILTER_TYPES := ["", "equip", "consumable", "material", "quest"]

var _equip_buttons: Dictionary = {}
var _grid: GridContainer
var _stats_grid: GridContainer
var _filter_buttons: Array = []
var _capacity_label: Label
var _toast: Label
var _portrait: TextureRect
var _portrait_frame: PanelContainer

var _detail_icon: TextureRect
var _detail_name: Label
var _detail_rarity: Label
var _detail_info: Label
var _detail_stats: RichTextLabel
var _detail_desc: Label
var _btn_main: Button
var _btn_lock: Button
var _btn_discard: Button

var _confirm: Control
var _confirm_label: Label
var _confirm_action: Callable

var _filter: int = 0
var _sel_kind: String = "" # "" | "bag" | "equip"
var _sel_index: int = -1
var _sel_slot: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	Game.inventory_changed.connect(_on_inventory_changed)


func open() -> void:
	if not Game.backpack_unlocked:
		return
	Audio.play_sfx("open")
	_sel_kind = ""
	_sel_index = -1
	_sel_slot = ""
	_toast.text = ""
	_refresh()
	visible = true
	get_tree().paused = true


func close() -> void:
	if not visible:
		return
	Audio.play_sfx("close")
	visible = false
	_confirm.visible = false
	get_tree().paused = false
	closed.emit()


func _on_inventory_changed() -> void:
	if visible:
		_refresh()


# ------------------------------------------------------------------ construção da tela

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GameTheme.box(Color("#17142a"), GameTheme.GOLD, 5, 12, 12))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 28.0
	panel.offset_right = -28.0
	panel.offset_top = 10.0
	panel.offset_bottom = -10.0

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	# Cabeçalho
	var head := HBoxContainer.new()
	root.add_child(head)
	var title := Label.new()
	title.text = "MOCHILA"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_color", Color("#f2a060"))
	_toast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_toast)
	var close_btn := Button.new()
	close_btn.text = "  X  "
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 26)
	close_btn.pressed.connect(close)
	head.add_child(close_btn)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_left())
	body.add_child(_build_right())

	_build_confirm()


func _build_left() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(520, 0)

	var eq_row := HBoxContainer.new()
	eq_row.add_theme_constant_override("separation", 10)
	eq_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(eq_row)
	eq_row.add_child(_slot_column(LEFT_SLOTS))

	_portrait_frame = PanelContainer.new()
	_portrait_frame.custom_minimum_size = Vector2(220, 0)
	_portrait_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_row.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(190, 190)
	_portrait_frame.add_child(_portrait)

	eq_row.add_child(_slot_column(RIGHT_SLOTS))

	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", GameTheme.box(Color("#100e20"), GameTheme.GOLD_DARK, 3, 8, 10))
	col.add_child(stats_panel)
	var sv := VBoxContainer.new()
	stats_panel.add_child(sv)
	var st := Label.new()
	st.text = "Atributos Principais"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_font_size_override("font_size", 22)
	st.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	sv.add_child(st)
	_stats_grid = GridContainer.new()
	_stats_grid.columns = 2
	_stats_grid.add_theme_constant_override("h_separation", 24)
	_stats_grid.add_theme_constant_override("v_separation", 2)
	sv.add_child(_stats_grid)
	return col


func _slot_column(slots: Array) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	for s in slots:
		var slot: String = str(s)
		var b := _make_slot(EQUIP_PX)
		b.pressed.connect(func() -> void: _select_equip(slot))
		v.add_child(b)
		_equip_buttons[slot] = b
	return v


func _build_right() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Detalhes do item
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", GameTheme.box(Color("#100e20"), GameTheme.GOLD, 3, 8, 10))
	dp.custom_minimum_size = Vector2(0, 230)
	col.add_child(dp)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	dp.add_child(dv)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	dv.add_child(top)
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(72, 72)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(_detail_icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(names)
	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 26)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_child(_detail_name)
	_detail_rarity = Label.new()
	_detail_rarity.add_theme_font_size_override("font_size", 20)
	names.add_child(_detail_rarity)
	_detail_info = Label.new()
	_detail_info.add_theme_font_size_override("font_size", 18)
	_detail_info.add_theme_color_override("font_color", GameTheme.PARCHMENT)
	names.add_child(_detail_info)

	_detail_stats = RichTextLabel.new()
	_detail_stats.bbcode_enabled = true
	_detail_stats.fit_content = true
	_detail_stats.scroll_active = false
	_detail_stats.add_theme_font_size_override("normal_font_size", 19)
	dv.add_child(_detail_stats)

	_detail_desc = Label.new()
	_detail_desc.add_theme_font_size_override("font_size", 17)
	_detail_desc.add_theme_color_override("font_color", Color("#c9bfa0"))
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(_detail_desc)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	dv.add_child(btns)
	_btn_main = _make_button("Equipar", btns)
	_btn_main.pressed.connect(_on_main_pressed)
	_btn_lock = _make_button("Bloquear", btns)
	_btn_lock.pressed.connect(_on_lock_pressed)
	_btn_discard = _make_button("Descartar", btns)
	_btn_discard.pressed.connect(_on_discard_pressed)

	# Filtros
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 6)
	col.add_child(fr)
	for i in FILTER_NAMES.size():
		var fb := Button.new()
		fb.text = str(FILTER_NAMES[i])
		fb.toggle_mode = true
		fb.focus_mode = Control.FOCUS_NONE
		fb.add_theme_font_size_override("font_size", 18)
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		fb.pressed.connect(func() -> void: _set_filter(idx))
		fr.add_child(fb)
		_filter_buttons.append(fb)

	# Grade de itens
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_grid)

	# Rodapé
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	col.add_child(foot)
	_capacity_label = Label.new()
	_capacity_label.add_theme_font_size_override("font_size", 20)
	_capacity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_capacity_label)
	var org := _make_button("Organizar", foot)
	org.pressed.connect(func() -> void: Game.sort_inventory())
	return col


func _make_button(text: String, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.custom_minimum_size = Vector2(0, 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b


func _make_slot(px: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(px, px)
	b.focus_mode = Control.FOCUS_NONE
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", int(px * 0.72))
	var qty := Label.new()
	qty.name = "Qty"
	qty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty.add_theme_font_size_override("font_size", 18)
	qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(qty)
	var tag := Label.new()
	tag.name = "Tag"
	tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tag.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color("#f2dc94"))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tag)
	return b


func _build_confirm() -> void:
	_confirm = Control.new()
	_confirm.visible = false
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm)
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	_confirm.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_confirm.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", GameTheme.box(Color(0.08, 0.04, 0.06, 0.97), GameTheme.BLOOD, 4, 12, 20))
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	_confirm_label = Label.new()
	_confirm_label.add_theme_font_size_override("font_size", 24)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_confirm_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var yes := _make_button("Descartar", row)
	yes.custom_minimum_size = Vector2(200, 56)
	yes.pressed.connect(_on_confirm_yes)
	var no := _make_button("Cancelar", row)
	no.custom_minimum_size = Vector2(200, 56)
	no.pressed.connect(func() -> void: _confirm.visible = false)


# ------------------------------------------------------------------ atualização

func _refresh() -> void:
	_refresh_portrait()
	_refresh_equipment()
	_refresh_grid()
	_refresh_stats()
	_refresh_details()


func _refresh_portrait() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = CHAR_TEX
	var f: int = Game.class_frame
	atlas.region = Rect2((f % 12) * 16, (f / 12) * 16, 16, 16)
	_portrait.texture = atlas
	var weapon_id := str(Game.equipped.get("weapon", ""))
	var glow := Color("#4a3f6a")
	if weapon_id != "":
		glow = Items.rarity_color(int(Items.get_def(weapon_id).get("rarity", 0)))
	_portrait_frame.add_theme_stylebox_override("panel", GameTheme.box(Color("#1c1838"), glow, 4, 10, 8))


func _refresh_equipment() -> void:
	for slot in _equip_buttons:
		var b: Button = _equip_buttons[slot]
		var id := str(Game.equipped.get(slot, ""))
		var selected: bool = _sel_kind == "equip" and _sel_slot == slot
		_fill_slot(b, id, 1, false, false, selected)
		if id == "":
			var tag := b.get_node("Tag") as Label
			tag.text = str(Items.SLOT_NAMES.get(slot, "")).substr(0, 4)
			tag.add_theme_color_override("font_color", Color("#6a6080"))


func _refresh_grid() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var shown := 0
	for i in Game.inventory.size():
		var entry: Dictionary = Game.inventory[i]
		var def := Items.get_def(str(entry["id"]))
		if _filter > 0 and str(def["type"]) != str(FILTER_TYPES[_filter]):
			continue
		var b := _make_slot(BAG_PX)
		var selected: bool = _sel_kind == "bag" and _sel_index == i
		_fill_slot(b, str(entry["id"]), int(entry["qty"]), bool(entry["locked"]), bool(entry["new"]), selected)
		var idx := i
		b.pressed.connect(func() -> void: _select_bag(idx))
		_grid.add_child(b)
		shown += 1
	var total: int = Game.bag_capacity if _filter == 0 else maxi(shown, 18)
	while shown < total:
		var empty := _make_slot(BAG_PX)
		_fill_slot(empty, "", 1, false, false, false)
		empty.disabled = true
		_grid.add_child(empty)
		shown += 1
	_capacity_label.text = "Espaços: %d / %d" % [Game.inventory.size(), Game.bag_capacity]
	for i in _filter_buttons.size():
		(_filter_buttons[i] as Button).button_pressed = (i == _filter)


func _fill_slot(b: Button, id: String, qty: int, locked: bool, is_new: bool, selected: bool) -> void:
	var def := Items.get_def(id)
	var border := Color("#4a3f6a")
	var fill := Color("#0e0c1c")
	if id != "":
		b.icon = Items.icon(id)
		border = Items.rarity_color(int(def.get("rarity", 0)))
		fill = Color("#1a1633")
	else:
		b.icon = null
	var width := 5 if selected else 3
	if selected:
		border = Color.WHITE if id == "" else border.lightened(0.4)
	var sb := GameTheme.box(fill, border, width, 6, 2)
	sb.shadow_size = 0
	for key in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(key, sb)
	var q := b.get_node("Qty") as Label
	q.text = str(qty) if qty > 1 else ""
	var tag := b.get_node("Tag") as Label
	tag.add_theme_color_override("font_color", Color("#f2dc94"))
	if locked:
		tag.text = "Bloq"
	elif is_new:
		tag.text = "Novo"
	else:
		tag.text = ""


func _refresh_stats() -> void:
	for c in _stats_grid.get_children():
		_stats_grid.remove_child(c)
		c.queue_free()
	var gear: Dictionary = Game.gear_stats()
	for key in Items.STAT_ORDER:
		var k: String = str(key)
		var total: int = Game.stat(k)
		var bonus: int = int(gear.get(k, 0))
		var l := Label.new()
		l.text = "%s: %d%s" % [str(Items.STAT_NAMES[k]), total, str(Items.STAT_SUFFIX.get(k, ""))]
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", Color("#5ac86e") if bonus > 0 else GameTheme.PARCHMENT)
		_stats_grid.add_child(l)


func _selected_id() -> String:
	if _sel_kind == "bag" and _sel_index >= 0 and _sel_index < Game.inventory.size():
		var entry: Dictionary = Game.inventory[_sel_index]
		return str(entry["id"])
	if _sel_kind == "equip":
		return str(Game.equipped.get(_sel_slot, ""))
	return ""


func _refresh_details() -> void:
	var id := _selected_id()
	if id == "":
		_sel_kind = ""
		_detail_icon.texture = null
		_detail_name.text = "Selecione um item"
		_detail_name.add_theme_color_override("font_color", GameTheme.PARCHMENT)
		_detail_rarity.text = ""
		_detail_info.text = ""
		_detail_stats.text = ""
		_detail_desc.text = "Toque em um item da mochila ou em um espaço de equipamento."
		_btn_main.visible = false
		_btn_lock.visible = false
		_btn_discard.visible = false
		return

	var def := Items.get_def(id)
	var rarity: int = int(def["rarity"])
	var col := Items.rarity_color(rarity)
	_detail_icon.texture = Items.icon(id)
	_detail_name.text = str(def["name"])
	_detail_name.add_theme_color_override("font_color", col)
	_detail_rarity.text = "%s · %s" % [Items.rarity_name(rarity), str(Items.TYPE_NAMES.get(str(def["type"]), ""))]
	_detail_rarity.add_theme_color_override("font_color", col)

	var info := "Nível %d" % int(def.get("level", 1))
	var cls: String = str(def.get("cls", ""))
	if cls != "":
		info += " · " + str(Items.CLASS_NAMES.get(cls, cls))
	if def.has("slot"):
		info += " · " + str(Items.SLOT_NAMES.get(str(def["slot"]), ""))
	_detail_info.text = info

	_detail_stats.text = _stats_text(id)
	_detail_desc.text = str(def.get("desc", ""))

	var is_equip: bool = str(def["type"]) == "equip"
	var is_potion: bool = def.has("heal")
	_btn_main.visible = is_equip or is_potion
	if _sel_kind == "equip":
		_btn_main.text = "Desequipar"
		_btn_lock.visible = false
		_btn_discard.visible = false
	else:
		_btn_main.text = "Equipar" if is_equip else "Usar"
		_btn_lock.visible = true
		var entry: Dictionary = Game.inventory[_sel_index]
		_btn_lock.text = "Desbloquear" if bool(entry["locked"]) else "Bloquear"
		_btn_discard.visible = true


# Atributos do item; se for equipamento da mochila, compara com o que está equipado.
func _stats_text(id: String) -> String:
	var def := Items.get_def(id)
	var st: Dictionary = def.get("stats", {})
	var cur_stats: Dictionary = {}
	var compare := false
	if _sel_kind == "bag" and str(def["type"]) == "equip":
		var cur := str(Game.equipped.get(Game.target_slot(id), ""))
		if cur != "":
			cur_stats = Items.get_def(cur).get("stats", {})
			compare = true
	var lines: Array = []
	for key in Items.STAT_ORDER:
		var k: String = str(key)
		var v: int = int(st.get(k, 0))
		var c: int = int(cur_stats.get(k, 0)) if compare else 0
		if v == 0 and c == 0:
			continue
		var line := Items.stat_line(k, v)
		if compare and v != c:
			var d := v - c
			var color := "#5ac86e" if d > 0 else "#e0605a"
			line += "  [color=%s](%s%d)[/color]" % [color, "+" if d > 0 else "", d]
		lines.append(line)
	if lines.is_empty():
		return ""
	return "[color=#8fd8ff]" + "\n".join(lines) + "[/color]"


# ------------------------------------------------------------------ ações

func _set_filter(i: int) -> void:
	_filter = i
	_refresh_grid()


func _select_bag(i: int) -> void:
	_sel_kind = "bag"
	_sel_index = i
	_sel_slot = ""
	if i < Game.inventory.size():
		var entry: Dictionary = Game.inventory[i]
		entry["new"] = false
	Audio.play_sfx("click")
	_refresh()


func _select_equip(slot: String) -> void:
	if not Game.equipped.has(slot):
		_sel_kind = ""
		_refresh()
		return
	_sel_kind = "equip"
	_sel_slot = slot
	_sel_index = -1
	Audio.play_sfx("click")
	_refresh()


func _say(text: String) -> void:
	_toast.text = text


func _on_main_pressed() -> void:
	_do_main()
	_refresh()


func _do_main() -> void:
	var id := _selected_id()
	if id == "":
		return
	var def := Items.get_def(id)
	_toast.text = ""
	if _sel_kind == "equip":
		var err := Game.unequip_slot(_sel_slot)
		if err != "":
			_say(err)
		else:
			_sel_kind = ""
		return
	if str(def["type"]) == "equip":
		var err2 := Game.equip_index(_sel_index)
		if err2 != "":
			_say(err2)
		else:
			Audio.play_sfx("levelup")
			_sel_kind = ""
		return
	if def.has("heal"):
		var player := get_tree().get_first_node_in_group("player") as Player
		if player == null or player.hp >= player.max_hp:
			_say("Sua vida já está cheia.")
			return
		player.heal(int(def["heal"]))
		Audio.play_sfx("revive")
		var idx := _sel_index
		Game.remove_at(idx, 1)
		if _sel_index >= Game.inventory.size() or str(Game.inventory[_sel_index]["id"]) != id:
			_sel_kind = ""


func _on_lock_pressed() -> void:
	if _sel_kind != "bag" or _sel_index >= Game.inventory.size():
		return
	var entry: Dictionary = Game.inventory[_sel_index]
	entry["locked"] = not bool(entry["locked"])
	Game.save_bag()
	_refresh()


func _on_discard_pressed() -> void:
	if _sel_kind != "bag" or _sel_index >= Game.inventory.size():
		return
	var entry: Dictionary = Game.inventory[_sel_index]
	if bool(entry["locked"]):
		_say("Item bloqueado. Desbloqueie para descartar.")
		return
	var def := Items.get_def(str(entry["id"]))
	_confirm_label.text = "Descartar %s?" % str(def["name"])
	_confirm.visible = true


func _on_confirm_yes() -> void:
	_confirm.visible = false
	if _sel_kind != "bag" or _sel_index >= Game.inventory.size():
		return
	var entry: Dictionary = Game.inventory[_sel_index]
	if bool(entry["locked"]):
		return
	Game.remove_at(_sel_index, int(entry["qty"]))
	_sel_kind = ""
	_refresh()