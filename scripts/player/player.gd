class_name Player
extends CharacterBody2D

signal state_changed(new_state: int)
signal hp_changed(hp: int, max_hp: int)
signal attacked
signal skill_used

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEAD }

const FRAME_COLS := 12
const FRAME_SIZE := 16
const DARK_WOOD := Color("#2a1810")
const LIGHT_WOOD := Color("#b9772f")

# Dados de combate de cada classe (arma, alcance, habilidade) ficam em class_combat.gd.

@export var character_frame: int = 96
@export var walk_speed: float = 45.0
@export var run_speed: float = 80.0
@export var run_threshold: float = 0.85
@export var attack_time: float = 0.5
@export_range(0.0, 1.0) var attack_move_factor: float = 0.8 # velocidade ao andar atacando (0 = parado)
@export var hurt_time: float = 0.3
@export var base_hp: int = 100
@export var hp_per_level: int = 10
@export var world_limit: Rect2 = Rect2(0, 0, 640, 480)

var joystick: VirtualJoystick
var state: int = State.IDLE
var direction_index: int = 2
var max_hp: int = 100
var hp: int = 100

var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _facing_left: bool = false
var _step_timer: float = 0.0
var _hit_done: bool = false
var _invuln: float = 0.0
var _knock: Vector2 = Vector2.ZERO
var _last_level: int = 1

var _weapon: Node2D
var _weapon_sprite: Sprite2D
var _fx: Node2D

# Combate por classe
var combat_class: String = "warrior"
var _combat: Dictionary = {}
var _cur_attack_time: float = 0.5
var _release_frac: float = 0.55
var _skill_mode: bool = false
var _skill_cd: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _body: Sprite2D = $Visual/Body
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	_build_weapon()
	_build_fx()
	set_combat_class(ClassCombat.id_from_frame(character_frame))
	_apply_frame()
	_last_level = Game.level
	max_hp = _max_hp_for(Game.level)
	hp = max_hp
	Game.profile_changed.connect(_on_profile_changed)
	hp_changed.emit(hp, max_hp)


func _process(delta: float) -> void:
	_update_visual(delta)


func _physics_process(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)
	_skill_cd = maxf(_skill_cd - delta, 0.0)
	match state:
		State.ATTACK:
			velocity = _attack_velocity()
			_state_timer -= delta
			# O golpe / disparo sai no ponto de "soltar" de cada classe.
			if not _hit_done and _state_timer <= _cur_attack_time * _release_frac:
				_hit_done = true
				_release()
			if _state_timer <= 0.0:
				_set_state(State.IDLE)
		State.HURT:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, 500.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_set_state(State.IDLE)
		State.DEAD:
			velocity = Vector2.ZERO
		_:
			_move()

	move_and_slide()
	position = position.clamp(world_limit.position, world_limit.end)


func _move() -> void:
	var input := Vector2.ZERO
	if joystick:
		input = joystick.output

	var strength := input.length()
	if strength < 0.01:
		velocity = Vector2.ZERO
		_set_state(State.IDLE)
		return

	# Oito direções: o ângulo do joystick é arredondado para múltiplos de 45 graus.
	direction_index = posmod(roundi(input.angle() / (PI / 4.0)), 8)
	var dir := Vector2.from_angle(direction_index * PI / 4.0)
	_facing = dir
	if dir.x < -0.1:
		_facing_left = true
	elif dir.x > 0.1:
		_facing_left = false

	var running := strength >= run_threshold
	velocity = dir * (run_speed if running else walk_speed)
	_set_state(State.RUN if running else State.WALK)

	_step_timer -= get_physics_process_delta_time()
	if _step_timer <= 0.0:
		_step_timer = 0.22 if running else 0.34
		Audio.play_sfx("step", 0.15)


# Durante o ataque o personagem continua andando na direção do joystick,
# sem mudar o estado nem a direção do golpe.
func _attack_velocity() -> Vector2:
	if joystick == null or joystick.output.length() < 0.01:
		return Vector2.ZERO
	var angle := posmod(roundi(joystick.output.angle() / (PI / 4.0)), 8) * PI / 4.0
	var factor: float = float(_combat.get("move_factor", attack_move_factor))
	return Vector2.from_angle(angle) * walk_speed * factor


# ------------------------------------------------------------------ combate

func attack() -> void:
	if state == State.DEAD or state == State.ATTACK:
		return
	_skill_mode = false
	_cur_attack_time = float(_combat["attack_time"])
	_release_frac = float(_combat["release"])
	_auto_face(float(_combat["auto_range"]))
	_set_state(State.ATTACK)
	Audio.play_sfx("attack", 0.08)
	attacked.emit()


# Habilidade da classe (Giro / Rajada / Nova), com tempo de recarga.
func use_skill() -> void:
	if state == State.DEAD or state == State.ATTACK or _skill_cd > 0.0:
		return
	_skill_mode = true
	_cur_attack_time = float(_combat["skill_time"])
	_release_frac = float(_combat["skill_release"])
	_skill_cd = float(_combat["skill_cd"])
	_auto_face(float(_combat["auto_range"]))
	_set_state(State.ATTACK)
	Audio.play_sfx(str(_combat["skill_sfx"]), 0.1)
	skill_used.emit()


func skill_cooldown_left() -> float:
	return _skill_cd


func skill_cooldown_total() -> float:
	return float(_combat.get("skill_cd", 1.0))


# Define o estilo de combate. A classe vem da conta (permanente): Game.combat_class_id().
func set_combat_class(id: String) -> void:
	combat_class = id if ClassCombat.DATA.has(id) else "warrior"
	_combat = ClassCombat.get_data(combat_class)
	attack_time = float(_combat["attack_time"])
	_cur_attack_time = attack_time
	_skill_cd = 0.0
	if is_node_ready():
		_apply_frame()


# Vira para o inimigo mais próximo dentro de max_dist (facilita o toque no celular).
func _auto_face(max_dist: float) -> void:
	var best: Enemy = null
	var best_dist := max_dist
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null:
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	if best == null:
		return
	var to := best.global_position - global_position
	_facing = to.normalized()
	if to.x < -0.1:
		_facing_left = true
	elif to.x > 0.1:
		_facing_left = false


func attack_damage() -> int:
	return 8 + Game.level * 3


func _damage_for(mult: float) -> int:
	return int(attack_damage() * mult * randf_range(0.85, 1.2))


func _release() -> void:
	match combat_class:
		"archer":
			if _skill_mode:
				_fire_volley()
			else:
				_spawn_projectile("arrow", _facing, float(_combat["damage_mult"]))
		"mage":
			if _skill_mode:
				_cast_nova()
			else:
				_spawn_projectile("bolt", _facing, float(_combat["damage_mult"]))
		_:
			if _skill_mode:
				_spin_hit()
			else:
				_do_hit()


# Guerreiro: golpe de espada em arco, só na frente.
func _do_hit() -> void:
	var reach: float = float(_combat["melee_reach"])
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null:
			continue
		var to := e.global_position - global_position
		var dist := to.length()
		if dist > reach + e.hit_radius:
			continue
		if dist > 8.0 and _facing.dot(to / dist) < 0.1:
			continue
		e.take_damage(_damage_for(float(_combat["damage_mult"])), global_position)


# Guerreiro (habilidade): giro com a espada, acerta todos ao redor.
func _spin_hit() -> void:
	var radius: float = float(_combat["skill_radius"])
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null:
			continue
		if e.global_position.distance_to(global_position) <= radius + e.hit_radius:
			e.take_damage(_damage_for(float(_combat["skill_mult"])), global_position)
	Fx.ring(get_parent(), global_position + Vector2(0, -4), Color("#f2dc94"), radius, 0.3)
	Fx.sparks(get_parent(), global_position + Vector2(0, -4), Color.WHITE, radius, 10, 0.25)


# Arqueiro / Mago: ponto de onde sai o projétil (na frente do personagem).
func _muzzle() -> Vector2:
	return global_position + Vector2(0, -6) + _facing * 8.0


func _spawn_projectile(kind: String, dir: Vector2, mult: float) -> void:
	var p := Projectile.new()
	p.kind = kind
	p.direction = dir.normalized()
	p.damage = _damage_for(mult)
	p.speed = float(_combat["proj_speed"])
	p.max_range = float(_combat["proj_range"])
	p.splash = float(_combat["splash"])
	get_parent().add_child(p)
	p.global_position = _muzzle()


# Arqueiro (habilidade): três flechas em leque.
func _fire_volley() -> void:
	for a in [-0.3, 0.0, 0.3]:
		_spawn_projectile("arrow", _facing.rotated(a), float(_combat["skill_mult"]))


# Mago (habilidade): explosão arcana ao redor.
func _cast_nova() -> void:
	var radius: float = float(_combat["skill_radius"])
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null:
			continue
		if e.global_position.distance_to(global_position) <= radius + e.hit_radius:
			e.take_damage(_damage_for(float(_combat["skill_mult"])), global_position)
	var pos := global_position + Vector2(0, -4)
	Fx.ring(get_parent(), pos, Color("#7fd8ff"), radius, 0.45)
	Fx.ring(get_parent(), pos, Color("#9b7bff"), radius * 0.6, 0.35)
	Fx.sparks(get_parent(), pos, Color("#c9f1ff"), radius, 14, 0.4)


func take_hit(amount: int = 10, from: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD or _invuln > 0.0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	_invuln = 0.7
	if from != Vector2.ZERO:
		_knock = (global_position - from).normalized() * 110.0
	FloatText.spawn(get_parent(), global_position, str(amount), Color("#e0605a"))
	if hp == 0:
		die()
		return
	Audio.play_sfx("hurt", 0.05)
	_set_state(State.HURT)


func heal(amount: int) -> void:
	if state == State.DEAD:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


func die() -> void:
	if state == State.DEAD:
		return
	hp = 0
	hp_changed.emit(hp, max_hp)
	Audio.play_sfx("death")
	_set_state(State.DEAD)


func revive() -> void:
	if state == State.DEAD:
		hp = max_hp
		_invuln = 1.2
		hp_changed.emit(hp, max_hp)
		Audio.play_sfx("revive")
		_set_state(State.IDLE)


# ------------------------------------------------------------------ mundo

func set_world(rect: Rect2) -> void:
	world_limit = rect
	_camera.limit_left = int(rect.position.x)
	_camera.limit_top = int(rect.position.y)
	_camera.limit_right = int(rect.end.x)
	_camera.limit_bottom = int(rect.end.y)


func teleport(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_camera.reset_smoothing()


func set_character_frame(frame: int) -> void:
	character_frame = frame
	if is_node_ready():
		_apply_frame()


func _max_hp_for(level: int) -> int:
	return base_hp + (level - 1) * hp_per_level


func _on_profile_changed() -> void:
	if Game.level == _last_level:
		return
	_last_level = Game.level
	max_hp = _max_hp_for(Game.level)
	if state != State.DEAD:
		hp = max_hp # subir de nível cura tudo
	hp_changed.emit(hp, max_hp)


func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	if state == State.ATTACK:
		_state_timer = _cur_attack_time
		_hit_done = false
	elif state == State.HURT:
		_state_timer = hurt_time
	state_changed.emit(state)


# ------------------------------------------------------------------ visual

func _build_weapon() -> void:
	_weapon = Node2D.new()
	_visual.add_child(_weapon)
	_weapon_sprite = Sprite2D.new()
	_weapon_sprite.texture = _body.texture
	_weapon_sprite.region_enabled = true
	_weapon_sprite.centered = false
	_weapon_sprite.offset = Vector2(-8, -12) # o "cabo" da arma fica no ponto de giro (a mão)
	_weapon.add_child(_weapon_sprite)


func _build_fx() -> void:
	# Camada de efeitos desenhada POR CIMA do corpo (arco, brilho do cajado, giro).
	_fx = Node2D.new()
	add_child(_fx)
	_fx.draw.connect(_draw_fx)


func _apply_frame() -> void:
	var col := character_frame % FRAME_COLS
	var row := character_frame / FRAME_COLS
	_body.region_rect = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	if _weapon_sprite:
		var wf: int = int(_combat.get("weapon_frame", 104))
		if wf < 0:
			wf = 104
		_weapon_sprite.region_rect = Rect2((wf % FRAME_COLS) * FRAME_SIZE, (wf / FRAME_COLS) * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)


func _attack_progress() -> float:
	return 1.0 - clampf(_state_timer / _cur_attack_time, 0.0, 1.0)


# O personagem tem uma pose só, então os movimentos são feitos por código:
# balanço ao andar, avanço e golpe de arma ao atacar, tremida ao levar dano e deitar ao morrer.
func _update_visual(delta: float) -> void:
	_anim_time += delta
	var offset := Vector2.ZERO
	var rot := 0.0
	var scl := Vector2.ONE
	var tint := Color.WHITE
	var weapon_rot := 0.35
	if combat_class == "mage":
		weapon_rot = 0.15 # cajado quase em pé

	match state:
		State.IDLE:
			scl.y = 1.0 + sin(_anim_time * 2.5) * 0.03
		State.WALK:
			var s := sin(_anim_time * 10.0)
			offset.y = -absf(s) * 1.5
			rot = s * 0.06
			weapon_rot = 0.35 + s * 0.12
		State.RUN:
			var s := sin(_anim_time * 16.0)
			offset.y = -absf(s) * 2.5
			rot = s * 0.1
			weapon_rot = 0.5 + s * 0.2
		State.ATTACK:
			var p := _attack_progress()
			var k := sin(p * PI)
			var rel := 1.0 - _release_frac
			match combat_class:
				"archer":
					# Puxa a corda para trás e solta; a habilidade tem recuo maior.
					offset = -_facing * k * (3.0 if _skill_mode else 1.5)
				"mage":
					if _skill_mode:
						offset.y = -k * 3.0
						scl = Vector2.ONE * (1.0 + k * 0.12)
						weapon_rot = -0.2
					else:
						scl = Vector2(1.0 - k * 0.04, 1.0 + k * 0.08)
						if p < rel:
							weapon_rot = lerpf(0.15, -0.7, p / rel)
						else:
							weapon_rot = lerpf(-0.7, 1.0, (p - rel) / maxf(1.0 - rel, 0.01))
				_:
					if _skill_mode:
						rot = p * TAU
						weapon_rot = p * TAU * 2.0 + 1.0
						scl = Vector2(1.0 + k * 0.1, 1.0 - k * 0.06)
					else:
						offset = _facing * k * 4.0
						scl = Vector2(1.0 + k * 0.1, 1.0 - k * 0.06)
						var e := 1.0 - pow(1.0 - p, 3.0)
						weapon_rot = lerpf(-1.4, 1.8, e)
		State.HURT:
			offset.x = sin(_anim_time * 60.0) * 1.5
			tint = Color(1.0, 0.4, 0.4)
		State.DEAD:
			rot = PI / 2.0
			tint = Color(0.5, 0.5, 0.55)

	if _invuln > 0.0 and state != State.DEAD and int(_invuln * 25.0) % 2 == 0:
		tint.a = 0.5

	_visual.position = offset
	_visual.rotation = rot
	_visual.scale = scl
	_body.flip_h = _facing_left
	_body.modulate = tint

	_weapon.visible = state != State.DEAD and combat_class != "archer"
	_weapon.position = Vector2(-6.0 if _facing_left else 6.0, -6.0)
	_weapon.scale.x = -1.0 if _facing_left else 1.0
	_weapon.rotation = weapon_rot
	_weapon_sprite.modulate = tint
	queue_redraw()
	if _fx:
		_fx.queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Rastro do golpe de espada (só o Guerreiro, ataque normal)
	if state == State.ATTACK and combat_class == "warrior" and not _skill_mode:
		var p := _attack_progress()
		var e := 1.0 - pow(1.0 - p, 3.0)
		var a0 := -1.4 - PI / 2.0
		var a1 := lerpf(-1.4, 1.8, e) - PI / 2.0
		if a1 - a0 > 0.1:
			var center := Vector2(-6.0 if _facing_left else 6.0, -6.0)
			var col := Color(1, 1, 1, 0.7 * (1.0 - p))
			if _facing_left:
				draw_arc(center, 14.0, PI - a1, PI - a0, 12, col, 2.0)
			else:
				draw_arc(center, 14.0, a0, a1, 12, col, 2.0)


# ------------------------------------------------------------------ efeitos por classe

func _draw_fx() -> void:
	if state == State.DEAD:
		return
	match combat_class:
		"archer":
			_fx_bow()
		"mage":
			_fx_orb()
		_:
			_fx_spin()


# Giro do guerreiro: arco branco girando em volta do corpo.
func _fx_spin() -> void:
	if state != State.ATTACK or not _skill_mode:
		return
	var p := _attack_progress()
	var start := p * TAU - 2.2
	_fx.draw_arc(Vector2(0, -6), 17.0, start, start + 2.2, 16, Color(1, 1, 1, 0.85 * (1.0 - p)), 3.0)
	_fx.draw_arc(Vector2(0, -6), 14.0, start - 0.4, start + 1.6, 16, Color(0.95, 0.86, 0.58, 0.6 * (1.0 - p)), 2.0)


# Arco do arqueiro: segurado na frente do corpo; ao atacar, puxa a corda com a flecha e solta.
func _fx_bow() -> void:
	var aim := _facing.angle()
	var rel := 1.0 - _release_frac
	var p := _attack_progress()
	var pull := 0.0
	var nocked := false
	if state == State.ATTACK and p < rel:
		pull = 6.0 * (p / maxf(rel, 0.01))
		nocked = true
	var radius := 8.0
	var half := 1.05
	var grip := Vector2(0, -6) + _visual.position + _facing * 7.0
	var center := grip - _facing * radius
	var tint := Color(1, 1, 1, 0.5) if (_invuln > 0.0 and int(_invuln * 25.0) % 2 == 0) else Color.WHITE
	_fx.draw_arc(center, radius, aim - half, aim + half, 14, DARK_WOOD * tint, 4.0)
	_fx.draw_arc(center, radius, aim - half, aim + half, 14, LIGHT_WOOD * tint, 2.0)
	var t1 := center + Vector2.from_angle(aim - half) * radius
	var t2 := center + Vector2.from_angle(aim + half) * radius
	var mid := (t1 + t2) * 0.5 - _facing * pull
	_fx.draw_line(t1, mid, Color("#e8e2d0") * tint, 1.0)
	_fx.draw_line(mid, t2, Color("#e8e2d0") * tint, 1.0)
	if nocked:
		var tip := mid + _facing * 12.0
		_fx.draw_line(mid, tip, Color("#d9c7a0"), 1.5)
		_fx.draw_colored_polygon(PackedVector2Array([
			tip + _facing * 3.0, tip + _facing.orthogonal() * 1.8, tip - _facing.orthogonal() * 1.8
		]), Color("#e8e8f0"))


# Brilho na ponta do cajado: cresce ao carregar a magia e estoura ao lançar.
func _fx_orb() -> void:
	var tip: Vector2 = _visual.transform * (_weapon.transform * Vector2(0.0, -11.0))
	var p := _attack_progress()
	var rel := 1.0 - _release_frac
	var glow := 0.35 + 0.15 * sin(_anim_time * 5.0)
	var r := 2.5
	if state == State.ATTACK:
		if p < rel:
			r = 2.5 + 4.0 * (p / maxf(rel, 0.01))
			glow = 0.6
		else:
			r = 2.5 + 4.0 * (1.0 - (p - rel) / maxf(1.0 - rel, 0.01))
			glow = 0.5
		if _skill_mode:
			r *= 1.4
	_fx.draw_circle(tip, r + 2.0, Color(0.4, 0.8, 1.0, glow))
	_fx.draw_circle(tip, r, Color(0.7, 0.95, 1.0, 0.9))
	_fx.draw_circle(tip, r * 0.45, Color.WHITE)
	for i in 3:
		var a := _anim_time * 3.0 + i * TAU / 3.0
		_fx.draw_rect(Rect2(tip + Vector2.from_angle(a) * (r + 3.0) - Vector2(0.5, 0.5), Vector2(1, 1)), Color(0.8, 0.95, 1.0, 0.9))