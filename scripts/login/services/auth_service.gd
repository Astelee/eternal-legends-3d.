class_name AuthService
extends Node
# Cliente HTTP do servidor de autenticação.
#
# IMPORTANTE: este serviço NÃO simula login. Se nenhum servidor estiver
# configurado, toda chamada falha com code = "not_configured".
#
# Configuração (a primeira que existir vence):
#   1. variável de ambiente EL_AUTH_URL
#   2. Project Settings: eternal_legends/auth/base_url   (ver project.godot)
#
# Contrato esperado do backend: docs/LOGIN_SCREEN.md
#
# Toda função devolve um Dictionary:
#   { "ok": bool, "status": int, "code": String, "message": String,
#     "errors": Dictionary (campo -> mensagem), "data": Dictionary }

const TIMEOUT_SECONDS := 15.0


func base_url() -> String:
	var env: String = OS.get_environment("EL_AUTH_URL").strip_edges()
	if env != "":
		return env.rstrip("/")
	var setting: String = str(ProjectSettings.get_setting("eternal_legends/auth/base_url", "")).strip_edges()
	return setting.rstrip("/")


func is_configured() -> bool:
	return base_url() != ""


func login(identifier: String, password: String, remember: bool) -> Dictionary:
	return await _post("/auth/login", {
		"identifier": identifier.strip_edges(),
		"password": password,
		"remember": remember
	})


func register(username: String, email: String, password: String) -> Dictionary:
	return await _post("/auth/register", {
		"username": username.strip_edges(),
		"email": email.strip_edges(),
		"password": password,
		"accepted_terms": true,
		"accepted_privacy": true
	})


func request_password_reset(email: String) -> Dictionary:
	return await _post("/auth/password-reset", {"email": email.strip_edges()})


# ------------------------------------------------------------------ interno

func _post(path: String, payload: Dictionary) -> Dictionary:
	if not is_configured():
		push_warning("AuthService: servidor não configurado (eternal_legends/auth/base_url ou EL_AUTH_URL).")
		await get_tree().process_frame
		return _fail("not_configured", "O servidor de autenticação ainda não está configurado.", 0)

	var req := HTTPRequest.new()
	req.timeout = TIMEOUT_SECONDS
	add_child(req)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	var err: int = req.request(base_url() + path, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		req.queue_free()
		return _fail("request_failed", "Não foi possível iniciar a conexão. Tente novamente.", 0)

	var res: Array = await req.request_completed
	req.queue_free()
	var result: int = res[0]
	var code: int = res[1]
	var body: PackedByteArray = res[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return _fail("network", "Sem conexão com o servidor. Verifique sua internet e tente novamente.", 0)

	var data: Dictionary = {}
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary:
		data = parsed

	if code >= 200 and code < 300:
		return {"ok": true, "status": code, "code": "ok", "message": str(data.get("message", "")), "errors": {}, "data": data}
	return _http_error(code, data)


func _http_error(status: int, data: Dictionary) -> Dictionary:
	var server_message: String = str(data.get("message", ""))
	var field_errors: Dictionary = {}
	var raw_errors: Variant = data.get("errors", null)
	if raw_errors is Dictionary:
		field_errors = raw_errors

	var code: String = "error"
	var message: String = server_message
	match status:
		400, 422:
			code = "invalid"
			if message == "":
				message = "Verifique os dados informados."
		401:
			code = "unauthorized"
			if message == "":
				message = "Usuário ou senha incorretos."
		403:
			code = "forbidden"
			if message == "":
				message = "Acesso negado para esta conta."
		409:
			code = "conflict"
			if message == "":
				message = "Este usuário ou e-mail já está cadastrado."
		429:
			code = "rate_limited"
			if message == "":
				message = "Muitas tentativas. Aguarde um momento e tente de novo."
		_:
			if status >= 500:
				code = "server_error"
				message = "O servidor encontrou um problema. Tente novamente em instantes."
			elif message == "":
				message = "Não foi possível concluir a solicitação."
	var out: Dictionary = _fail(code, message, status)
	out["errors"] = field_errors
	out["data"] = data
	return out


func _fail(code: String, message: String, status: int) -> Dictionary:
	return {"ok": false, "status": status, "code": code, "message": message, "errors": {}, "data": {}}