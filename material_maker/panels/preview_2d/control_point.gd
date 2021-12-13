extends TextureRect

export var parent_control : String = ""
export(int, "Simple", "Rect", "Radius", "Scale" ) var control_type : int = 0

var generator : MMGenBase = null
var parameter_x : String = ""
var parameter_y : String = ""
var parameter_r : String = ""
var parameter_a : String = ""
var is_xy : bool = false

var dragging : bool = false

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
			var ppos
			if parent_control_node == null:
				ppos = get_parent().value_to_pos(Vector2(0, 0))
			else:
				ppos = parent_control_node.rect_position+0.5*parent_control_node.rect_size
			draw_line(0.5*rect_size, ppos-rect_position, modulate)
		3: # Scale
			var ppos
			if parent_control_node == null:
				ppos = get_parent().value_to_pos(Vector2(0, 0))
			else:
				ppos = parent_control_node.rect_position+0.5*parent_control_node.rect_size
			draw_rect(Rect2(0.5*rect_size, ppos-(rect_position+0.5*rect_size)), modulate, false)

func setup_control(g : MMGenBase, param_defs : Array) -> void:
	hide()
	if is_instance_valid(generator) and generator.is_connected("parameter_changed", self, "on_parameter_changed"):
		generator.disconnect("parameter_changed", self, "on_parameter_changed")
	generator = g
	parameter_x = ""
	parameter_y = ""
	parameter_r = ""
	parameter_a = ""
	for p in param_defs:
		if p.has("control"):
			if p.control == name+".x":
				show()
				parameter_x = p.name
			elif p.control == name+".y":
				show()
				parameter_y = p.name
			elif p.control == name+".r":
				show()
				parameter_r = p.name
			elif p.control == name+".a":
				show()
				parameter_a = p.name
	is_xy = parameter_x != "" or parameter_y != ""
	if visible:
		generator.connect("parameter_changed", self, "on_parameter_changed")
		update_position(get_value())
	else:
		generator = null
		update_position(Vector2(0, 0))

func get_value() -> Vector2:
	var pos : Vector2 = Vector2(0, 0)
	if is_instance_valid(generator):
		if is_xy:
			if parameter_x != "":
				var p = generator.get_parameter(parameter_x)
				if p is float:
					pos.x = p
			if parameter_y != "":
				var p = generator.get_parameter(parameter_y)
				if p is float:
					pos.y = p
		else:
			var r = 0.25
			var a = 0
			if parameter_r != "":
				var p = generator.get_parameter(parameter_r)
				if p is float:
					r = p
			if parameter_a != "":
				var p = generator.get_parameter(parameter_a)
				if p is float:
					a = p*0.01745329251
			pos.x = r*cos(a)
			pos.y = r*sin(a)
	return pos

func get_parent_value() -> Vector2:
	var parent_value = Vector2(0, 0)
	var p = parent_control_node
	while p != null:
		parent_value += p.get_value()
		p = p.parent_control_node
	return parent_value

func on_parameter_changed(p, v) -> void:
	if !dragging and (p == parameter_x or p == parameter_y or p == parameter_r or p == parameter_a):
		if v is float:
			visible = true
			update_position(get_value())
			update()
		else:
			visible = false

func update_parameters(value : Vector2) -> void:
	if !is_instance_valid(generator):
		return
	match control_type:
		1: # Rect
			value.x = abs(value.x)
			value.y = abs(value.y)
		3: # Scale
			value = 4.0*value
	if parameter_x != "":
		generator.set_parameter(parameter_x, value.x)
	if parameter_y != "":
		generator.set_parameter(parameter_y, value.y)
	if parameter_r != "":
		generator.set_parameter(parameter_r, value.length())
	if parameter_a != "":
		generator.set_parameter(parameter_a, atan2(value.y, value.x)*57.2957795131)

func update_position(pos : Vector2) -> void:
	match control_type:
		3: # Scale
			pos *= 0.25
	if parent_control_node != null:
		pos += parent_control_node.get_value()
	rect_position = get_parent().value_to_pos(pos)-0.5*rect_size
	for c in children_control_nodes:
		c.update_position(c.get_value())
	update()

func _on_Point_gui_input(event : InputEvent):
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_LEFT:
		var parent_value = get_parent_value()
		var value = get_parent().pos_to_value(rect_position+event.position)-parent_value
		if event.control:
			var snap : float = 0.0
			var grid = get_parent().get_node("Axes")
			if grid != null and grid.visible:
				snap = grid.snap
			if is_xy:
				if snap > 0.0:
					value.x = round(value.x*snap)/snap
					value.y = round(value.y*snap)/snap
			elif parameter_a != "":
				var l = value.length()
				var a = value.angle()
				snap = PI/12.0
				a = round(a/snap)*snap
				value = l*Vector2(cos(a), sin(a))
		if event.shift:
			if control_type == 3:
				value.x = max(value.x, value.y)
				value.y = value.x
		if is_xy:
			if parameter_x == "":
				value.x = 0
			if parameter_y == "":
				value.y = 0
		else:
			if parameter_r == "":
				value = 0.25*value/value.length()
			if parameter_a == "":
				value = Vector2(value.length(), 0.0)
		rect_position = get_parent().value_to_pos(value+parent_value)-0.5*rect_size
		dragging = true
		update_parameters(value)
		update()
		dragging = false
		for c in children_control_nodes:
			c.update_position(c.get_value())
