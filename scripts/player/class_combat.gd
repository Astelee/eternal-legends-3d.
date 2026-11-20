class_name ClassCombat
extends RefCounted
# Dados de combate de cada classe + ícones dos botões (desenhados por código,
# porque o pacote de sprites não tem arco nem ícones de habilidade).
# A classe vem SEMPRE da conta (Game.combat_class_id()), nunca é trocada aqui.

const DATA := {
	"warrior": {
		"title": "Guerreiro", "attack_name": "Espada", "skill_name": "Giro",
		"attack_time": 0.5, "release": 0.55, "damage_mult": 1.0,
		"melee_reach": 20.0, "auto_range": 48.0, "move_factor": 0.8,
		"weapon_frame": 104,
		"proj_speed": 0.0, "proj_range": 0.0, "splash": 0.0,
		"skill_cd": 6.0, "skill_time": 0.45, "skill_release": 0.6,
		"skill_mult": 1.2, "skill_radius": 28.0, "skill_sfx": "attack"
	},
	"archer": {
		"title": "Arqueiro", "attack_name": "Flecha", "skill_name": "Rajada",
		"attack_time": 0.55, "release": 0.4, "damage_mult": 0.9,
		"melee_reach": 0.0, "auto_range": 120.0, "move_factor": 0.6,
		"weapon_frame": -1,
		"proj_speed": 260.0, "proj_range": 150.0, "splash": 0.0,
		"skill_cd": 5.0, "skill_time": 0.6, "skill_release": 0.45,
		"skill_mult": 0.75, "skill_radius": 0.0, "skill_sfx": "attack"
	},
	"mage": {
		"title": "Mago", "attack_name": "Magia", "skill_name": "Nova",
		"attack_time": 0.8, "release": 0.35, "damage_mult": 1.25,
		"melee_reach": 0.0, "auto_range": 100.0, "move_factor": 0.4,
		"weapon_frame": 130,
		"proj_speed": 150.0, "proj_range": 130.0, "splash": 16.0,
		"skill_cd": 7.0, "skill_time": 0.7, "skill_release": 0.5,
		"skill_mult": 1.4, "skill_radius": 42.0, "skill_sfx": "revive"
	}
}

const DARK := Color("#2a1810")
const WOOD := Color("#b9772f")
const STRING_COL := Color("#e8e2d0")
const STEEL := Color("#e8e8f0")
const GOLD_COL := Color("#f2dc94")
const CYAN := Color("#5fd4ff")

static var _icons: Dictionary = {}


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, DATA["warrior"])


static func id_from_frame(frame: int) -> String:
	match frame:
		112:
			return "archer"
		84:
			return "mage"
		_:
			return "warrior"


# null = usar o ícone padrão (espada) do projeto.
static func attack_icon(id: String) -> Texture2D:
	return _icon("attack_" + id)


static func skill_icon(id: String) -> Texture2D:
	return _icon("skill_" + id)


static func _icon(key: String) -> Texture2D:
	if _icons.has(key):
		return _icons[key] as Texture2D
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var known := true
	match key:
		"attack_archer":
			_art_bow(img)
		"attack_mage":
			_art_staff(img)
		"skill_warrior":
			_art_spin(img)
		"skill_archer":
			_art_volley(img)
		"skill_mage":
			_art_nova(img)
		_:
			known = false
	if not known:
		_icons[key] = null
		return null
	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex


# ------------------------------------------------------------------ desenho dos ícones

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _line(img: Image, a: Vector2, b: Vector2, c: Color, thick: int = 1) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) * 2 + 1
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		for dx in thick:
			for dy in thick:
				_px(img, roundi(p.x) + dx, roundi(p.y) + dy, c)


static func _disc(img: Image, center: Vector2, r: float, c: Color) -> void:
	var ri := int(ceil(r))
	for y in range(-ri, ri + 1):
		for x in range(-ri, ri + 1):
			if Vector2(x, y).length() <= r:
				_px(img, roundi(center.x) + x, roundi(center.y) + y, c)


static func _arrow(img: Image, from: Vector2, to: Vector2, c: Color) -> void:
	_line(img, from, to, c, 1)
	var dir := (to - from).normalized()
	var side := dir.orthogonal()
	_line(img, to, to - dir * 4.0 + side * 2.5, c, 1)
	_line(img, to, to - dir * 4.0 - side * 2.5, c, 1)


static func _art_bow(img: Image) -> void:
	var c := Vector2(7, 12)
	var pts: Array[Vector2] = []
	var a := -1.15
	while a <= 1.15:
		pts.append(c + Vector2.from_angle(a) * 11.0)
		a += 0.04
	for p in pts:
		_disc(img, p, 1.7, DARK)
	for p in pts:
		_disc(img, p, 0.9, WOOD)
	_line(img, pts[0], pts[pts.size() - 1], STRING_COL, 1)
	_line(img, Vector2(7, 12), Vector2(21, 12), Color("#d9c7a0"), 1)
	_line(img, Vector2(21, 12), Vector2(18, 9), STEEL, 1)
	_line(img, Vector2(21, 12), Vector2(18, 15), STEEL, 1)


static func _art_staff(img: Image) -> void:
	_line(img, Vector2(4, 20), Vector2(16, 9), DARK, 3)
	_line(img, Vector2(4, 20), Vector2(16, 9), WOOD, 1)
	_disc(img, Vector2(18, 6), 4.5, Color(0.37, 0.83, 1.0, 0.45))
	_disc(img, Vector2(18, 6), 3.2, CYAN)
	_disc(img, Vector2(18, 6), 1.5, Color.WHITE)
	_px(img, 22, 2, Color.WHITE)
	_px(img, 13, 3, Color(0.8, 0.95, 1.0))
	_px(img, 22, 10, Color(0.8, 0.95, 1.0))


static func _art_spin(img: Image) -> void:
	var c := Vector2(12, 12)
	var a := 0.6
	while a <= 5.6:
		_disc(img, c + Vector2.from_angle(a) * 8.0, 1.6, DARK)
		a += 0.05
	a = 0.6
	while a <= 5.6:
		_disc(img, c + Vector2.from_angle(a) * 8.0, 0.9, STEEL)
		a += 0.05
	var end := c + Vector2.from_angle(5.6) * 8.0
	_arrow(img, end - Vector2(4, 1), end + Vector2(2, 2), GOLD_COL)
	_disc(img, c, 1.5, GOLD_COL)


static func _art_volley(img: Image) -> void:
	var origin := Vector2(3, 19)
	_arrow(img, origin, Vector2(21, 4), STEEL)
	_arrow(img, origin, Vector2(22, 12), GOLD_COL)
	_arrow(img, origin, Vector2(20, 20), STEEL)


static func _art_nova(img: Image) -> void:
	var c := Vector2(12, 12)
	var a := 0.0
	while a < TAU:
		_disc(img, c + Vector2.from_angle(a) * 9.0, 1.0, Color("#9b7bff"))
		a += 0.08
	for i in 8:
		var dir := Vector2.from_angle(i * TAU / 8.0)
		_line(img, c + dir * 2.0, c + dir * 6.0, CYAN, 1)
	_disc(img, c, 2.4, Color.WHITE)