class_name Enemy
extends CharacterBody2D
# Inimigo: persegue o jogador, avisa o golpe (fica amarelo), ataca, leva dano,
# some ao morrer e dá XP.
# Os monstros ilustrados do tutorial (assets/monsters) também podem:
#  - atirar de longe (arqueiros e magos);
#  - bater no chão (golpe em área, com um círculo vermelho de aviso);
#  - no caso dos chefes, entrar em fúria quando a vida chega na metade.

const TEXTURE: Texture2D = preload("res://assets/characters/tiny_dungeon.png")
const COLS := 12
const MONSTER_DIR := "res://assets/monsters/"
const PIXEL := 0.5 # tamanho, no mundo, de cada pixel das imagens ilustradas (câmera do tutorial = zoom 2)
const SLAM_WINDUP := 0.9

const TYPES := {
	# Monstros pequenos do pacote Tiny Dungeon (vila e masmorra antiga).
	"slime": {"name": "Slime", "frame": 108, "hp": 30, "damage": 8, "speed": 22.0, "xp": 12, "scale": 1.0},
	"bat": {"name": "Morcego", "frame": 120, "hp": 18, "damage": 6, "speed": 38.0, "xp": 10, "scale": 1.0},
	"spider": {"name": "Aranha", "frame": 122, "hp": 40, "damage": 10, "speed": 30.0, "xp": 16, "scale": 1.0},
	"ghost": {"name": "Fantasma", "frame": 121, "hp": 35, "damage": 9, "speed": 24.0, "xp": 15, "scale": 1.0},
	"ogre": {"name": "Ogro", "frame": 109, "hp": 120, "damage": 15, "speed": 22.0, "xp": 100, "scale": 1.5, "boss": true},
	# Monstros ilustrados (36): iniciais, intermediários, avançados, elite e lendários.
	"esqueleto_guerreiro": {"name": "Esqueleto Guerreiro", "file": "01_esqueleto_guerreiro.png", "hp": 40, "damage": 8, "speed": 26.0, "xp": 7, "radius": 7.0},
	"arqueiro_esqueleto": {"name": "Esqueleto Arqueiro", "file": "02_arqueiro_esqueleto.png", "hp": 28, "damage": 7, "speed": 22.0, "xp": 7, "radius": 7.0, "ranged": true, "shot_color": "#e8e2d0", "shot_speed": 110, "keep_min": 60, "keep_max": 120, "cooldown": 1.9},
	"necromante_menor": {"name": "Necromante Menor", "file": "03_necromante_menor.png", "hp": 30, "damage": 9, "speed": 20.0, "xp": 8, "radius": 7.0, "ranged": true, "shot_color": "#c98bff", "shot_speed": 85, "keep_min": 65, "keep_max": 120, "cooldown": 2.1},
	"morto_vivo": {"name": "Morto-vivo", "file": "04_morto_vivo.png", "hp": 45, "damage": 8, "speed": 20.0, "xp": 6, "radius": 7.0},
	"goblin_das_ruinas": {"name": "Goblin das Ruínas", "file": "05_goblin_das_ruinas.png", "hp": 26, "damage": 6, "speed": 40.0, "xp": 5, "radius": 7.0},
	"orc_guerreiro": {"name": "Orc Guerreiro", "file": "06_orc_guerreiro.png", "hp": 55, "damage": 10, "speed": 26.0, "xp": 9, "radius": 8.0},
	"rato_gigante": {"name": "Rato Gigante", "file": "07_rato_gigante.png", "hp": 22, "damage": 5, "speed": 44.0, "xp": 4, "radius": 7.0},
	"lobisomem": {"name": "Lobisomem", "file": "08_lobisomem.png", "hp": 50, "damage": 9, "speed": 42.0, "xp": 9, "radius": 8.0},
	"espectro_azul": {"name": "Espectro Azul", "file": "09_espectro_azul.png", "hp": 55, "damage": 10, "speed": 30.0, "xp": 12, "radius": 8.0, "hover": true},
	"espectro_sombrio": {"name": "Espectro Sombrio", "file": "10_espectro_sombrio.png", "hp": 65, "damage": 12, "speed": 26.0, "xp": 14, "radius": 8.0, "hover": true, "ranged": true, "shot_color": "#7fd8ff", "shot_speed": 95, "keep_min": 70, "keep_max": 130, "cooldown": 2.0},
	"aranha_gigante": {"name": "Aranha Gigante", "file": "11_aranha_gigante.png", "hp": 70, "damage": 11, "speed": 38.0, "xp": 13, "radius": 8.0},
	"escorpiao_das_profundezas": {"name": "Escorpião das Profundezas", "file": "12_escorpiao_das_profundezas.png", "hp": 85, "damage": 13, "speed": 28.0, "xp": 15, "radius": 8.0},
	"assassino_das_sombras": {"name": "Assassino das Sombras", "file": "13_assassino_das_sombras.png", "hp": 60, "damage": 14, "speed": 48.0, "xp": 15, "radius": 8.0},
	"cavaleiro_amaldicoado": {"name": "Cavaleiro Amaldiçoado", "file": "14_cavaleiro_amaldicoado.png", "hp": 95, "damage": 13, "speed": 26.0, "xp": 16, "radius": 8.0},
	"cavaleiro_arcano": {"name": "Cavaleiro Arcano", "file": "15_cavaleiro_arcano.png", "hp": 85, "damage": 14, "speed": 28.0, "xp": 16, "radius": 8.0},
	"cavaleiro_infernal": {"name": "Cavaleiro Infernal", "file": "16_cavaleiro_infernal.png", "hp": 100, "damage": 15, "speed": 28.0, "xp": 18, "radius": 8.0},
	"golem_ancestral": {"name": "Golem Ancestral", "file": "17_golem_ancestral.png", "hp": 220, "damage": 16, "speed": 20.0, "xp": 40, "radius": 13.0, "slam": 38, "slam_cd": 7.0, "cooldown": 1.5},
	"gargula_sombria": {"name": "Gárgula Sombria", "file": "18_gargula_sombria.png", "hp": 120, "damage": 15, "speed": 36.0, "xp": 20, "radius": 10.0, "hover": true},
	"lich_guardiao": {"name": "Lich Guardião", "file": "19_lich_guardiao.png", "hp": 130, "damage": 16, "speed": 22.0, "xp": 22, "radius": 10.0, "ranged": true, "shot_color": "#9b7bff", "shot_speed": 95, "keep_min": 80, "keep_max": 140, "cooldown": 2.0},
	"mago_arcano": {"name": "Mago Arcano", "file": "20_mago_arcano.png", "hp": 110, "damage": 17, "speed": 24.0, "xp": 22, "radius": 10.0, "ranged": true, "shot_color": "#5fd4ff", "shot_speed": 100, "keep_min": 80, "keep_max": 140, "cooldown": 1.9},
	"cavaleiro_de_elite": {"name": "Cavaleiro de Elite", "file": "21_cavaleiro_de_elite.png", "hp": 150, "damage": 18, "speed": 30.0, "xp": 24, "radius": 10.0},
	"dragao_azul": {"name": "Dragão Azul", "file": "22_dragao_azul.png", "hp": 160, "damage": 18, "speed": 28.0, "xp": 26, "radius": 10.0, "hover": true},
	"ogro_da_ruina": {"name": "Ogro da Ruína", "file": "23_ogro_da_ruina.png", "hp": 170, "damage": 20, "speed": 24.0, "xp": 26, "radius": 10.0},
	"brutamontes": {"name": "Brutamontes", "file": "24_brutamontes.png", "hp": 180, "damage": 20, "speed": 22.0, "xp": 28, "radius": 10.0},
	"colosso_infernal": {"name": "Colosso Infernal", "file": "25_colosso_infernal.png", "hp": 320, "damage": 22, "speed": 24.0, "xp": 60, "radius": 13.0, "slam": 44, "slam_cd": 7.0, "cooldown": 1.5},
	"senhor_demonio": {"name": "Senhor Demônio", "file": "26_senhor_demonio.png", "hp": 320, "damage": 18, "speed": 30.0, "xp": 70, "radius": 16.0, "boss": true, "enrage": true, "slam": 46, "slam_cd": 6.0, "cooldown": 1.4},
	"cavaleiro_glacial": {"name": "Cavaleiro Glacial", "file": "27_cavaleiro_glacial.png", "hp": 300, "damage": 21, "speed": 28.0, "xp": 60, "radius": 13.0},
	"demonio_de_fogo": {"name": "Demônio de Fogo", "file": "28_demonio_de_fogo.png", "hp": 290, "damage": 22, "speed": 30.0, "xp": 60, "radius": 13.0, "hover": true},
	"aranha_venenosa": {"name": "Aranha Venenosa", "file": "29_aranha_venenosa.png", "hp": 260, "damage": 20, "speed": 40.0, "xp": 55, "radius": 13.0},
	"dragao_da_ruina": {"name": "Dragão da Ruína", "file": "30_dragao_da_ruina.png", "hp": 340, "damage": 24, "speed": 26.0, "xp": 65, "radius": 14.0},
	"golem_cristalino": {"name": "Golem Cristalino", "file": "31_golem_cristalino.png", "hp": 450, "damage": 24, "speed": 20.0, "xp": 90, "radius": 16.0, "slam": 50, "slam_cd": 7.0, "cooldown": 1.5},
	"fera_do_vazio": {"name": "Fera do Vazio", "file": "32_fera_do_vazio.png", "hp": 420, "damage": 26, "speed": 36.0, "xp": 90, "radius": 16.0},
	"arquimago_ancestral": {"name": "Arquimago Ancestral", "file": "33_arquimago_ancestral.png", "hp": 380, "damage": 22, "speed": 24.0, "xp": 90, "radius": 16.0, "ranged": true, "shot_color": "#7dff7a", "shot_speed": 105, "keep_min": 90, "keep_max": 150, "cooldown": 1.7},
	"guardiao_celestial": {"name": "Guardião Celestial", "file": "34_guardiao_celestial.png", "hp": 460, "damage": 24, "speed": 28.0, "xp": 95, "radius": 16.0, "hover": true},
	"senhor_das_trevas": {"name": "Senhor das Trevas", "file": "35_senhor_das_trevas.png", "hp": 480, "damage": 20, "speed": 32.0, "xp": 110, "radius": 18.0, "boss": true, "enrage": true, "slam": 52, "slam_cd": 7.0, "volley": 3, "shot_color": "#ff7a3a", "shot_speed": 95, "cooldown": 1.4},
	"deus_antigo": {"name": "Deus Antigo", "file": "36_deus_antigo.png", "hp": 520, "damage": 26, "speed": 28.0, "xp": 120, "radius": 16.0, "hover": true}
}

var kind: String = "slime"
var display_name: String = "Slime"
var frame: int = 108
var max_hp: int = 30
var hp: int = 30
var damage: int = 8
var speed: float = 22.0
var xp_reward: int = 12
var body_scale: float = 1.0
var hit_radius: float = 6.0
var aggro_radius: float = 80.0
var attack_range: float = 15.0
var attack_cooldown: float = 1.3

var boss: bool = false
var can_enrage: bool = false
var enraged: bool = false
var hover: bool = false
var ranged: bool = false
var shot_color: Color = Color("#c98bff")
var shot_speed: float = 100.0
var keep_min: float = 60.0
var keep_max: float = 120.0
var volley: int = 0
var slam_radius: float = 0.0
var slam_cooldown: float = 7.0
var knock_scale: float = 1.0

var _illustrated: bool = false
var _sprite_height: float = 16.0
var _bar_width: float = 14.0
var _shadow_radius: float = 6.0

var _player: Player
var _visual: Node2D
var _body: Sprite2D
var _shape: CollisionShape2D
var _knock: Vector2 = Vector2.ZERO
var _cooldown: float = 0.5
var _windup: float = 0.0
var _shot_windup: float = 0.0
var _shot_fan: int = 1
var _slam_windup: float = 0.0
var _slam_cd: float = 3.0
var _volley_cd: float = 3.0
var _flash: float = 0.0
var _time: float = 0.0
var _phase: float = 0.0
var _facing_left: bool = false
var _dying: bool = false


func _ready() -> void:
	var data: Dictionary = TYPES.get(kind, TYPES["slime"])
	display_name = str(data["name"])
	max_hp = int(data["hp"])
	hp = max_hp
	damage = int(data["damage"])
	speed = float(data["speed"])
	xp_reward = int(data["xp"])
	boss = bool(data.get("boss", false))
	can_enrage = bool(data.get("enrage", false))
	hover = bool(data.get("hover", false)) or kind == "bat"
	ranged = bool(data.get("ranged", false))
	slam_radius = float(data.get("slam", 0.0))
	slam_cooldown = float(data.get("slam_cd", 7.0))
	volley = int(data.get("volley", 0))
	attack_cooldown = float(data.get("cooldown", attack_cooldown))
	if data.has("shot_color"):
		shot_color = Color(str(data["shot_color"]))
		shot_speed = float(data.get("shot_speed", 100.0))
		keep_min = float(data.get("keep_min", 60.0))
		keep_max = float(data.get("keep_max", 120.0))
	_phase = randf() * TAU
	_slam_cd = randf_range(2.0, 4.0)
	_volley_cd = randf_range(2.5, 4.0)

	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemies")

	_visual = Node2D.new()
	add_child(_visual)
	_body = Sprite2D.new()
	_body.centered = false
	_visual.add_child(_body)

	var tex: Texture2D = null
	if data.has("file"):
		tex = _load_monster(str(data["file"]))
	if tex != null:
		_illustrated = true
		var radius: float = float(data.get("radius", 8.0))
		_body.texture = tex
		_body.scale = Vector2(PIXEL, PIXEL)
		_body.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		_sprite_height = tex.get_height() * PIXEL
		_bar_width = clampf(tex.get_width() * PIXEL * 0.7, 18.0, 44.0)
		_shadow_radius = radius * 1.15
		hit_radius = radius
		attack_range = radius + 9.0
		aggro_radius = 260.0
		body_scale = 1.0
		knock_scale = 0.2 if boss else clampf(8.0 / radius, 0.3, 1.0)
	else:
		# Monstro pequeno (ou imagem ausente: usa o slime no lugar).
		if data.has("frame"):
			frame = int(data["frame"])
			body_scale = float(data["scale"])
		else:
			frame = 108
			body_scale = 1.0
		_body.texture = TEXTURE
		_body.region_enabled = true
		_body.region_rect = Rect2((frame % COLS) * 16, (frame / COLS) * 16, 16, 16)
		_body.offset = Vector2(-8, -16)
		_sprite_height = 16.0 * body_scale
		_bar_width = 14.0 * body_scale
		_shadow_radius = 6.0 * body_scale
		hit_radius = 6.0 * body_scale
		attack_range = 15.0 * body_scale

	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	if _illustrated:
		circle.radius = maxf(hit_radius * 0.75, 5.0)
		_shape.position = Vector2(0, -hit_radius * 0.5)
	else:
		circle.radius = 5.0 * body_scale
		_shape.position = Vector2(0, -4)
	_shape.shape = circle
	add_child(_shape)


static func _load_monster(file: String) -> Texture2D:
	var path := MONSTER_DIR + file
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player

	_cooldown = maxf(_cooldown - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	_slam_cd = maxf(_slam_cd - delta, 0.0)
	_volley_cd = maxf(_volley_cd - delta, 0.0)
	_knock = _knock.move_toward(Vector2.ZERO, 320.0 * delta)
	_check_enrage()

	var move := Vector2.ZERO
	if _slam_windup > 0.0:
		_slam_windup -= delta
		if _slam_windup <= 0.0:
			_slam_strike()
	elif _shot_windup > 0.0:
		_shot_windup -= delta
		if _shot_windup <= 0.0:
			_shoot()
	elif _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_strike()
	elif _player != null and _player.state != Player.State.DEAD:
		move = _decide()

	velocity = move + _knock
	move_and_slide()


# Decide o que fazer neste quadro: devolve a velocidade desejada (ou começa um ataque).
func _decide() -> Vector2:
	var to := _player.global_position - global_position
	var dist := to.length()
	if dist >= aggro_radius:
		return Vector2.ZERO
	_face(to.x)

	# Pancada no chão (chefes e golens): círculo vermelho avisa antes de bater.
	if slam_radius > 0.0 and _slam_cd <= 0.0 and dist < slam_radius + 60.0:
		_slam_windup = SLAM_WINDUP
		_slam_cd = slam_cooldown * (0.7 if enraged else 1.0)
		return Vector2.ZERO

	# Rajada de tiros em leque (chefe final).
	if volley > 0 and _volley_cd <= 0.0 and dist > attack_range + 12.0:
		_shot_fan = volley
		_shot_windup = 0.6
		_volley_cd = 4.5 * (0.75 if enraged else 1.0)
		return Vector2.ZERO

	if ranged:
		if dist < keep_min:
			return -to.normalized() * speed * 0.8
		if dist > keep_max:
			return to.normalized() * speed
		if _cooldown <= 0.0:
			_shot_fan = 1
			_shot_windup = 0.5
			_cooldown = attack_cooldown
		return Vector2.ZERO

	if dist > attack_range:
		return to.normalized() * speed
	if _cooldown <= 0.0:
		_windup = 0.4
		_cooldown = attack_cooldown
	return Vector2.ZERO


func _strike() -> void:
	if _player == null or _player.state == Player.State.DEAD:
		return
	if global_position.distance_to(_player.global_position) <= attack_range + 6.0:
		_player.take_hit(damage, global_position)


func _shoot() -> void:
	if _player == null or _player.state == Player.State.DEAD:
		return
	var origin := global_position + Vector2(0, -_sprite_height * 0.55)
	var aim := (_player.global_position + Vector2(0, -6) - origin).normalized()
	var count: int = maxi(_shot_fan, 1)
	for i in count:
		var angle := 0.0
		if count > 1:
			angle = (float(i) - float(count - 1) / 2.0) * 0.32
		var shot := EnemyShot.new()
		shot.direction = aim.rotated(angle)
		shot.damage = damage
		shot.speed = shot_speed
		shot.color = shot_color
		get_parent().add_child(shot)
		shot.global_position = origin
	Audio.play_sfx("attack", 0.1)


func _slam_strike() -> void:
	var pos := global_position
	var parent := get_parent()
	Fx.ring(parent, pos + Vector2(0, -2), Color("#e0605a"), slam_radius, 0.4)
	Fx.sparks(parent, pos + Vector2(0, -2), Color("#ffb070"), slam_radius, 16, 0.4)
	Audio.play_sfx("hit", 0.2)
	if _player != null and _player.state != Player.State.DEAD:
		if _player.global_position.distance_to(pos) <= slam_radius:
			_player.take_hit(int(float(damage) * 1.5), pos)


func _check_enrage() -> void:
	if not can_enrage or enraged or hp <= 0:
		return
	if hp * 2 > max_hp:
		return
	enraged = true
	speed *= 1.25
	attack_cooldown *= 0.75
	FloatText.spawn(get_parent(), global_position + Vector2(0, -_sprite_height), "Fúria!", Color("#e0605a"))
	Fx.ring(get_parent(), global_position + Vector2(0, -6), Color("#e0605a"), 40.0, 0.5)
	Audio.play_sfx("revive", 0.1)


func take_damage(amount: int, from: Vector2) -> void:
	if _dying:
		return
	hp -= amount
	_flash = 0.15
	_windup = 0.0
	_knock = (global_position - from).normalized() * 90.0 * knock_scale
	Audio.play_sfx("hit", 0.1)
	FloatText.spawn(get_parent(), global_position + Vector2(0, -_sprite_height * 0.4), str(amount), Color.WHITE)
	if hp <= 0:
		_die()


func _die() -> void:
	_dying = true
	remove_from_group("enemies")
	_shape.set_deferred("disabled", true)
	Audio.play_sfx("enemy_die", 0.08)
	var parent := get_parent()
	if Game.add_xp(xp_reward):
		Audio.play_sfx("levelup")
	FloatText.spawn(parent, global_position, "+%d XP" % xp_reward, Color("#f2dc94"))
	if boss:
		FloatText.spawn(parent, global_position + Vector2(0, -12), "Chefe derrotado!", Color("#e0605a"))
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_visual, "modulate:a", 0.0, 0.4)
	tw.tween_property(_visual, "scale", Vector2(0.2, 0.2) * body_scale, 0.4)
	tw.chain().tween_callback(queue_free)


func _face(dx: float) -> void:
	if dx < -0.1:
		_facing_left = true
	elif dx > 0.1:
		_facing_left = false


func _process(delta: float) -> void:
	_time += delta
	if _dying:
		return
	var offset := Vector2.ZERO
	var scl := Vector2.ONE * body_scale
	var tint := Color.WHITE
	if hover:
		offset.y = -4.0 + sin(_time * 9.0 + _phase) * 2.0 if kind == "bat" else -3.0 + sin(_time * 3.0 + _phase) * 2.0
	elif velocity.length() > 2.0:
		offset.y = -absf(sin(_time * 10.0 + _phase)) * (1.0 if _illustrated else 1.5)
	else:
		scl.y *= 1.0 + sin(_time * 2.5 + _phase) * 0.04
	if enraged:
		tint = Color(1.3, 0.85, 0.85)
	if _windup > 0.0 or _shot_windup > 0.0:
		tint = Color(1.6, 1.3, 0.5)
		scl *= 1.12
	if _slam_windup > 0.0:
		var prog := 1.0 - _slam_windup / SLAM_WINDUP
		tint = Color(1.7, 0.8, 0.7)
		scl *= 1.0 + 0.1 * prog
	if _flash > 0.0:
		tint = Color(2.0, 0.6, 0.6)
	_visual.position = offset
	_visual.scale = scl
	_body.flip_h = _facing_left
	_body.modulate = tint
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, _shadow_radius, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _slam_windup > 0.0 and slam_radius > 0.0:
		var prog := 1.0 - _slam_windup / SLAM_WINDUP
		draw_circle(Vector2.ZERO, slam_radius, Color(0.9, 0.15, 0.1, 0.10 + 0.20 * prog))
		draw_arc(Vector2.ZERO, slam_radius, 0.0, TAU, 48, Color(1.0, 0.35, 0.25, 0.85), 1.2)
		draw_arc(Vector2.ZERO, maxf(slam_radius * prog, 1.0), 0.0, TAU, 48, Color(1.0, 0.6, 0.4, 0.9), 1.5)
	if not _dying and hp < max_hp:
		var w := _bar_width
		var y := -_sprite_height - 4.0
		draw_rect(Rect2(-w / 2.0, y, w, 2.0), Color(0.08, 0.06, 0.10, 0.9))
		draw_rect(Rect2(-w / 2.0, y, w * float(hp) / float(max_hp), 2.0), Color("#b23a34"))