class_name NewsDetailWindow
extends ModalWindow
# Detalhes de uma notícia (corpo completo, rolável).


func _init(item: Dictionary) -> void:
	super("DETALHES", 600.0)

	var top := HFlowContainer.new()
	top.add_theme_constant_override("h_separation", 8)
	top.add_theme_constant_override("v_separation", 6)
	top.add_child(NewsCard.category_chip(str(item["category"])))
	if bool(item["is_demo"]):
		top.add_child(NewsCard.demo_chip())
	top.add_child(LoginTheme.label(NewsRepository.format_date(str(item["published_at"])), 16, LoginTheme.PARCHMENT_DIM))
	body.add_child(top)

	var title := LoginTheme.label(str(item["title"]), 24, LoginTheme.GOLD_LIGHT)
	title.add_theme_font_override("font", LoginTheme.title_font())
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(title)

	if bool(item["is_demo"]):
		var note := FormMessage.new()
		note.show_info("Conteúdo demonstrativo. Não é uma notícia real do jogo.")
		body.add_child(note)

	for paragraph in str(item["body"]).split("\n\n", false):
		var l := LoginTheme.label(paragraph.strip_edges(), 18)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(l)

	var close_btn := PixelButton.new("FECHAR", PixelButton.Kind.GOLD)
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.pressed.connect(close)
	footer.add_child(close_btn)