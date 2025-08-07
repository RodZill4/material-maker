@tool
class_name CurveView

extends Control

@export var show_axes : bool = false
@export var axes_density : int = 5

var curve : MMCurve

func _init(v : MMCurve = null) -> void:
	curve = v

func _ready() -> void:
	if curve == null:
		curve = MMCurve.new()
	connect("resized",Callable(self,"_on_resize"))
	queue_redraw()

func transform_point(p : Vector2) -> Vector2:
	return (Vector2(0.0, 1.0)+Vector2(1.0, -1.0)*p)*size

func reverse_transform_point(p : Vector2) -> Vector2:
	return Vector2(0.0, 1.0)+Vector2(1.0, -1.0)*p/size

func _draw():
	var current_theme : Theme = mm_globals.main_window.theme
	var bg = current_theme.get_stylebox("panel", "Panel").bg_color
	var fg = current_theme.get_color("font_color", "Label")
	var axes_color : Color = bg.lerp(fg, 0.25)
	var curve_color : Color = bg.lerp(fg, 0.75)
	if show_axes:
		for i in range(axes_density):
			var p = transform_point(1.0/(axes_density-1)*Vector2(i, i))
			draw_line(Vector2(p.x, 0), Vector2(p.x, size.y-1), axes_color)
			draw_line(Vector2(0, p.y), Vector2(size.x-1, p.y), axes_color)
	var points : PackedVector2Array = PackedVector2Array()
	for i in range(curve.points.size()-1):
		var p1 = curve.points[i].p
		var p2 = curve.points[i+1].p
		var d = (p2.x-p1.x)/3.0
		var yac = p1.y+d*curve.points[i].rs
		var ybc = p2.y-d*curve.points[i+1].ls
		var p = transform_point(p1)
		if points.is_empty():
			points.push_back(p)
		var count : int = int(max(1, (transform_point(p2).x-p.x/5.0)))
		for tt in range(count):
			var t = (tt+1.0)/count
			var omt = (1.0 - t)
			var omt2 = omt * omt
			var omt3 = omt2 * omt
			var t2 = t * t
			var t3 = t2 * t
			var x = p1.x+(p2.x-p1.x)*t
			p = transform_point(Vector2(x, p1.y*omt3 + yac*omt2*t*3.0 + ybc*omt*t2*3.0 + p2.y*t3))
			points.push_back(p)
	draw_polyline(points, curve_color, 0.5, true)

func _on_resize() -> void:
	queue_redraw()
