extends "res://material_maker/widgets/polygon_edit/polygon_view.gd"

signal value_changed(value)

func _ready():
	update_controls()

func set_polygon(p : MMPolygon) -> void:
	polygon = p
	update()
	update_controls()

func update_controls() -> void:
	for c in get_children():
		c.queue_free()
	for i in polygon.points.size():
		var p = polygon.points[i]
		var control_point = preload("res://material_maker/widgets/polygon_edit/control_point.tscn").instance()
		add_child(control_point)
		control_point.initialize(p)
		control_point.rect_position = transform_point(p)-control_point.OFFSET
		control_point.connect("moved", self, "_on_ControlPoint_moved")
		control_point.connect("removed", self, "_on_ControlPoint_removed")
	emit_signal("value_changed", polygon)

func _on_ControlPoint_moved(index):
	var control_point = get_child(index)
	polygon.points[index] = reverse_transform_point(control_point.rect_position+control_point.OFFSET)
	update()
	emit_signal("value_changed", polygon)

func _on_ControlPoint_removed(index):
	if polygon.remove_point(index):
		update()
		update_controls()

func _on_PolygonEditor_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.doubleclick:
			var new_point_position = reverse_transform_point(get_local_mouse_position())
			polygon.add_point(new_point_position.x, new_point_position.y)
			update_controls()

func _on_resize() -> void:
	._on_resize()
	update_controls()
