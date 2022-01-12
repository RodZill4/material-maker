tool
extends Control

var polygon: MMPolygon

var draw_size: Vector2 = Vector2(1, 1)
var draw_offset: Vector2 = Vector2(0, 0)
var closed: bool = true


func set_closed(c: bool = true):
	closed = c
	update()


func _ready() -> void:
	polygon = MMPolygon.new()
	connect("resized", self, "_on_resize")
	_on_resize()


func transform_point(p: Vector2) -> Vector2:
	return draw_offset + p * draw_size


func reverse_transform_point(p: Vector2) -> Vector2:
	return (p - draw_offset) / draw_size


func _draw():
	var current_theme: Theme = get_node("/root/MainWindow").theme
	var bg = current_theme.get_stylebox("panel", "Panel").bg_color
	var fg = current_theme.get_color("font_color", "Label")
	var axes_color: Color = bg.linear_interpolate(fg, 0.25)
	var curve_color: Color = bg.linear_interpolate(fg, 0.75)
	draw_rect(Rect2(draw_offset, draw_size), axes_color, false)
	var tp: Vector2 = transform_point(polygon.points[polygon.points.size() - 1 if closed else 0])
	for p in polygon.points:
		var tnp = transform_point(p)
		draw_line(tp, tnp, curve_color)
		tp = tnp


func _on_resize() -> void:
	var ds: float = min(rect_size.x, rect_size.y)
	draw_size = Vector2(ds, ds)
	draw_offset = 0.5 * (rect_size - draw_size)
	update()
