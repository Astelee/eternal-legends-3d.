class_name EnemyShot
extends Node2D
# Tiro dos inimigos à distância (arqueiros, magos, chefe final).
# Voa reto, some ao bater em parede e fere o jogador ao encostar nele.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 100.0
var damage: int = 8
var color: Color = Color("#c98bff")
var radius: float = 3.0

var _life: float = 3.0
var _done: bool = false


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	if _done:
		return
	_life -= delta
	if _life <= 0.0:
		_done = true
		queue_free()
		return

	var from := global_position
	var to := from + direction * speed * delta

	# Parede: qualquer colisão que não seja personagem.
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and not (hit["collider"] is CharacterBody2D):
		global_position = hit["position"]
		_burst()
		return

	global_position = to

	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and player.state != Player.State.DEAD:
		var center := player.global_position + Vector2(0, -6)
		if center.distance_to(global_position) <= radius + 5.0:
			player.take_hit(damage, global_position - direction * 8.0)
			_burst()
			return
	queue_redraw()


func _burst() -> void:
	_done = true
	Fx.sparks(get_parent(), global_position, color, 8.0, 6, 0.25)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 2.0, Color(color.r, color.g, color.b, 0.3))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.5, Color.WHITE)