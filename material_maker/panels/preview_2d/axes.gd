extends Control

var point : Vector2

const AXIS_X := Color(0.029, 0.788, 0.02, 1.0)
const AXIS_Y := Color(1.0, 0.042, 0.022, 1.0)

func _draw() -> void:
	if point:
		var parent = get_parent()
		var xf : Vector2 = parent.value_to_pos(Vector2(-1.0, 0.0))
		var xt : Vector2 = parent.value_to_pos(Vector2(1.0, 0.0))

		var yf : Vector2 = parent.value_to_pos(Vector2(0.0, -1.0))
		var yt : Vector2 = parent.value_to_pos(Vector2(0.0, 1.0))

		draw_line(Vector2(point.x, yf.y), Vector2(point.x, yt.y), Color.BLACK, 4.0)
		draw_line(Vector2(point.x, yf.y), Vector2(point.x, yt.y), AXIS_Y, 2.0)

		draw_line(Vector2(xf.x, point.y), Vector2(xt.x, point.y), Color.BLACK, 4.0)
		draw_line(Vector2(xf.x, point.y), Vector2(xt.x, point.y), AXIS_X, 2.0)
