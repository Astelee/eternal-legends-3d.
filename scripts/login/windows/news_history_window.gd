class_name NewsHistoryWindow
extends ModalWindow
# Histórico completo de atualizações, com filtro por categoria.

signal details_requested(item: Dictionary)

var _items: Array
var _list: VBoxContainer
var _count: Label
var _filter: String = ""


func _init(items: Array) -> void:
	super("HISTÓRICO DE ATUALIZAÇÕES", 680.0)
	_items = items

	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	body.add_child(chips)

	var group := ButtonGroup.new()
	chips.add_child(_make_chip("Todas", "", group, true))
	for cat in NewsCategories.ORDER:
		var info: Dictionary = NewsCategories.info(cat)
		chips.add_child(_make_chip(str(info["label"]), cat, group, false))

	_count = LoginTheme.label("", 16, LoginTheme.PARCHMENT_DIM)
	body.add_child(_count)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	body.add_child(_list)

	var close_btn := PixelButton.new("FECHAR", PixelButton.Kind.GOLD)
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.pressed.connect(close)
	footer.add_child(close_btn)

	_rebuild()


func _make_chip(label_text: String, category: String, group: ButtonGroup, active: bool) -> PixelButton:
	var b := PixelButton.new(label_text, PixelButton.Kind.CHIP)
	b.button_group = group
	b.button_pressed = active
	b.pressed.connect(func() -> void:
		_filter = category
		_rebuild())
	return b


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var shown: int = 0
	for it in _items:
		if _filter != "" and str(it["category"]) != _filter:
			continue
		var card := NewsCard.new(it, false)
		card.details_requested.connect(func(item: Dictionary) -> void: details_requested.emit(item))
		_list.add_child(card)
		shown += 1
	if shown == 0:
		var empty := LoginTheme.label("Nenhuma atualização nesta categoria.", 18, LoginTheme.PARCHMENT_DIM)
		_list.add_child(empty)
	_count.text = "%d %s" % [shown, "atualização" if shown == 1 else "atualizações"]