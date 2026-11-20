class_name AuthService
extends Node
# Cliente do Firebase (Authentication + Firestore) por REST. Não existe servidor próprio.
#
# IMPORTANTE: este serviço NÃO simula login. Sem configuração, toda chamada falha
# com code = "not_configured".
#
# Configuração (project.godot, seção [eternal_legends]):
#   firebase/api_key     chave Web do projeto (Firebase > Configurações do projeto)
#   firebase/project_id  ID do projeto
# A chave Web do Firebase não é segredo; a segurança vem das regras do Firestore
# (firebase/firestore.rules). Passo a passo: docs/FIREBASE.md
#
# Toda função devolve um Dictionary:
#   { "ok": bool, "status": int, "code": String, "message": String,
#     "errors": Dictionary (campo -> mensagem), "data": Dictionary }

const TIMEOUT_SECONDS := 15.0
const IDENTITY_URL := "https://identitytoolkit.googleapis.com/v1/accounts:"
const FIRESTORE_URL := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents"


func api_key() -> String:
	return str(ProjectSettings.get_setting("eternal_legends/firebase/api_key", "")).strip_edges()


func project_id() -> String:
	return str(ProjectSettings.get_setting("eternal_legends/firebase/project_id", "")).strip_edges()


func is_configured() -> bool:
	return api_key() != "" and project_id() != ""


# ------------------------------------------------------------------ autenticação

# O Firebase entra por e-mail e senha. O nome de usuário é só o nome de exibição.
func login(identifier: String, password: String, _remember: bool) -> Dictionary:
	var email: String = identifier.strip_edges()
	if not email.contains("@"):
		var msg := "Entre com o e-mail da sua conta."
		var out: Dictionary = _fail("invalid", msg, 0)
		out["errors"] = {"identifier": msg}
		await get_tree().process_frame
		return out
	var res: Dictionary = await _identity("signInWithPassword", {
		"email": email,
		"password": password,
		"returnSecureToken": true
	})
	if not res["ok"]:
		return res
	return _session_result(res, "")


func register(username: String, email: String, password: String) -> Dictionary:
	var display_name: String = username.strip_edges()
	var res: Dictionary = await _identity("signUp", {
		"email": email.strip_edges(),
		"password": password,
		"returnSecureToken": true
	})
	if not res["ok"]:
		return res
	# Nome de exibição: se falhar, a conta continua criada (o nome é refeito no perfil).
	var token: String = str(res["data"].get("idToken", ""))
	await _identity("update", {"idToken": token, "displayName": display_name, "returnSecureToken": false})
	return _session_result(res, display_name)


func request_password_reset(email: String) -> Dictionary:
	var res: Dictionary = await _identity("sendOobCode", {
		"requestType": "PASSWORD_RESET",
		"email": email.strip_edges()
	})
	# Resposta igual exista ou não o e-mail (não revela quais e-mails têm conta).
	if not res["ok"] and str(res.get("firebase_code", "")) == "EMAIL_NOT_FOUND":
		return {"ok": true, "status": 200, "code": "ok", "message": "", "errors": {}, "data": {}}
	return res


# ------------------------------------------------------------------ Firestore (com o token da sessão)

func firestore_get(path: String) -> Dictionary:
	return await _firestore(HTTPClient.METHOD_GET, path, null)


# Cria o documento "collection/doc_id". Falha com status 409 se ele já existir.
func firestore_create(collection: String, doc_id: String, fields: Dictionary) -> Dictionary:
	var path := "/%s?documentId=%s" % [collection, doc_id.uri_encode()]
	return await _firestore(HTTPClient.METHOD_POST, path, {"fields": fields})


# Atualiza só os campos listados em "mask". As regras do Firestore decidem se pode.
func firestore_patch(path: String, fields: Dictionary, mask: Array) -> Dictionary:
	var query := PackedStringArray()
	for field in mask:
		query.append("updateMask.fieldPaths=" + str(field).uri_encode())
	return await _firestore(HTTPClient.METHOD_PATCH, path + "?" + "&".join(query), {"fields": fields})


# ------------------------------------------------------------------ interno

func _identity(action: String, payload: Dictionary) -> Dictionary:
	if not is_configured():
		return await _not_configured()
	var res: Dictionary = await _send(HTTPClient.METHOD_POST, IDENTITY_URL + action + "?key=" + api_key().uri_encode(), payload, "")
	if res["ok"]:
		return res
	return _identity_error(res)


func _firestore(method: HTTPClient.Method, path: String, payload: Variant) -> Dictionary:
	if not is_configured():
		return await _not_configured()
	if not Session.is_active():
		await get_tree().process_frame
		return _fail("unauthorized", "Sua sessão expirou. Entre novamente.", 401)
	var res: Dictionary = await _send(method, (FIRESTORE_URL % project_id()) + path, payload, Session.token)
	if res["ok"]:
		return res
	return _firestore_error(res)


func _not_configured() -> Dictionary:
	push_warning("AuthService: Firebase não configurado (eternal_legends/firebase/api_key e project_id no project.godot).")
	await get_tree().process_frame
	return _fail("not_configured", "O Firebase ainda não está configurado no jogo.", 0)


func _send(method: HTTPClient.Method, url: String, payload: Variant, token: String) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = TIMEOUT_SECONDS
	add_child(req)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if token != "":
		headers.append("Authorization: Bearer " + token)
	var body_text: String = ""
	if payload != null:
		body_text = JSON.stringify(payload)
	var err: int = req.request(url, headers, method, body_text)
	if err != OK:
		req.queue_free()
		return _fail("request_failed", "Não foi possível iniciar a conexão. Tente novamente.", 0)

	var res: Array = await req.request_completed
	req.queue_free()
	var result: int = res[0]
	var status: int = res[1]
	var body: PackedByteArray = res[3]
	if result != HTTPRequest.RESULT_SUCCESS:
		return _fail("network", "Sem conexão com o servidor. Verifique sua internet e tente novamente.", 0)

	var data: Dictionary = {}
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary:
		data = parsed

	if status >= 200 and status < 300:
		return {"ok": true, "status": status, "code": "ok", "message": "", "errors": {}, "data": data}
	var out: Dictionary = _fail("http", "", status)
	out["data"] = data
	return out


# Resposta de login/cadastro no formato que as telas esperam.
func _session_result(res: Dictionary, display_name: String) -> Dictionary:
	var d: Dictionary = res["data"]
	var email: String = str(d.get("email", ""))
	var shown: String = display_name
	if shown == "":
		shown = str(d.get("displayName", ""))
	if shown == "":
		shown = email.split("@")[0].left(16)
	var out: Dictionary = res.duplicate()
	out["data"] = {
		"token": str(d.get("idToken", "")),
		"refresh_token": str(d.get("refreshToken", "")),
		"uid": str(d.get("localId", "")),
		"email": email,
		"username": shown
	}
	return out


func _identity_error(res: Dictionary) -> Dictionary:
	if str(res["code"]) != "http":
		return res
	var data: Dictionary = res["data"]
	var raw := ""
	var err: Variant = data.get("error", null)
	if err is Dictionary:
		raw = str(err.get("message", ""))
	var fb_code: String = raw.split(" ")[0]

	var code := "error"
	var message := "Não foi possível concluir a solicitação."
	var errors: Dictionary = {}
	match fb_code:
		"EMAIL_EXISTS":
			code = "conflict"
			message = "Este e-mail já está cadastrado."
			errors = {"email": message}
		"INVALID_EMAIL":
			code = "invalid"
			message = "E-mail inválido."
			errors = {"email": message}
		"WEAK_PASSWORD":
			code = "invalid"
			message = "A senha precisa ter pelo menos 6 caracteres."
			errors = {"password": message}
		"EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS":
			code = "unauthorized"
			message = "E-mail ou senha incorretos."
		"USER_DISABLED":
			code = "forbidden"
			message = "Esta conta foi desativada."
		"TOO_MANY_ATTEMPTS_TRY_LATER":
			code = "rate_limited"
			message = "Muitas tentativas. Aguarde um momento e tente de novo."
		"OPERATION_NOT_ALLOWED":
			code = "config"
			message = "O login por e-mail e senha não está ativado no Firebase."
		_:
			if raw.contains("API key"):
				code = "config"
				message = "A chave do Firebase (api_key) é inválida."
			elif int(res["status"]) >= 500:
				code = "server_error"
				message = "O servidor encontrou um problema. Tente novamente em instantes."
	var out: Dictionary = _fail(code, message, int(res["status"]))
	out["errors"] = errors
	out["data"] = data
	out["firebase_code"] = fb_code
	return out


func _firestore_error(res: Dictionary) -> Dictionary:
	if str(res["code"]) != "http":
		return res
	var status: int = int(res["status"])
	var code := "error"
	var message := "Não foi possível concluir a solicitação."
	match status:
		401:
			code = "unauthorized"
			message = "Sua sessão expirou. Entre novamente."
		403:
			code = "forbidden"
			message = "O servidor negou esta operação."
		404:
			code = "not_found"
			message = "Registro não encontrado."
		409:
			code = "conflict"
			message = "Este registro já existe."
		429:
			code = "rate_limited"
			message = "Muitas tentativas. Aguarde um momento e tente de novo."
		_:
			if status >= 500:
				code = "server_error"
				message = "O servidor encontrou um problema. Tente novamente em instantes."
	var out: Dictionary = _fail(code, message, status)
	out["data"] = res["data"]
	return out


func _fail(code: String, message: String, status: int) -> Dictionary:
	return {"ok": false, "status": status, "code": code, "message": message, "errors": {}, "data": {}}