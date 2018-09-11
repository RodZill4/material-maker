extends Control

var clip_pos = Vector2(0, 0)
var clip_size = Vector2(0, 0)
var end
var source = null
var target = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func clip(p, s):
	clip_pos = p
	rect_global_position = Vector2(0, 0)
	rect_size = s
	rect_clip_content = true

func closest(rect, point):
	return Vector2(max(rect.position.x, min(rect.end.x, point.x)), max(rect.position.y, min(rect.end.y, point.y)))

func _draw():
	var start = source.rect_global_position+0.5*source.rect_size*source.get_global_transform().get_scale()
	var color = Color(1, 0.5, 0.5, 0.5)
	var rect
	if target != null:
		color = Color(0.5, 1, 0.5, 0.5)
		rect = Rect2(target.rect_global_position, target.rect_size*target.get_global_transform().get_scale())
		draw_rect(Rect2(rect.position-clip_pos, rect.size), color, false)
		end = closest(rect, start)
	rect = Rect2(source.rect_global_position, source.rect_size*source.get_global_transform().get_scale())
	draw_rect(Rect2(rect.position-clip_pos, rect.size), color, false)
	start = closest(rect, end)
	draw_line(start-clip_pos, end-clip_pos, color, 1, true)
