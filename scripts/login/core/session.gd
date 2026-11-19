class_name Session
extends RefCounted
# Sessão em memória. O token vem do servidor de autenticação e NÃO é gravado em disco.

static var token: String = ""
static var username: String = ""
static var data: Dictionary = {}


static func start(response: Dictionary, fallback_name: String = "") -> void:
	data = response
	token = str(response.get("token", response.get("access_token", "")))
	var name_from_server: String = str(response.get("username", ""))
	var user: Variant = response.get("user", null)
	if name_from_server == "" and user is Dictionary:
		name_from_server = str(user.get("username", ""))
	username = name_from_server if name_from_server != "" else fallback_name


static func clear() -> void:
	token = ""
	username = ""
	data = {}


static func is_active() -> bool:
	return token != ""