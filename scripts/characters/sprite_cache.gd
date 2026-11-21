class_name SpriteCache
extends RefCounted
## Cache único de texturas de personagem. Cada PNG é carregado uma vez só e
## compartilhado por todas as camadas/instâncias (nada é recriado a cada quadro).

static var _textures: Dictionary = {}
static var _missing: Dictionary = {}


static func get_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _textures.has(path):
		return _textures[path]
	if _missing.has(path):
		return null
	if not ResourceLoader.exists(path):
		_missing[path] = true
		push_warning("SpriteCache: textura não encontrada: %s" % path)
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		_missing[path] = true
		return null
	_textures[path] = tex
	return tex


static func preload_paths(paths: Array) -> void:
	for p in paths:
		get_texture(str(p))


static func clear() -> void:
	_textures.clear()
	_missing.clear()