class_name LegalWindow
extends ModalWindow
# Termos de Serviço / Política de Privacidade.
# O texto vem de um JSON (data/legal/*.json) para que o texto definitivo possa
# ser colocado sem mexer no layout. Enquanto "sections" estiver vazio, a janela
# mostra um aviso de que o texto oficial ainda não foi publicado.
#
# Formato: { "title": "", "updated_at": "AAAA-MM-DD", "sections": [ {"heading": "", "body": ""} ] }


func _init(doc_path: String, fallback_title: String) -> void:
	super(fallback_title.to_upper(), 640.0)

	var doc: Dictionary = _load(doc_path)
	var title: String = str(doc.get("title", fallback_title))
	set_title(title.to_upper())
	var sections: Array = []
	var raw: Variant = doc.get("sections", [])
	if raw is Array:
		sections = raw

	if sections.is_empty():
		var note := FormMessage.new()
		note.show_info("O texto oficial deste documento ainda não foi publicado. Esta janela já está pronta para recebê-lo.")
		body.add_child(note)
		var hint := LoginTheme.label("Arquivo de conteúdo: %s" % doc_path.get_file(), 16, LoginTheme.PARCHMENT_DIM)
		body.add_child(hint)
	else:
		var updated: String = str(doc.get("updated_at", ""))
		if updated != "":
			body.add_child(LoginTheme.label("Última atualização: %s" % NewsRepository.format_date(updated), 16, LoginTheme.PARCHMENT_DIM))
		for s in sections:
			if not (s is Dictionary):
				continue
			var heading: String = str(s.get("heading", ""))
			if heading != "":
				var h := LoginTheme.label(heading, 21, LoginTheme.GOLD_LIGHT)
				h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				body.add_child(h)
			var text: String = str(s.get("body", ""))
			if text != "":
				var l := LoginTheme.label(text, 18)
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				body.add_child(l)

	var close_btn := PixelButton.new("FECHAR", PixelButton.Kind.GOLD)
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.pressed.connect(close)
	footer.add_child(close_btn)


static func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}