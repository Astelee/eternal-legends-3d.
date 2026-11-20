class_name Items
extends RefCounted
# Banco de itens do jogo: equipamentos, poções, materiais e itens de missão.
# Para criar um item novo, copie uma linha de DB, troque o id e os dados, e (se quiser um
# ícone novo) coloque o PNG em res://assets/items/ com o nome indicado em "icon".

const RARITY_NAMES := ["Comum", "Incomum", "Raro", "Épico", "Lendário", "Mítico"]
const RARITY_COLORS := [
	Color("#b8b8c0"), Color("#5ac86e"), Color("#4a86d8"),
	Color("#b05ae0"), Color("#f0a030"), Color("#e0405a")
]

# Espaços de equipamento (ordem usada na tela).
const SLOTS := ["helmet", "chest", "necklace", "ring1", "weapon", "orn1", "orn2", "ring2"]
const SLOT_NAMES := {
	"helmet": "Capacete", "chest": "Peitoral", "weapon": "Arma", "necklace": "Colar",
	"ring1": "Anel", "ring2": "Anel", "orn1": "Ornamento", "orn2": "Ornamento",
	"ring": "Anel", "ornament": "Ornamento"
}

const CLASS_NAMES := {"warrior": "Guerreiro", "archer": "Arqueiro", "mage": "Mago"}
const TYPE_NAMES := {"equip": "Equipamento", "consumable": "Consumível", "material": "Material", "quest": "Item de missão"}

# Atributos, na ordem em que aparecem no painel. "suffix" é o que vem depois do número.
const STAT_ORDER := ["phys_atk", "magic_atk", "phys_def", "magic_def", "max_hp", "max_mp", "move_speed", "accuracy", "crit_chance", "crit_dmg", "dodge"]
const STAT_NAMES := {
	"phys_atk": "Ataque Físico", "magic_atk": "Ataque Mágico", "phys_def": "Defesa Física",
	"magic_def": "Defesa Mágica", "max_hp": "Vida Máxima", "max_mp": "Mana Máxima",
	"move_speed": "Velocidade de Movimento", "accuracy": "Precisão", "crit_chance": "Chance de Crítico",
	"crit_dmg": "Dano Crítico", "dodge": "Esquiva"
}
const STAT_SUFFIX := {"move_speed": "%", "crit_chance": "%", "crit_dmg": "%", "dodge": "%"}

# type: equip | consumable | material | quest.  slot: helmet | chest | weapon | necklace | ring | ornament.
# cls: "" (qualquer) ou warrior | archer | mage.  rarity: 0 a 5.  stack: máximo por espaço.
const DB := {
	"arco_despertar": {"name": "Arco do Despertar", "type": "equip", "slot": "weapon", "rarity": 3, "level": 1, "cls": "archer", "icon": "arco",
		"stats": {"phys_atk": 14, "crit_dmg": 10, "accuracy": 20}, "desc": "Um arco que brilha com a luz do Cristal Eterno. Entregue a quem desperta nas ruínas."},
	"espada_despertar": {"name": "Espada do Despertar", "type": "equip", "slot": "weapon", "rarity": 3, "level": 1, "cls": "warrior", "icon": "espada",
		"stats": {"phys_atk": 14, "crit_chance": 3, "phys_def": 4}, "desc": "Uma lâmina que vibra com a luz do Cristal Eterno. Entregue a quem desperta nas ruínas."},
	"cajado_despertar": {"name": "Cajado do Despertar", "type": "equip", "slot": "weapon", "rarity": 3, "level": 1, "cls": "mage", "icon": "cajado",
		"stats": {"magic_atk": 16, "max_mp": 20, "magic_def": 4}, "desc": "Um cajado cuja gema pulsa com a luz do Cristal Eterno. Entregue a quem desperta nas ruínas."},
	"elmo_ferro": {"name": "Elmo de Ferro", "type": "equip", "slot": "helmet", "rarity": 1, "level": 1, "cls": "", "icon": "capacete",
		"stats": {"phys_def": 6, "magic_def": 2}, "desc": "Um elmo simples, mas firme. Já salvou muitas cabeças."},
	"peitoral_reforcado": {"name": "Peitoral Reforçado", "type": "equip", "slot": "chest", "rarity": 1, "level": 1, "cls": "", "icon": "peitoral",
		"stats": {"phys_def": 10, "magic_def": 4}, "desc": "Couro e placas de ferro costurados com cuidado."},
	"colar_vida": {"name": "Colar da Vitalidade", "type": "equip", "slot": "necklace", "rarity": 2, "level": 1, "cls": "", "icon": "colar",
		"stats": {"max_hp": 40}, "desc": "A gema verde pulsa como um coração."},
	"anel_precisao": {"name": "Anel da Mira Certeira", "type": "equip", "slot": "ring", "rarity": 2, "level": 1, "cls": "", "icon": "anel",
		"stats": {"accuracy": 30, "crit_chance": 3}, "desc": "Quem o usa raramente erra o alvo."},
	"anel_vigor": {"name": "Anel do Vigor", "type": "equip", "slot": "ring", "rarity": 1, "level": 1, "cls": "", "icon": "anel",
		"stats": {"max_hp": 20, "phys_def": 2}, "desc": "Um anel de ouro gasto, cheio de energia."},
	"ornamento_vento": {"name": "Ornamento do Vento", "type": "equip", "slot": "ornament", "rarity": 2, "level": 1, "cls": "", "icon": "ornamento",
		"stats": {"move_speed": 5, "dodge": 3}, "desc": "Asas douradas que deixam os passos mais leves."},
	"pocao_vida": {"name": "Poção de Vida", "type": "consumable", "rarity": 0, "level": 1, "cls": "", "icon": "pocao", "stack": 20, "heal": 50,
		"stats": {}, "desc": "Restaura 50 pontos de vida."},
	"cristal_azul": {"name": "Cristal Azul", "type": "material", "rarity": 1, "level": 1, "cls": "", "icon": "cristal", "stack": 99,
		"stats": {}, "desc": "Fragmento de cristal. Será usado para melhorar equipamentos."},
	"gema_roxa": {"name": "Gema Roxa", "type": "material", "rarity": 2, "level": 1, "cls": "", "icon": "gema", "stack": 99,
		"stats": {}, "desc": "Uma gema rara, vinda das profundezas."},
	"pergaminho_aldric": {"name": "Pergaminho de Aldric", "type": "quest", "rarity": 2, "level": 1, "cls": "", "icon": "pergaminho", "stack": 1,
		"stats": {}, "desc": "Um recado do Ancião Aldric."}
}

static var _icons: Dictionary = {}


static func get_def(id: String) -> Dictionary:
	if DB.has(id):
		var d: Dictionary = DB[id]
		return d
	return {}


static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]


static func rarity_name(rarity: int) -> String:
	return str(RARITY_NAMES[clampi(rarity, 0, RARITY_NAMES.size() - 1)])


static func icon(id: String) -> Texture2D:
	var def := get_def(id)
	if def.is_empty():
		return null
	var key := str(def["icon"])
	if _icons.has(key):
		return _icons[key] as Texture2D
	var path := "res://assets/items/%s.png" % key
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_icons[key] = tex
	return tex


# Texto de um atributo: "Ataque Físico +14".
static func stat_line(key: String, value: int) -> String:
	var sign_text := "+" if value >= 0 else ""
	return "%s %s%d%s" % [str(STAT_NAMES.get(key, key)), sign_text, value, str(STAT_SUFFIX.get(key, ""))]