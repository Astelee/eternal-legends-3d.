class_name CharacterDefs
extends RefCounted
## Dados dos personagens em camadas. NADA aqui inventa animação: o que não existe
## fica com status "pending" e o sistema cai para a pose parada (idle).
##
## Convenções:
##  - Todas as posições são em pixels LÓGICOS, relativas ao PIVÔ NOS PÉS (0,0 = centro dos pés,
##    y negativo = para cima).
##  - "sockets" são âncoras por quadro (mão, cabeça, tronco...). Equipamentos se prendem
##    a um soquete + deslocamento, nunca a uma posição solta na tela.
##  - "validated": false = âncora estimada, ainda não aprovada visualmente.

const ORDER_DEFAULT: Array = ["cape_back", "body", "legs", "boots", "chest", "gloves", "head", "hair",
		"helmet", "necklace", "ornament", "ornament2", "weapon", "shield", "fx"]
# De costas, arma e escudo ficam atrás do corpo.
const ORDER_UP: Array = ["weapon", "shield", "cape_back", "body", "legs", "boots", "chest", "gloves",
		"head", "hair", "helmet", "necklace", "ornament", "ornament2", "fx"]

# Espaço de equipamento do jogo (Items.SLOTS) -> camada visual (anéis não têm camada).
const SLOT_LAYER := {"helmet": "helmet", "chest": "chest", "necklace": "necklace", "weapon": "weapon",
		"orn1": "ornament", "orn2": "ornament2"}

const ARCHER_DIR := "res://assets/characters/archer/"

const DATA := {
	"archer": {
		"dir": ARCHER_DIR,
		"logical_height": 40,
		"side_native": "right", # para onde as poses laterais olham no PNG (ainda sem lateral aprovada)
		"anims": {
			# PROVISÓRIO: um único quadro frontal (r1_f2) aprovado. Não é ciclo.
			"idle": {"status": "provisional_static", "fps": 0.0, "loop": true, "frames": {
				"down": [{"tex": "base/front_idle.png", "validated": false,
					"sockets": {"hand_l": Vector2(-10, -13), "hand_r": Vector2(10, -13),
						"head": Vector2(0, -30), "torso": Vector2(0, -20), "feet": Vector2(0, 0)}}],
			}},
			# PENDENTES: faltam quadros reais. Não usar poses 7 a 12 como ciclo.
			"walk": {"status": "pending", "fps": 8.0, "loop": true, "frames": {}},
			"run": {"status": "pending", "fps": 10.0, "loop": true, "frames": {}},
			"attack": {"status": "pending", "fps": 0.0, "loop": false, "frames": {}},
			"skill": {"status": "pending", "fps": 0.0, "loop": false, "frames": {}},
			"hit": {"status": "pending", "fps": 0.0, "loop": false, "frames": {}},
			"death": {"status": "pending", "fps": 0.0, "loop": false, "frames": {}},
		},
	},
}

# Visual de cada item equipável, por id do item (Items.DB). "enabled": false = a camada
# existe e está pronta, mas só liga quando houver pose e âncora validadas.
const EQUIP_VISUALS := {
	"arco_despertar": {"layer": "weapon", "tex": "weapons/arco_esmeralda.png", "socket": "hand_l",
		"offset": Vector2(0, 0), "enabled": false, "validated": false,
		"note": "Desligado: o quadro frontal não segura o arco. Ligar com a pose de ataque/mira."},
}


static func has_class(id: String) -> bool:
	return DATA.has(id)


static func get_def(id: String) -> Dictionary:
	return DATA.get(id, {})


static func abs_path(id: String, rel: String) -> String:
	if rel.begins_with("res://"):
		return rel
	return str(get_def(id).get("dir", "")) + rel


static func equip_visual(item_id: String) -> Dictionary:
	return EQUIP_VISUALS.get(item_id, {})


static func order_for(dir: String) -> Array:
	return ORDER_UP if dir == "up" else ORDER_DEFAULT


static func _frames(anims: Dictionary, anim: String, dir: String) -> Array:
	var a: Dictionary = anims.get(anim, {})
	var f: Dictionary = a.get("frames", {})
	return f.get(dir, [])


# Escolhe os quadros a usar. Sem quadros para (anim, dir): cai para idle, depois para "down".
# "exact" só é true quando existe animação real para o que foi pedido.
static func resolve(id: String, anim: String, dir: String) -> Dictionary:
	var anims: Dictionary = get_def(id).get("anims", {})
	var frames := _frames(anims, anim, dir)
	var exact := not frames.is_empty()
	var used_anim := anim
	var used_dir := dir
	if frames.is_empty():
		used_anim = "idle"
		frames = _frames(anims, "idle", dir)
	if frames.is_empty() and dir != "down":
		used_dir = "down"
		frames = _frames(anims, used_anim, "down")
	var fps := float(anims.get(used_anim, {}).get("fps", 0.0))
	return {"frames": frames, "anim": used_anim, "dir": used_dir, "exact": exact, "fps": fps}