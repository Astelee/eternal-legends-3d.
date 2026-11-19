class_name LoginPrefs
extends RefCounted
# Preferências locais da tela de login (user://login.cfg).
# Guarda APENAS o identificador do "Lembrar-me" e a preferência de movimento.
# Senhas e tokens nunca são gravados aqui.

const CFG_PATH := "user://login.cfg"

# Redução de movimento: o Godot não expõe a configuração do sistema, então:
#  - na exportação Web lemos o "prefers-reduced-motion" do navegador;
#  - em qualquer plataforma o jogador pode alternar manualmente (rodapé da tela).
static var reduced_motion: bool = false
static var _loaded: bool = false


static func load_prefs() -> void:
	if _loaded:
		return
	_loaded = true
	reduced_motion = _system_reduced_motion()
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK and cfg.has_section_key("ui", "reduced_motion"):
		reduced_motion = bool(cfg.get_value("ui", "reduced_motion"))


static func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	var cfg := _read()
	cfg.set_value("ui", "reduced_motion", value)
	cfg.save(CFG_PATH)


static func remembered_identifier() -> String:
	var cfg := _read()
	return str(cfg.get_value("login", "identifier", ""))


static func set_remembered_identifier(value: String) -> void:
	var cfg := _read()
	cfg.set_value("login", "identifier", value)
	cfg.save(CFG_PATH)


static func clear_remembered_identifier() -> void:
	set_remembered_identifier("")


static func _read() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	return cfg


static func _system_reduced_motion() -> bool:
	if OS.has_feature("web"):
		var r: Variant = JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches")
		return bool(r)
	return false