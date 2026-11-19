class_name FloatText
extends RefCounted
# Texto que sobe e some (dano, XP, cura).


static func spawn(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.z_index = 100
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("#14101a"))
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	l.global_position = pos + Vector2(-10, -28)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 14.0, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)