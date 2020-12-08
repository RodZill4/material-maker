tool
extends Control

export var show_axes : bool = false

var curve : MMCurve

func _ready() -> void:
	curve = MMCurve.new()
	connect("resized", self, "_on_resize")
	update()

func transform_point(p : Vector2) -> Vector2:
	return (Vector2(0.0, 1.0)+Vector2(1.0, -1.0)*p)*rect_size

func reverse_transform_point(p : Vector2) -> Vector2:
	return Vector2(0.0, 1.0)+Vector2(1.0, -1.0)*p/rect_size

func _draw():
	if show_axes:
		for i in range(5):
			var p = transform_point(0.25*Vector2(i, i))
			draw_line(Vector2(p.x, 0), Vector2(p.x, rect_size.y-1), Color(0.25, 0.25, 0.25))
			draw_line(Vector2(0, p.y), Vector2(rect_size.x-1, p.y), Color(0.25, 0.25, 0.25))
	for i in range(curve.points.size()-1):
		var p1 = curve.points[i].p
		var s1 = curve.points[i].rs
		var p2 = curve.points[i+1].p
		var s2 = curve.points[i+1].ls
		var p = transform_point(p1)
		var count : int = max(1, int((transform_point(p2).x-p.x/5.0)))
		for t in range(count):
			var tt = (t+1.0)/count
			var x = p1.x+(p2.x-p1.x)*tt
			var y1 = p1.y+(x-p1.x)*s1
			var y2 = p2.y+(x-p2.x)*s2
			var np = transform_point(Vector2(x, lerp(y1, y2, (3.0-2.0*tt)*tt*tt)))
			draw_line(p, np, Color(1.0, 1.0, 1.0))
			p = np

func _on_resize() -> void:
	update()
