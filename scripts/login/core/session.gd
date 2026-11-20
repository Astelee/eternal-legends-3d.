class_name Session
extends RefCounted
# Sessão em memória. O token vem do Firebase e NÃO é gravado em disco.

static var token: String = ""
static var refresh_token: String = ""
static var uid: String = ""
static var email: String = ""
static var username: String = ""
static var data: Dictionary = {}


static func start(response: Dictionary, fallback_name: String = "") -> void:
	data = response
	token = str(response.get("token", response.get("access_token", "")))
	refresh_token = str(response.get("refresh_token", ""))
	uid = str(response.get("uid", ""))
	email = str(response.get("email", ""))
	var name_from_server: String = str(response.get("username", ""))
	var user: Variant = response.get("user", null)
	if name_from_server == "" and user is Dictionary:
		name_from_server = str(user.get("username", ""))
	username = name_from_server if name_from_server != "" else fallback_name


static func clear() -> void:
	token = ""
	refresh_token = ""
	uid = ""
	email = ""
	username = ""
	data = {}


static func is_active() -> bool:
	return token != "" and uid != ""