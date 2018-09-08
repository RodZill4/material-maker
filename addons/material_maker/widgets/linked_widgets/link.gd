extends Node2D

var end
var source = null
var target = null

func closest(rect, point):
	return Vector2(max(rect.position.x, min(rect.end.x, point.x)), max(rect.position.y, min(rect.end.y, point.y)))

func _draw():
	var start = source.rect_global_position+0.5*source.rect_size*source.get_global_transform().get_scale()
	var color = Color(1, 0.5, 0.5, 0.5)
	var rect
	if target != null:
		color = Color(0.5, 1, 0.5, 0.5)
		rect = Rect2(target.rect_global_position, target.rect_size*target.get_global_transform().get_scale())
		draw_rect(rect, color, false)
		end = closest(rect, start)
	rect = Rect2(source.rect_global_position, source.rect_size*source.get_global_transform().get_scale())
	draw_rect(rect, color, false)
	start = closest(rect, end)
	draw_line(start, end, color, 1, true)
