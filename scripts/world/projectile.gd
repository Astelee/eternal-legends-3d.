class_name Projectile
extends Node2D
# Projétil do Arqueiro ("arrow") e do Mago ("bolt").
# A flecha acerta o primeiro inimigo no caminho; a esfera arcana explode (dano em área).
# Ambos somem ao bater em parede ou ao passar do alcance.

var kind: String = "arrow"
var direction: Vector2 = Vector2.RIGHT
var speed: float = 240.0
var max_range: float = 140.0
var damage: int = 10
var splash: float = 0.0

var _origin: Vector2
var _started: bool = false
var _travelled: float = 0.0
var _trail: Array[Vector2] = []
var _done: bool = false


func _ready() -> void:
	z_index = 2
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _done:
		return
	if not _started:
		_started = true
		_origin = global_position
	var from := global_position
	var step := speed * delta
	var to := from + direction * step

	# Parede: qualquer colisão que não seja personagem (jogador, NPC, inimigo).
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and not (hit["collider"] is CharacterBody2D):
		global_position = hit["position"]
		_impact(null)
		return

	# Inimigos: distância do centro do inimigo ao trecho percorrido neste quadro.
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null:
			continue
		var center := e.global_position + Vector2(0, -4)
		var closest := Geometry2D.get_closest_point_to_segment(center, from, to)
		if closest.distance_to(center) <= e.hit_radius + 2.0:
			global_position = closest
			_impact(e)
			return

	global_position = to
	_travelled += step
	if kind == "bolt":
		_trail.append(global_position)
		if _trail.size() > 7:
			_trail.remove_at(0)
	if _travelled >= max_range:
		if kind == "bolt":
			_impact(null)
		else:
			_done = true
			queue_free()


func _impact(target: Enemy) -> void:
	_done = true
	var parent := get_parent()
	if kind == "bolt":
		Fx.ring(parent, global_position, Color("#7fd8ff"), splash * 1.5 + 6.0, 0.3)
		Fx.sparks(parent, global_position, Color("#c9f1ff"), 18.0, 8, 0.3)
		for n in get_tree().get_nodes_in_group("enemies"):
			var e := n as Enemy
			if e == null:
				continue
			if e.global_position.distance_to(global_position) <= splash + e.hit_radius:
				e.take_damage(damage, global_position)
	else:
		Fx.sparks(parent, global_position, Color("#d9c7a0"), 8.0, 5, 0.2)
		if target != null:
			target.take_damage(damage, _origin)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if kind == "arrow":
		draw_line(Vector2(-9, 0), Vector2(4, 0), Color("#d9c7a0"), 1.5)
		draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(3, -2.2), Vector2(3, 2.2)]), Color("#e8e8f0"))
		draw_line(Vector2(-9, 0), Vector2(-12, -2.5), Color("#c0392b"), 1.0)
		draw_line(Vector2(-9, 0), Vector2(-12, 2.5), Color("#c0392b"), 1.0)
	else:
		for i in _trail.size():
			var f := float(i) / float(maxi(_trail.size(), 1))
			draw_circle(to_local(_trail[i]), 1.0 + 2.5 * f, Color(0.5, 0.85, 1.0, 0.5 * f))
		draw_circle(Vector2.ZERO, 5.5, Color(0.4, 0.8, 1.0, 0.35))
		draw_circle(Vector2.ZERO, 3.4, Color(0.6, 0.95, 1.0))
		draw_circle(Vector2.ZERO, 1.6, Color.WHITE)