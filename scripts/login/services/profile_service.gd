class_name ProfileService
extends RefCounted
# Perfil da conta no Firestore: classe permanente do personagem e papel de GM.
#
# Quem decide é SEMPRE o Firestore, pelas regras em firebase/firestore.rules:
# a classe só pode ser gravada uma vez, e só pelo dono da conta.
#
# Toda função devolve:
#   { "ok": bool, "code": String, "message": String, "class_id": String }
# "class_id" vazio significa que a conta ainda não escolheu.
# code "already_chosen": a conta já tinha classe (class_id traz a classe oficial).

var _auth: AuthService


func _init(auth: AuthService) -> void:
	_auth = auth


# Consulta a classe registrada na conta. Na primeira vez, cria o perfil (sem classe).
func fetch_class() -> Dictionary:
	var res: Dictionary = await _read_profile()
	if str(res["code"]) == "not_found":
		var created: Dictionary = await _create_profile()
		if not created["ok"] and int(created["status"]) != 409:
			return _from_failure(created)
		res = await _read_profile()
	return res


# Pede a gravação da classe. O Firestore só aceita se a conta ainda não tiver classe.
func choose_class(class_id: String) -> Dictionary:
	if Game.frame_of_id(class_id) < 0:
		return _result(false, "invalid", "Classe inválida.", "")
	var res: Dictionary = await _auth.firestore_patch(
		"/players/" + Session.uid.uri_encode(),
		{"class_id": {"stringValue": class_id}},
		["class_id"]
	)
	if res["ok"]:
		# Só aceita se o servidor confirmou exatamente a classe pedida.
		var saved: String = _read_class_id(res["data"])
		if saved != class_id:
			return _result(false, "invalid_response", "O servidor não confirmou a escolha. Tente novamente.", "")
		return _result(true, "ok", "", saved)
	if str(res["code"]) == "forbidden":
		# Regra negou: normalmente porque a conta já tem classe. Confere a oficial.
		var current: Dictionary = await _read_profile()
		if current["ok"] and str(current["class_id"]) != "":
			return _result(false, "already_chosen", "Esta conta já possui um personagem definido.", str(current["class_id"]))
	return _from_failure(res)


# GM = existe o documento gms/<uid>, criado só pelo console do Firebase (as regras proíbem o app de criar).
func fetch_is_gm() -> bool:
	var res: Dictionary = await _auth.firestore_get("/gms/" + Session.uid.uri_encode())
	return bool(res["ok"])


# ------------------------------------------------------------------ interno

func _read_profile() -> Dictionary:
	var res: Dictionary = await _auth.firestore_get("/players/" + Session.uid.uri_encode())
	if not res["ok"]:
		return _from_failure(res)
	var cid: String = _read_class_id(res["data"])
	if cid != "" and Game.frame_of_id(cid) < 0:
		return _result(false, "invalid_response", "Resposta inválida do servidor. Tente novamente.", "")
	return _result(true, "ok", "", cid)


func _create_profile() -> Dictionary:
	var fields := {
		"username": {"stringValue": Session.username.left(16)},
		"class_id": {"nullValue": null},
		"created_at": {"timestampValue": Time.get_datetime_string_from_system(true) + "Z"}
	}
	return await _auth.firestore_create("players", Session.uid, fields)


# Documento do Firestore: {"fields": {"class_id": {"stringValue": "warrior"} | {"nullValue": null}}}
func _read_class_id(doc: Variant) -> String:
	if doc is Dictionary:
		var fields: Variant = doc.get("fields", null)
		if fields is Dictionary:
			var field: Variant = fields.get("class_id", null)
			if field is Dictionary and field.has("stringValue"):
				return str(field["stringValue"]).strip_edges()
	return ""


func _from_failure(res: Dictionary) -> Dictionary:
	var code: String = str(res["code"])
	var message: String = str(res["message"])
	if code == "forbidden":
		message = "O servidor negou o acesso ao perfil. Confira as regras do Firestore (docs/FIREBASE.md)."
	return _result(false, code, message, "")


func _result(ok: bool, code: String, message: String, class_id: String) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "class_id": class_id}