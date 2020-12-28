extends "res://material_maker/widgets/curve_edit/curve_view.gd"

signal value_changed(value)

func _ready():
	update_controls()

func set_curve(c : MMCurve) -> void:
	curve = c
	update()
	update_controls()

func update_controls() -> void:
	for c in get_children():
		c.queue_free()
	for i in curve.points.size():
		var p = curve.points[i]
		var control_point = preload("res://material_maker/widgets/curve_edit/control_point.tscn").instance()
		add_child(control_point)
		control_point.initialize(p)
		control_point.rect_position = transform_point(p.p)-control_point.OFFSET
		if i == 0 or i == curve.points.size()-1:
			control_point.set_constraint(control_point.rect_position.x, control_point.rect_position.x, -control_point.OFFSET.y, rect_size.y-control_point.OFFSET.y)
			if i == 0:
				control_point.get_child(0).visible = false
			else:
				control_point.get_child(1).visible = false
		else:
			var min_x = transform_point(curve.points[i-1].p).x+1
			var max_x = transform_point(curve.points[i+1].p).x-1
			control_point.set_constraint(min_x, max_x, -control_point.OFFSET.y, rect_size.y-control_point.OFFSET.y)
		control_point.connect("moved", self, "_on_ControlPoint_moved")
		control_point.connect("removed", self, "_on_ControlPoint_removed")
	emit_signal("value_changed", curve)

func _on_ControlPoint_moved(index):
	var control_point = get_child(index)
	curve.points[index].p = reverse_transform_point(control_point.rect_position+control_point.OFFSET)
	if control_point.has_node("LeftSlope"):
		var slope_vector = control_point.get_node("LeftSlope").rect_position/rect_size
		if slope_vector.x != 0:
			curve.points[index].ls = -slope_vector.y / slope_vector.x
	if control_point.has_node("RightSlope"):
		var slope_vector = control_point.get_node("RightSlope").rect_position/rect_size
		if slope_vector.x != 0:
			curve.points[index].rs = -slope_vector.y / slope_vector.x
	update()
	emit_signal("value_changed", curve)

func _on_ControlPoint_removed(index):
	if curve.remove_point(index):
		update()
		update_controls()

func _on_CurveEditor_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.doubleclick:
			var new_point_position = reverse_transform_point(get_local_mouse_position())
			curve.add_point(new_point_position.x, new_point_position.y, 0.0, 0.0)
			update_controls()

func _on_resize() -> void:
	._on_resize()
	update_controls()
