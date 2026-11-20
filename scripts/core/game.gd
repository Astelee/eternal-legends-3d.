extends Node

signal profile_changed
signal inventory_changed

const GAME_NAME := "Eternal Legends"
const VERSION := "0.2.0"
const SAVE_PATH := "user://profile.cfg"

# Classes disponíveis: "frame" é o índice da peça em assets/characters/tiny_dungeon.png.
# "id" é o identificador gravado na conta (servidor); "frame" é só visual.
const CLASSES := [
	{"id": "warrior", "name": "Guerreiro", "frame": 96},
	{"id": "archer", "name": "Arqueiro", "frame": 112},
	{"id": "mage", "name": "Mago", "frame": 84}
]

var player_name: String = "Herói"
var class_frame: int = 96
# Classe da conta autenticada. Só vale depois que o servidor confirmou (class_confirmed).
# O valor em user://profile.cfg é apenas cache visual: o login sempre o sobrescreve.
var class_id: String = ""
var class_confirmed: bool = false
# GM (mestre do jogo): vem do Firestore (gms/<uid>). Aqui é só para exibir; poderes de GM
# precisam ser validados pelas regras do servidor, nunca por esta variável.
var is_gm: bool = false
var level: int = 1
var xp: int = 0
var music_volume: float = 0.7
var sfx_volume: float = 0.9


func _ready() -> void:
	load_profile()


func frame_of_id(id: String) -> int:
	for c in CLASSES:
		if c["id"] == id:
			return c["frame"]
	return -1


# Aplica a classe devolvida pelo servidor. Retorna false se o id for desconhecido.
func apply_account_class(id: String) -> bool:
	var frame := frame_of_id(id)
	if frame < 0:
		return false
	class_id = id
	class_frame = frame
	class_confirmed = true
	save_profile()
	profile_changed.emit()
	return true


# Esquece a classe confirmada (logout, voltar ao login ou falha de sessão).
func clear_account_class() -> void:
	class_id = ""
	class_confirmed = false
	is_gm = false


# Atalho de desenvolvimento (entrada de debug sem servidor): usa a classe em cache.
func allow_debug_entry() -> void:
	class_confirmed = true


# Estilo de combate do personagem: vem da classe confirmada pela conta.
# (No modo debug, sem servidor, usa a classe em cache.)
func combat_class_id() -> String:
	if class_id != "" and frame_of_id(class_id) >= 0:
		return class_id
	for c in CLASSES:
		if c["frame"] == class_frame:
			return c["id"]
	return "warrior"


# Tutorial inicial: gravado por conta (uid) no arquivo local de perfil.
func _tutorial_key() -> String:
	return Session.uid if Session.is_active() else "debug"


func is_tutorial_done() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return bool(cfg.get_value("tutorial", _tutorial_key(), false))


func complete_tutorial() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # se o arquivo ainda não existe, começa vazio
	cfg.set_value("tutorial", _tutorial_key(), true)
	cfg.save(SAVE_PATH)


# ------------------------------------------------------------------ mochila e equipamentos

const BAG_START_SIZE := 30

var backpack_unlocked: bool = false
var inventory: Array = [] # cada item: {"id": String, "qty": int, "locked": bool, "new": bool}
var equipped: Dictionary = {} # espaço -> id do item
var bag_capacity: int = BAG_START_SIZE
var _bag_key: String = ""


# Carrega a mochila da conta atual (uma vez por conta).
func load_bag() -> void:
	var key := _tutorial_key()
	if key == _bag_key:
		return
	_bag_key = key
	inventory = []
	equipped = {}
	backpack_unlocked = false
	bag_capacity = BAG_START_SIZE
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		backpack_unlocked = bool(cfg.get_value("bag", key + "_unlocked", false))
		bag_capacity = int(cfg.get_value("bag", key + "_cap", BAG_START_SIZE))
		var inv: Variant = JSON.parse_string(str(cfg.get_value("bag", key + "_inv", "[]")))
		if inv is Array:
			for e in inv:
				if e is Dictionary and Items.DB.has(str(e.get("id", ""))):
					inventory.append({"id": str(e["id"]), "qty": int(e.get("qty", 1)), "locked": bool(e.get("locked", false)), "new": false})
		var eq: Variant = JSON.parse_string(str(cfg.get_value("bag", key + "_eq", "{}")))
		if eq is Dictionary:
			for s in eq:
				if Items.DB.has(str(eq[s])) and Items.SLOTS.has(str(s)):
					equipped[str(s)] = str(eq[s])
	# Quem já terminou o tutorial antes da mochila existir recebe a mochila e a arma inicial.
	if is_tutorial_done() and not backpack_unlocked:
		backpack_unlocked = true
		add_item(starter_weapon_id())
		add_item("pocao_vida", 3)
	inventory_changed.emit()


func save_bag() -> void:
	if _bag_key == "":
		return
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("bag", _bag_key + "_unlocked", backpack_unlocked)
	cfg.set_value("bag", _bag_key + "_cap", bag_capacity)
	cfg.set_value("bag", _bag_key + "_inv", JSON.stringify(inventory))
	cfg.set_value("bag", _bag_key + "_eq", JSON.stringify(equipped))
	cfg.save(SAVE_PATH)


func unlock_backpack() -> void:
	load_bag()
	backpack_unlocked = true
	save_bag()
	inventory_changed.emit()


# Arma inicial de cada classe.
func starter_weapon_id() -> String:
	match combat_class_id():
		"archer":
			return "arco_despertar"
		"mage":
			return "cajado_despertar"
	return "espada_despertar"


# Guarda um item (empilha quando dá). Retorna false se a mochila ficou cheia.
func add_item(id: String, qty: int = 1) -> bool:
	load_bag()
	var def := Items.get_def(id)
	if def.is_empty():
		return false
	var stack: int = int(def.get("stack", 1))
	var left := qty
	if stack > 1:
		for entry in inventory:
			if left <= 0:
				break
			if str(entry["id"]) == id and int(entry["qty"]) < stack:
				var room: int = stack - int(entry["qty"])
				var put: int = mini(room, left)
				entry["qty"] = int(entry["qty"]) + put
				left -= put
	while left > 0:
		if inventory.size() >= bag_capacity:
			save_bag()
			inventory_changed.emit()
			return false
		var put2: int = mini(stack, left)
		inventory.append({"id": id, "qty": put2, "locked": false, "new": true})
		left -= put2
	save_bag()
	inventory_changed.emit()
	return true


func remove_at(index: int, qty: int = 1) -> void:
	if index < 0 or index >= inventory.size():
		return
	var entry: Dictionary = inventory[index]
	var left: int = int(entry["qty"]) - qty
	if left > 0:
		entry["qty"] = left
	else:
		inventory.remove_at(index)
	save_bag()
	inventory_changed.emit()


# Motivo pelo qual o item não pode ser equipado ("" = pode).
func equip_error(id: String) -> String:
	var def := Items.get_def(id)
	if def.is_empty() or str(def["type"]) != "equip":
		return "Este item não é um equipamento."
	var req: int = int(def.get("level", 1))
	if level < req:
		return "Requer nível %d." % req
	var cls: String = str(def.get("cls", ""))
	if cls != "" and cls != combat_class_id():
		return "Exclusivo para %s." % str(Items.CLASS_NAMES.get(cls, cls))
	return ""


# Espaço onde o item vai ao ser equipado (anéis e ornamentos usam o primeiro vazio).
func target_slot(id: String) -> String:
	var def := Items.get_def(id)
	var slot: String = str(def.get("slot", ""))
	if slot == "ring":
		return "ring1" if not equipped.has("ring1") else ("ring2" if not equipped.has("ring2") else "ring1")
	if slot == "ornament":
		return "orn1" if not equipped.has("orn1") else ("orn2" if not equipped.has("orn2") else "orn1")
	return slot


# Equipa o item da mochila. Retorna uma mensagem de erro ("" = deu certo).
func equip_index(index: int) -> String:
	if index < 0 or index >= inventory.size():
		return ""
	var entry: Dictionary = inventory[index]
	var id := str(entry["id"])
	var err := equip_error(id)
	if err != "":
		return err
	var slot := target_slot(id)
	var old := str(equipped.get(slot, ""))
	equipped[slot] = id
	inventory.remove_at(index)
	if old != "":
		inventory.append({"id": old, "qty": 1, "locked": false, "new": false})
	save_bag()
	inventory_changed.emit()
	return ""


func unequip_slot(slot: String) -> String:
	if not equipped.has(slot):
		return ""
	if inventory.size() >= bag_capacity:
		return "Mochila cheia."
	var id := str(equipped[slot])
	equipped.erase(slot)
	inventory.append({"id": id, "qty": 1, "locked": false, "new": false})
	save_bag()
	inventory_changed.emit()
	return ""


# Organiza: equipamentos primeiro, depois por raridade e nível.
func sort_inventory() -> void:
	inventory.sort_custom(_item_less)
	save_bag()
	inventory_changed.emit()


func _item_less(a: Dictionary, b: Dictionary) -> bool:
	var order := {"equip": 0, "consumable": 1, "material": 2, "quest": 3}
	var da := Items.get_def(str(a["id"]))
	var db := Items.get_def(str(b["id"]))
	var ta: int = int(order.get(str(da["type"]), 9))
	var tb: int = int(order.get(str(db["type"]), 9))
	if ta != tb:
		return ta < tb
	var ra: int = int(da["rarity"])
	var rb: int = int(db["rarity"])
	if ra != rb:
		return ra > rb
	var la: int = int(da["level"])
	var lb: int = int(db["level"])
	if la != lb:
		return la > lb
	return str(da["name"]) < str(db["name"])


# ------------------------------------------------------------------ atributos

func base_stats() -> Dictionary:
	return {
		"phys_atk": 8 + level * 3, "magic_atk": 8 + level * 3,
		"phys_def": level * 2, "magic_def": level * 2,
		"max_hp": 100 + (level - 1) * 10, "max_mp": 50 + level * 5,
		"move_speed": 0, "accuracy": 100, "crit_chance": 5, "crit_dmg": 150, "dodge": 0
	}


# Soma dos atributos dos itens equipados.
func gear_stats() -> Dictionary:
	var total := {}
	for slot in equipped:
		var def := Items.get_def(str(equipped[slot]))
		var st: Dictionary = def.get("stats", {})
		for k in st:
			total[k] = int(total.get(k, 0)) + int(st[k])
	return total


func stat(key: String) -> int:
	var base: Dictionary = base_stats()
	var gear: Dictionary = gear_stats()
	return int(base.get(key, 0)) + int(gear.get(key, 0))


func class_name_of(frame: int) -> String:
	for c in CLASSES:
		if c["frame"] == frame:
			return c["name"]
	return "Aventureiro"


func xp_to_next() -> int:
	return 40 + level * 20


# Retorna true se subiu de nível.
func add_xp(amount: int) -> bool:
	xp += amount
	var leveled := false
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled = true
	profile_changed.emit()
	save_profile()
	return leveled


func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # preserva outras seções (ex.: tutorial concluído)
	cfg.set_value("profile", "name", player_name)
	cfg.set_value("profile", "class_frame", class_frame)
	cfg.set_value("profile", "level", level)
	cfg.set_value("profile", "xp", xp)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SAVE_PATH)


func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	player_name = cfg.get_value("profile", "name", player_name)
	class_frame = cfg.get_value("profile", "class_frame", class_frame)
	level = cfg.get_value("profile", "level", level)
	xp = cfg.get_value("profile", "xp", xp)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)