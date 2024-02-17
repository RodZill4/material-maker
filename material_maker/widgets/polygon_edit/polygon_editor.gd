extends "res://material_maker/widgets/polygon_edit/polygon_view.gd"


signal value_changed(value : MMPolygon)
signal unhandled_event(event : InputEvent)


func _ready():
	super._ready()
	update_controls()

func set_polygon(p : MMPolygon) -> void:
	polygon = p
	queue_redraw()
	update_controls()

func update_controls() -> void:
	for c in get_children():
		c.queue_free()
	for i in polygon.points.size():
		var p = polygon.points[i]
		var control_point = preload("res://material_maker/widgets/polygon_edit/control_point.tscn").instantiate()
		add_child(control_point)
		control_point.initialize(p)
		control_point.position = transform_point(p)-control_point.OFFSET
		control_point.connect("moved", Callable(self, "_on_ControlPoint_moved"))
		control_point.connect("removed", Callable(self, "_on_ControlPoint_removed"))
	emit_signal("value_changed", polygon)

func is_editing() -> bool:
	for c in get_children():
		if c.moving:
			return true
	return false

func _on_ControlPoint_moved(index):
	var control_point = get_child(index)
	polygon.points[index] = reverse_transform_point(control_point.position+control_point.OFFSET)
	queue_redraw()
	emit_signal("value_changed", polygon)

func _on_ControlPoint_removed(index):
	if polygon.remove_point(index):
		queue_redraw()
		update_controls()

func _on_PolygonEditor_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			var new_point_position = reverse_transform_point(get_local_mouse_position())
			polygon.add_point(new_point_position.x, new_point_position.y, closed)
			update_controls()
			return
	unhandled_event.emit(event)

func _on_resize() -> void:
	super._on_resize()
	update_controls()


var generator : MMGenBase = null
var parameter_name : String

func setup_control(g : MMGenBase, param_defs : Array) -> void:
	var need_hide : bool = true
	for p in param_defs:
		if p.type == "polygon" or p.type == "polyline":
			if g != generator or p.name != parameter_name:
				show()
				generator = g
				parameter_name = p.name
				value_changed.connect(self.control_update_parameter)
				set_closed(p.type == "polygon")
			if not is_editing():
				set_polygon(MMType.deserialize_value(g.get_parameter(p.name)))
			need_hide = false
			break
	if need_hide:
		hide()
		if value_changed.is_connected(self.control_update_parameter):
			value_changed.disconnect(self.control_update_parameter)
		generator = null

func control_update_parameter(value : MMPolygon):
	generator.set_parameter(parameter_name, polygon.serialize())
