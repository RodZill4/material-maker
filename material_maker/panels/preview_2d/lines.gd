extends Control

func _draw() -> void:
	var parent = get_parent()
	var p
	p = parent.value_to_pos(Vector2(-0.5, -0.52))
	draw_line(p, Vector2(p.x, 0), Color(0.5, 0.5, 0.5))
	p = parent.value_to_pos(Vector2(0.5, -0.52))
	draw_line(p, Vector2(p.x, 0), Color(0.5, 0.5, 0.5))
	p = parent.value_to_pos(Vector2(-0.52, -0.5))
	draw_line(p, Vector2(0, p.y), Color(0.5, 0.5, 0.5))
	p = parent.value_to_pos(Vector2(-0.52, 0.5))
	draw_line(p, Vector2(0, p.y), Color(0.5, 0.5, 0.5))
	p = parent.value_to_pos(Vector2(-0.5, 0.52))
	draw_line(p, Vector2(p.x, rect_size.y), Color(0.5, 0.5, 0.5))
	p = parent.value_to_pos(Vector2(0.5, 0.52))
	draw_line(p, Vector2(p.x, rect_size.y), Color(0.5, 0.5, 0.5))
	p = parent.value_to_pos(Vector2(0.52, -0.5))
	draw_line(p, Vector2(rect_size.x, p.y), Color(0.5, 0.5, 0.5))
	p = parent.value_to_pos(Vector2(0.52, 0.5))
	draw_line(p, Vector2(rect_size.x, p.y), Color(0.5, 0.5, 0.5))
