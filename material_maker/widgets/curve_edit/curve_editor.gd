extends "res://material_maker/widgets/curve_edit/curve_view.gd"


signal value_changed(value)


func _ready():
	super._ready()
	update_controls()

func set_curve(c : MMCurve) -> void:
	curve = c
	queue_redraw()
	update_controls()

func update_controls() -> void:
	for c in get_children():
		c.queue_free()
	for i in curve.points.size():
		var p = curve.points[i]
		var control_point = preload("res://material_maker/widgets/curve_edit/control_point.tscn").instantiate()
		add_child(control_point)
		control_point.initialize(p)
		control_point.position = transform_point(p.p)-control_point.OFFSET
		if i == 0 or i == curve.points.size()-1:
			control_point.set_constraint(control_point.position.x, control_point.position.x, -control_point.OFFSET.y, size.y-control_point.OFFSET.y)
			if i == 0:
				control_point.get_child(0).visible = false
			else:
				control_point.get_child(1).visible = false
		else:
			var min_x = transform_point(curve.points[i-1].p).x+1
			var max_x = transform_point(curve.points[i+1].p).x-1
			control_point.set_constraint(min_x, max_x, -control_point.OFFSET.y, size.y-control_point.OFFSET.y)
		control_point.connect("moved", Callable(self, "_on_ControlPoint_moved"))
		control_point.connect("removed", Callable(self, "_on_ControlPoint_removed"))
	emit_signal("value_changed", curve)

func _on_ControlPoint_moved(index):
	var control_point = get_child(index)
	curve.points[index].p = reverse_transform_point(control_point.position+control_point.OFFSET)
	if control_point.has_node("LeftSlope"):
		var slope_vector = control_point.get_node("LeftSlope").position/size
		if slope_vector.x != 0:
			curve.points[index].ls = -slope_vector.y / slope_vector.x
	if control_point.has_node("RightSlope"):
		var slope_vector = control_point.get_node("RightSlope").position/size
		if slope_vector.x != 0:
			curve.points[index].rs = -slope_vector.y / slope_vector.x
	queue_redraw()
	emit_signal("value_changed", curve)

func _on_ControlPoint_removed(index):
	if curve.remove_point(index):
		queue_redraw()
		update_controls()

func _on_CurveEditor_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			var new_point_position = reverse_transform_point(get_local_mouse_position())
			curve.add_point(new_point_position.x, new_point_position.y, 0.0, 0.0)
			update_controls()

func _on_resize() -> void:
	super._on_resize()
	update_controls()
