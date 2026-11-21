class_name LayeredCharacter
extends Node2D
## Personagem em camadas (corpo + equipamentos), com pivô nos pés (0,0 = pés).
## Cada camada é um Sprite2D nearest, posicionado por soquete do quadro atual.
## Não inventa animação: se (anim, direção) não existe, mostra o idle e avisa uma vez no log.

var class_id: String = ""
var _def: Dictionary = {}
var _sprites: Dictionary = {}   # camada -> Sprite2D
var _state: Dictionary = {}     # camada -> {"tex": Texture2D, "pos": Vector2 (canto sup. esq. relativo aos pés)}
var _equip: Dictionary = {}     # camada -> id do item
var _anim: String = "idle"
var _dir: String = "down"
var _facing_left: bool = false
var _frame: int = 0
var _clock: float = 0.0
var _reported: Dictionary = {}


func setup(id: String) -> bool:
	var def := CharacterDefs.get_def(id)
	if def.is_empty():
		return false
	var r := CharacterDefs.resolve(id, "idle", "down")
	var frames: Array = r["frames"]
	if frames.is_empty():
		return false
	if SpriteCache.get_texture(CharacterDefs.abs_path(id, str(frames[0]["tex"]))) == null:
		return false
	_def = def
	class_id = id
	for s in _sprites.values():
		(s as Node).queue_free()
	_sprites.clear()
	_frame = 0
	_clock = 0.0
	_refresh()
	return true


# Recebe Game.equipped (slot -> id). Troca a aparência imediatamente.
func set_equipment(equipped: Dictionary) -> void:
	var layers := {}
	for slot in equipped:
		var item_id := str(equipped[slot])
		if item_id == "":
			continue
		var vis := CharacterDefs.equip_visual(item_id)
		if vis.is_empty():
			continue
		layers[str(vis.get("layer", CharacterDefs.SLOT_LAYER.get(slot, "")))] = item_id
	if layers == _equip:
		return
	_equip = layers
	_refresh()


func set_tint(c: Color) -> void:
	modulate = c


func update_pose(anim: String, dir: String, facing_left: bool, delta: float) -> void:
	if _def.is_empty():
		return
	var changed := anim != _anim or dir != _dir or facing_left != _facing_left
	if changed:
		_anim = anim
		_dir = dir
		_facing_left = facing_left
		_frame = 0
		_clock = 0.0
	else:
		var r := CharacterDefs.resolve(class_id, _anim, _dir)
		var frames: Array = r["frames"]
		var fps: float = r["fps"]
		if bool(r["exact"]) and fps > 0.0 and frames.size() > 1:
			_clock += delta
			var nf := int(_clock * fps) % frames.size()
			if nf != _frame:
				_frame = nf
				changed = true
	if changed:
		_refresh()


func _refresh() -> void:
	if _def.is_empty():
		return
	var r := CharacterDefs.resolve(class_id, _anim, _dir)
	var frames: Array = r["frames"]
	if frames.is_empty():
		return
	if not bool(r["exact"]):
		var k := "%s/%s" % [_anim, _dir]
		if not _reported.has(k):
			_reported[k] = true
			print("[%s] animação '%s' pendente: usando pose parada (sem animação inventada)." % [class_id, k])
	var fi := clampi(_frame, 0, frames.size() - 1)
	var fr: Dictionary = frames[fi]
	var new_state := {}
	var tex := SpriteCache.get_texture(CharacterDefs.abs_path(class_id, str(fr["tex"])))
	if tex != null:
		var pv: Vector2 = fr.get("pivot", Vector2(floorf(tex.get_width() / 2.0), float(tex.get_height())))
		new_state["body"] = {"tex": tex, "pos": -pv}
	var sockets: Dictionary = fr.get("sockets", {})
	var key := "%s/%s/%d" % [r["anim"], r["dir"], fi]
	for layer in _equip:
		var vis := CharacterDefs.equip_visual(str(_equip[layer]))
		if vis.is_empty() or not bool(vis.get("enabled", false)):
			continue
		var etex := SpriteCache.get_texture(CharacterDefs.abs_path(class_id, str(vis["tex"])))
		if etex == null:
			continue
		var pf: Dictionary = vis.get("per_frame", {}).get(key, {})
		if pf.has("visible") and not bool(pf["visible"]):
			continue
		var anchor := Vector2.ZERO
		var sock := str(vis.get("socket", ""))
		if sock != "":
			if not sockets.has(sock):
				continue
			anchor = sockets[sock]
		anchor += vis.get("offset", Vector2.ZERO) + pf.get("offset", Vector2.ZERO)
		var ep: Vector2 = vis.get("pivot", Vector2(floorf(etex.get_width() / 2.0), floorf(etex.get_height() / 2.0)))
		new_state[layer] = {"tex": etex, "pos": anchor - ep}
	_state = new_state
	var native := str(_def.get("side_native", "right"))
	var flip := false
	if str(r["dir"]) == "side":
		flip = _facing_left != (native == "left")
	scale.x = -1.0 if flip else 1.0
	_sync_sprites(str(r["dir"]))


func _sync_sprites(dir: String) -> void:
	for layer in _state:
		var sp: Sprite2D = _sprites.get(layer)
		if sp == null:
			sp = Sprite2D.new()
			sp.centered = false
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.name = str(layer)
			add_child(sp)
			_sprites[layer] = sp
		sp.texture = _state[layer]["tex"]
		sp.position = (_state[layer]["pos"] as Vector2).round()
		sp.visible = true
	for layer in _sprites:
		if not _state.has(layer):
			(_sprites[layer] as Sprite2D).visible = false
	var idx := 0
	for layer in CharacterDefs.order_for(dir):
		if _sprites.has(layer):
			move_child(_sprites[layer], idx)
			idx += 1


# Compõe a aparência atual em uma imagem (para o retrato da mochila). Usa o mesmo
# estado de equipamentos e as mesmas âncoras do mundo: pés em "pivot".
func compose_image(canvas: Vector2i, pivot: Vector2i) -> Image:
	var img := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	for layer in CharacterDefs.order_for(_dir):
		if not _state.has(layer):
			continue
		var src: Image = (_state[layer]["tex"] as Texture2D).get_image()
		if src == null:
			continue
		if src.get_format() != Image.FORMAT_RGBA8:
			src.convert(Image.FORMAT_RGBA8)
		var dst := pivot + Vector2i((_state[layer]["pos"] as Vector2).round())
		img.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), dst)
	return img