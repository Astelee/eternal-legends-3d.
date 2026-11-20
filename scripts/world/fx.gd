class_name Fx
extends Node2D
# Efeitos rápidos de combate: anel que se expande e faíscas. Some sozinho.

var kind: String = "ring" # "ring" | "sparks"
var color: Color = Color.WHITE
var radius: float = 20.0
var life: float = 0.35
var count: int = 8

var _t: float = 0.0
var _angles: Array[float] = []
var _lens: Array[float] = []


static func ring(parent: Node, pos: Vector2, col: Color, rad: float, duration: float = 0.35) -> void:
	var f := Fx.new()
	f.kind = "ring"
	f.color = col
	f.radius = rad
	f.life = duration
	parent.add_child(f)
	f.global_position = pos


static func sparks(parent: Node, pos: Vector2, col: Color, rad: float, amount: int = 8, duration: float = 0.3) -> void:
	var f := Fx.new()
	f.kind = "sparks"
	f.color = col
	f.radius = rad
	f.count = amount
	f.life = duration
	parent.add_child(f)
	f.global_position = pos


func _ready() -> void:
	z_index = 3
	for i in count:
		_angles.append(randf() * TAU)
		_lens.append(randf_range(0.5, 1.0))


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / life, 0.0, 1.0)
	var a := 1.0 - k
	if kind == "ring":
		var e := 1.0 - pow(1.0 - k, 3.0)
		var r := radius * (0.25 + 0.75 * e)
		draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, a * 0.15))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(color.r, color.g, color.b, a), 2.0)
	else:
		for i in _angles.size():
			var d := Vector2.from_angle(_angles[i])
			var far := radius * k * _lens[i]
			draw_line(d * far * 0.5, d * far, Color(color.r, color.g, color.b, a), 1.5)