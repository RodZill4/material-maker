@tool
class_name PolygonView

extends Control


@export var draw_area : bool = true
@export var auto_rescale : bool = true
@export var show_axes : bool = false
@export var axes_density : int = 5

var polygon : MMPolygon

var draw_size : Vector2 = Vector2(1, 1)
var draw_offset : Vector2 = Vector2(0, 0)
var closed : bool = true

func _init(v : MMPolygon = null) -> void:
	polygon = v

func set_closed(c : bool = true):
	closed = c
	queue_redraw()

func _ready() -> void:
	if polygon == null:
		polygon = MMPolygon.new()
	connect("resized", Callable(self, "_on_resize"))
	_on_resize()

func set_view_rect(do : Vector2, ds : Vector2):
	draw_size = ds
	draw_offset = do
	queue_redraw()

func transform_point(p : Vector2) -> Vector2:
	return draw_offset+p*draw_size

func reverse_transform_point(p : Vector2) -> Vector2:
	return (p-draw_offset)/draw_size

func _draw():
	var current_theme : Theme = mm_globals.main_window.theme
	var bg = current_theme.get_stylebox("panel", "Panel").bg_color
	var fg = current_theme.get_color("font_color", "Label")
	var axes_color : Color = bg.lerp(fg, 0.25)
	var curve_color : Color = bg.lerp(fg, 0.75)
	if draw_area:
		draw_rect(Rect2(draw_offset, draw_size), axes_color, false)
	if show_axes:
		for i in range(axes_density):
			var step : float = 1/(axes_density-1.0)*i
			draw_line(transform_point(Vector2(0.0, step)), transform_point(Vector2(1.0, step)), axes_color)
			draw_line(transform_point(Vector2(step, 0.0)), transform_point(Vector2(step, 1.0)), axes_color)
	var tp : Vector2 = transform_point(polygon.points[polygon.points.size()-1 if closed else 0])
	for p in polygon.points:
		var tnp = transform_point(p)
		draw_line(tp, tnp, curve_color, 0.5, true)
		tp = tnp

func _on_resize() -> void:
	if auto_rescale:
		var ds : float = min(size.x, size.y)
		set_view_rect(0.5*(size-draw_size), Vector2(ds, ds))
