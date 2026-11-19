class_name NewsCategories
extends RefCounted
# Categorias visuais das notícias. Para criar uma categoria nova basta
# adicionar uma entrada aqui; o layout não muda.

const ORDER := ["update", "content", "event", "fix", "maintenance", "notice"]

const INFO := {
	"update": {"label": "Atualização", "color": Color("#7cc0ff"), "icon": "sparkle"},
	"content": {"label": "Novo conteúdo", "color": Color("#8be39a"), "icon": "star"},
	"event": {"label": "Evento", "color": Color("#f2dc94"), "icon": "star"},
	"fix": {"label": "Correção", "color": Color("#c9a4ff"), "icon": "bug"},
	"maintenance": {"label": "Manutenção", "color": Color("#ffb070"), "icon": "gear"},
	"notice": {"label": "Aviso", "color": Color("#ff8a80"), "icon": "alert"}
}


static func info(category: String) -> Dictionary:
	if INFO.has(category):
		return INFO[category]
	return INFO["notice"]