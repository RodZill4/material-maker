tool
extends Control

var curve : MMCurve

signal value_changed(value)

func _ready() -> void:
	curve = MMCurve.new()
	connect("resized", self, "_on_resize")
	update()

func transform_point(p : Vector2) -> Vector2:
	return (Vector2(0.0, 1.0)+Vector2(1.0, -1.0)*p)*rect_size

func reverse_transform_point(p : Vector2) -> Vector2:
	return Vector2(0.0, 1.0)+Vector2(1.0, -1.0)*p/rect_size

func _draw():
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
			var np = transform_point(Vector2(x, lerp(y1, y2, 3.0*tt*tt-2.0*tt*tt*tt)))
			draw_line(p, np, Color(1.0, 1.0, 1.0))
			p = np

func _on_resize() -> void:
	update()
