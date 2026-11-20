class_name ProfileService
extends RefCounted
# Classe do personagem vinculada à conta autenticada.
#
# Quem decide é SEMPRE o servidor: este serviço só consulta e pede a gravação.
# Contrato do backend: docs/LOGIN_SCREEN.md (GET/POST /profile/class).
#
# Toda função devolve:
#   { "ok": bool, "code": String, "message": String, "class_id": String }
# "class_id" vazio significa que a conta ainda não escolheu.
# code "already_chosen": a conta já tinha classe (class_id traz a classe oficial).

var _auth: AuthService


func _init(auth: AuthService) -> void:
	_auth = auth


# Consulta a classe registrada na conta.
func fetch_class() -> Dictionary:
	var res: Dictionary = await _auth.authed_get("/profile/class")
	if not res["ok"]:
		return _from_failure(res)
	var cid: String = _read_class_id(res["data"])
	if cid != "" and Game.frame_of_id(cid) < 0:
		return _result(false, "invalid_response", "Resposta inválida do servidor. Tente novamente.", "")
	return _result(true, "ok", "", cid)


# Pede ao servidor para gravar a classe. O servidor só grava se o campo estiver vazio.
func choose_class(class_id: String) -> Dictionary:
	if Game.frame_of_id(class_id) < 0:
		return _result(false, "invalid", "Classe inválida.", "")
	var res: Dictionary = await _auth.authed_post("/profile/class", {"class_id": class_id})
	if res["ok"]:
		# Só aceita se o servidor confirmou exatamente a classe pedida.
		var saved: String = _read_class_id(res["data"])
		if saved != class_id:
			return _result(false, "invalid_response", "O servidor não confirmou a escolha. Tente novamente.", "")
		return _result(true, "ok", "", saved)
	if int(res["status"]) == 409:
		var existing: String = _read_class_id(res["data"])
		if Game.frame_of_id(existing) >= 0:
			return _result(false, "already_chosen", "Esta conta já possui um personagem definido.", existing)
	return _from_failure(res)


# ------------------------------------------------------------------ interno

func _read_class_id(data: Variant) -> String:
	if data is Dictionary:
		var value: Variant = data.get("class_id", null)
		if value == null:
			var profile: Variant = data.get("profile", null)
			if profile is Dictionary:
				value = profile.get("class_id", null)
		if value != null:
			return str(value).strip_edges()
	return ""


func _from_failure(res: Dictionary) -> Dictionary:
	var code: String = str(res["code"])
	var message: String = str(res["message"])
	if code == "unauthorized":
		message = "Sua sessão expirou. Entre novamente."
	return _result(false, code, message, "")


func _result(ok: bool, code: String, message: String, class_id: String) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "class_id": class_id}