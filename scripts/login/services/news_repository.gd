class_name NewsRepository
extends Node
# Fonte das "Últimas atualizações".
#
# Hoje: lê data/news.json (conteúdo de EXEMPLO, marcado com is_demo = true).
# Depois: defina eternal_legends/news/url (ou EL_NEWS_URL) apontando para a API
# do painel administrativo. A resposta deve ter o mesmo formato do arquivo local
# ({"items": [...]}) — a interface não precisa mudar.
#
# Item: { id, category, title, published_at (AAAA-MM-DD), summary, body, is_demo }

const LOCAL_PATH := "res://data/news.json"
const TIMEOUT_SECONDS := 10.0


func remote_url() -> String:
	var env: String = OS.get_environment("EL_NEWS_URL").strip_edges()
	if env != "":
		return env
	return str(ProjectSettings.get_setting("eternal_legends/news/url", "")).strip_edges()


# Devolve { "items": Array[Dictionary], "source": "remote"|"local", "error": String }
func fetch() -> Dictionary:
	var url: String = remote_url()
	if url != "":
		var remote: Dictionary = await _fetch_remote(url)
		if bool(remote.get("ok", false)):
			return {"items": remote["items"], "source": "remote", "error": ""}
		return {"items": _load_local(), "source": "local", "error": "Não foi possível atualizar as notícias agora."}
	return {"items": _load_local(), "source": "local", "error": ""}


func _fetch_remote(url: String) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = TIMEOUT_SECONDS
	add_child(req)
	var err: int = req.request(url, PackedStringArray(["Accept: application/json"]))
	if err != OK:
		req.queue_free()
		return {"ok": false}
	var res: Array = await req.request_completed
	req.queue_free()
	var result: int = res[0]
	var code: int = res[1]
	var body: PackedByteArray = res[3]
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		return {"ok": false}
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary and parsed.get("items") is Array:
		return {"ok": true, "items": normalize(parsed["items"])}
	return {"ok": false}


func _load_local() -> Array:
	if not FileAccess.file_exists(LOCAL_PATH):
		return []
	var f := FileAccess.open(LOCAL_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.get("items") is Array:
		return normalize(parsed["items"])
	return []


# Garante todos os campos e ordena do mais novo para o mais antigo.
static func normalize(raw: Array) -> Array:
	var out: Array = []
	for entry in raw:
		if not (entry is Dictionary):
			continue
		var title: String = str(entry.get("title", "")).strip_edges()
		if title == "":
			continue
		var category: String = str(entry.get("category", "notice"))
		if not NewsCategories.INFO.has(category):
			category = "notice"
		out.append({
			"id": str(entry.get("id", title)),
			"category": category,
			"title": title,
			"published_at": str(entry.get("published_at", "")),
			"summary": str(entry.get("summary", "")),
			"body": str(entry.get("body", entry.get("summary", ""))),
			"is_demo": bool(entry.get("is_demo", false))
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["published_at"]) > str(b["published_at"]))
	return out


# "2026-11-18" -> "18/11/2026"
static func format_date(iso: String) -> String:
	var parts: PackedStringArray = iso.substr(0, 10).split("-")
	if parts.size() == 3:
		return "%s/%s/%s" % [parts[2], parts[1], parts[0]]
	return iso