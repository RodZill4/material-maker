@tool
extends "res://material_maker/widgets/curve_edit/curve_view.gd"


signal value_changed(value)

var point_index : int = 0


func _ready():
	super._ready()
	update_controls()
	update_control_ui()
	%ControlUI.hide()


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
		control_point.selected.connect(_on_ControlPoint_selected)
	emit_signal("value_changed", curve)


func _on_ControlPoint_moved(index):
	var control_point = get_child(index)
	curve.points[index].p = reverse_transform_point(control_point.position+control_point.OFFSET)
	if control_point.has_node("LeftSlope"):
		var slope_vector = control_point.get_node("LeftSlope").position/size
		if slope_vector.x != 0:
			curve.points[index].ls = -slope_vector.y / slope_vector.x
			%LeftSlope.value = snappedf(-rad_to_deg(atan(curve.points[index].ls)), 0.01)

	if control_point.has_node("RightSlope"):
		var slope_vector = control_point.get_node("RightSlope").position/size
		if slope_vector.x != 0:
			curve.points[index].rs = -slope_vector.y / slope_vector.x
			%RightSlope.value = snappedf(rad_to_deg(atan(curve.points[index].rs)), 0.01)
	update_control_ui()
	queue_redraw()
	emit_signal("value_changed", curve)


func _on_ControlPoint_removed(index):
	if curve.remove_point(index):
		%ControlUI.hide()
		queue_redraw()
		update_controls()


func update_control_ui():
	%ControlUI.show()
	%LeftSlope.value = snappedf(-rad_to_deg(atan(curve.points[point_index].ls)), 1e-2)
	%RightSlope.value = snappedf(rad_to_deg(atan(curve.points[point_index].rs)), 1e-2)
	%PositionY.value = snappedf(curve.points[point_index].p.y, 1e-3)
	if point_index == 0 or point_index == curve.points.size()-1:
		%PositionX.editable = false
		%PositionX.modulate = Color.WEB_GRAY
		if point_index == 0:
			%PositionX.value = 0
			%LeftSlope.value = 0
			%LeftSlope.editable = false
			%RightSlope.editable = true
			%LeftSlope.modulate = Color.WEB_GRAY
			%RightSlope.modulate = Color.WHITE
		else:
			%PositionX.value = 1
			%RightSlope.value = 0
			%LeftSlope.editable = true
			%RightSlope.editable = false
			%LeftSlope.modulate = Color.WHITE
			%RightSlope.modulate = Color.WEB_GRAY
	else:
		%PositionX.editable = true
		%PositionY.editable = true
		%PositionX.modulate = Color.WHITE
		
		%LeftSlope.editable = true
		%RightSlope.editable = true
		%LeftSlope.modulate = Color.WHITE
		%RightSlope.modulate = Color.WHITE


		%PositionX.min_value = curve.points[point_index-1].p.x
		%PositionX.max_value = curve.points[point_index+1].p.x
		%PositionX.value = snappedf(clamp(
				curve.points[point_index].p.x,
				%PositionX.min_value, %PositionX.max_value),1e-3)

func _on_ControlPoint_selected(index):
	point_index = index
	update_control_ui()


func _on_CurveEditor_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and %ControlUI.visible:
				# release float fields' focus to make text submission work
				%ControlUI.hide()
				%ControlUI.show()
			if event.double_click:
				var new_point_position = reverse_transform_point(get_local_mouse_position())
				var new_index = curve.add_point(new_point_position.x, new_point_position.y, 0.0, 0.0)
				point_index = new_index
				_on_ControlPoint_selected(new_index)
				update_controls()


func _on_resize() -> void:
	super._on_resize()
	update_controls()


func _on_position_x_value_changed(value: Variant) -> void:
	curve.points[point_index].p.x = clamp(
			value, %PositionX.min_value, %PositionX.max_value)
	queue_redraw()
	update_controls()


func _on_position_y_value_changed(value: Variant) -> void:
	curve.points[point_index].p.y = clamp(
				value, %PositionY.min_value, %PositionY.max_value)
	queue_redraw()
	update_controls()


func _on_left_slope_value_changed(value: Variant) -> void:
	if point_index != 0:
		var rad = deg_to_rad(clamp(value, %LeftSlope.min_value, %LeftSlope.max_value))
		curve.points[point_index].ls = snappedf(-tan(rad), 1e-2)
	update_controls()
	queue_redraw()
	emit_signal("value_changed", curve)


func _on_right_slope_value_changed(value: Variant) -> void:
	if point_index != curve.points.size() - 1:
		var rad = deg_to_rad(clamp(value, %RightSlope.min_value, %RightSlope.max_value))
		curve.points[point_index].rs = snappedf(tan(rad), 1e-2)
	update_controls()
	queue_redraw()
	emit_signal("value_changed", curve)
