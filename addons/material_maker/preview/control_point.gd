extends TextureRect

export var parent_control : String = ""
export(int, "Simple", "Rect", "Radius", "Scale", "ScaleXY" ) var control_type : int = 0

var generator : MMGenBase = null
var parameter_x : String = ""
var parameter_y : String = ""
var dragging = false

var parent_control_node = null
var children_control_nodes = []

func _ready() -> void:
	if parent_control != "":
		parent_control_node = get_parent().get_node(parent_control)
		if parent_control_node != null:
			parent_control_node.children_control_nodes.push_back(self)

func _draw() -> void:
	match control_type:
		1: # Rect
			var ppos = parent_control_node.rect_position+0.5*parent_control_node.rect_size
			draw_rect(Rect2(0.5*rect_size, 2.0*(ppos-(rect_position+0.5*rect_size))), modulate, false)
		2: # Radius
			draw_line(0.5*rect_size, 0.5*rect_size-get_parent().value_to_offset(get_value()), modulate)
		3: # Scale
			draw_line(0.5*rect_size, 0.5*rect_size-get_parent().value_to_offset(0.25*get_value()), modulate)
		4: # ScaleXY
			var ppos = parent_control_node.rect_position+0.5*parent_control_node.rect_size
			draw_rect(Rect2(0.5*rect_size, ppos-(rect_position+0.5*rect_size)), modulate, false)

func setup_control(g : MMGenBase, param_defs : Array) -> void:
	hide()
	if is_instance_valid(generator):
		generator.disconnect("parameter_changed", self, "on_parameter_changed")
	generator = g
	parameter_x = ""
	parameter_y = ""
	for p in param_defs:
		if p.has("control"):
			if p.control == name+".x":
				show()
				parameter_x = p.name
			elif p.control == name+".y":
				show()
				parameter_y = p.name
	if visible:
		generator.connect("parameter_changed", self, "on_parameter_changed")
		update_position(get_value())
	else:
		generator = null
		update_position(Vector2(0, 0))

func get_value() -> Vector2:
	var pos : Vector2 = Vector2(0, 0)
	if is_instance_valid(generator):
		if parameter_x != "":
			pos.x = generator.get_parameter(parameter_x)
		if parameter_y != "":
			pos.y = generator.get_parameter(parameter_y)
	return pos

func on_parameter_changed(p, v) -> void:
	if !dragging and (p == parameter_x or p == parameter_y):
		update_position(get_value())
		update()

func update_parameters(pos : Vector2) -> void:
	if !is_instance_valid(generator):
		return
	if parent_control_node != null:
		pos -= parent_control_node.get_value()
	match control_type:
		1: # Rect
			pos.x = abs(pos.x)
			pos.y = abs(pos.y)
		3: # Scale
			pos.x = 4.0*pos.x
	if parameter_x != "":
		generator.set_parameter(parameter_x, pos.x)
	if parameter_y != "":
		generator.set_parameter(parameter_y, pos.y)

func update_position(pos : Vector2) -> void:
	match control_type:
		3: # Scale
			pos *= 0.25
	if parent_control_node != null:
		pos += parent_control_node.get_value()
	rect_position = get_parent().value_to_pos(pos+Vector2(0.5, 0.5))-0.5*rect_size
	for c in children_control_nodes:
		c.update_position(c.get_value())
	update()

func _on_Point_gui_input(event : InputEvent):
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_LEFT:
		rect_position += event.relative
		match control_type:
			2: # Radius
				rect_position.x = max(rect_position.x, parent_control_node.rect_position.x+0.5*(parent_control_node.rect_size.x-rect_size.x))
				rect_position.y = parent_control_node.rect_position.y+0.5*(parent_control_node.rect_size.y-rect_size.y)
			3: # Scale
				rect_position.x = max(rect_position.x, parent_control_node.rect_position.x+0.5*(parent_control_node.rect_size.x-rect_size.x))
				rect_position.y = parent_control_node.rect_position.y+0.5*(parent_control_node.rect_size.y-rect_size.y)
		var pos = get_parent().pos_to_value(rect_position+0.5*rect_size)-Vector2(0.5, 0.5)
		dragging = true
		update_parameters(pos)
		update()
		dragging = false
		for c in children_control_nodes:
			c.update_position(c.get_value())
