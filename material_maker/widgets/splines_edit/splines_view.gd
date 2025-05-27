@tool
class_name SplinesView

extends Control


@export var draw_area : bool = true
@export var auto_rescale : bool = true
@export var draw_control_lines : bool = false
@export var draw_width : bool = false


var splines : MMSplines
var edited : MMSplines.Bezier = null

var draw_size : Vector2 = Vector2(1, 1)
var draw_offset : Vector2 = Vector2(0, 0)

func _init(v : MMSplines = null) -> void:
	splines = v

func _ready() -> void:
	if splines == null:
		splines = MMSplines.new()
	_on_resized()

func set_view_rect(do : Vector2, ds : Vector2):
	draw_size = ds
	draw_offset = do
	queue_redraw()

func transform_point(p : Vector2) -> Vector2:
	return draw_offset+p*draw_size

func reverse_transform_point(p : Vector2) -> Vector2:
	return (p-draw_offset)/draw_size

func draw_bezier(b, color : Color, draw_radius : bool = false):
	var p1 : Vector2 = transform_point(b.points[0].position)
	var p2 : Vector2 = transform_point(b.points[1].position)
	var p3 : Vector2 = transform_point(b.points[2].position)
	var p4 : Vector2 = transform_point(b.points[3].position)
	var last_point : Vector2 = p1
	for i in range(20):
		var p : Vector2 = p1.bezier_interpolate(p2, p3, p4, float(i+1)/20)
		draw_line(last_point, p, color)
		last_point = p
	if draw_control_lines:
		draw_line(p1, p2, color)
		draw_line(p3, p4, color)
	if draw_radius:
		draw_arc(p1, b.points[0].width*draw_size.x, 0, TAU, 32, color)
		draw_arc(p2, b.points[1].width*draw_size.x, 0, TAU, 32, color)
		draw_arc(p3, b.points[2].width*draw_size.x, 0, TAU, 32, color)
		draw_arc(p4, b.points[3].width*draw_size.x, 0, TAU, 32, color)

func _draw():
	var current_theme : Theme = mm_globals.main_window.theme
	var bg = current_theme.get_stylebox("panel", "Panel").bg_color
	var fg = current_theme.get_color("font_color", "Label")
	var axes_color : Color = bg.lerp(fg, 0.25)
	var curve_color : Color = bg.lerp(fg, 0.75)
	if draw_area:
		draw_rect(Rect2(draw_offset, draw_size), axes_color, false)
	if edited != null:
		draw_bezier(edited, fg)
	if splines != null:
		for b in splines.splines:
			draw_bezier(b, curve_color, draw_width)

func _on_resized():
	if auto_rescale:
		var ds : float = min(size.x, size.y)
		set_view_rect(0.5*(size-draw_size), Vector2(ds, ds))
