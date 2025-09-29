extends TextureRect

@export var parent_control : String = ""
@export var control_type : int = 0 # (int, "Simple", "Rect", "Radius", "Scale", "RotateScale" )
@export var apply_local_transform : bool = false

var generator : MMGenBase = null
var parameter_x : String = ""
var parameter_y : String = ""
var parameter_r : String = ""
var parameter_a : String = ""
var is_xy : bool = false

var init_pos : Vector2

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
			var p0 = get_center_position()
			var val = get_value()
			var ppos = parent_control_node.get_center_position()
			var p1 = ppos+get_parent().value_to_pos(val*Vector2(-1, 1), true, apply_local_transform)-get_parent().value_to_pos(Vector2(0, 0), true, apply_local_transform)
			var p2 = 2.0*ppos-p0
			var p3 = 2.0*ppos-p1
			draw_line(0.5*size, p1-p0+0.5*size, modulate)
			draw_line(p1-p0+0.5*size, p2-p0+0.5*size, modulate)
			draw_line(p2-p0+0.5*size, p3-p0+0.5*size, modulate)
			draw_line(p3-p0+0.5*size, 0.5*size, modulate)
		2, 4: # Radius
			var ppos
			if parent_control_node == null:
				ppos = get_parent().value_to_pos(Vector2(0, 0))
			else:
				ppos = parent_control_node.position+0.5*parent_control_node.size
			draw_line(0.5*size, ppos-position, modulate)
		3: # Scale
			var ppos
			if parent_control_node == null:
				ppos = get_parent().value_to_pos(Vector2(0, 0))
			else:
				ppos = parent_control_node.position+0.5*parent_control_node.size
			draw_rect(Rect2(0.5*size, ppos-(position+0.5*size)), modulate, false)

func setup_control(g : MMGenBase, param_defs : Array) -> void:
	if dragging:
		return
	hide()
	if is_instance_valid(generator) and generator.parameter_changed.is_connected(self.on_parameter_changed):
		generator.parameter_changed.disconnect(self.on_parameter_changed)
	generator = g
	parameter_x = ""
	parameter_y = ""
	parameter_r = ""
	parameter_a = ""
	for p in param_defs:
		if p.has("control"):
			if p.control == String(name)+".x":
				show()
				parameter_x = p.name
			elif p.control == String(name)+".y":
				show()
				parameter_y = p.name
			elif p.control == String(name)+".r":
				show()
				parameter_r = p.name
			elif p.control == String(name)+".a":
				show()
				parameter_a = p.name
	is_xy = parameter_x != "" or parameter_y != ""
	if visible:
		generator.parameter_changed.connect(self.on_parameter_changed)
		update_position(get_value())
	else:
		generator = null
		update_position(Vector2(0, 0))

func get_center_position() -> Vector2:
	return position+0.5*size

func get_value() -> Vector2:
	var pos : Vector2 = Vector2(0, 0)
	if is_instance_valid(generator):
		if is_xy:
			if parameter_x != "":
				var p = generator.get_parameter(parameter_x)
				if p is float:
					pos.x = p
				else:
					visible = false
			if parameter_y != "":
				var p = generator.get_parameter(parameter_y)
				if p is float:
					pos.y = p
				else:
					visible = false
		else:
			var r = 0.25
			var a = 0
			if parameter_r != "":
				var p = generator.get_parameter(parameter_r)
				if p is float:
					r = p
				else:
					visible = false
			if parameter_a != "":
				var p = generator.get_parameter(parameter_a)
				if p is float:
					a = p*0.01745329251
				else:
					visible = false
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
			queue_redraw()
		else:
			visible = false

func update_parameters(value : Vector2) -> void:
	if !is_instance_valid(generator):
		return
	match control_type:
		1: # Rect
			value.x = abs(value.x)
			value.y = abs(value.y)
	var parameters : Dictionary = {}
	if parameter_x != "":
		parameters[parameter_x] = value.x
	if parameter_y != "":
		parameters[parameter_y] = value.y
	if parameter_r != "":
		parameters[parameter_r] = value.length()
	if parameter_a != "":
		parameters[parameter_a] = atan2(value.y, value.x)*57.2957795131
	if ! parameters.is_empty():
		var control_target = null
		if get_parent().has_node(get_parent().control_target):
			control_target = get_parent().get_node(get_parent().control_target)
		if control_target == null:
			var main_window = mm_globals.main_window
			control_target = main_window.get_current_graph_edit()
		control_target.set_node_parameters(generator, parameters)

func update_position(value : Vector2) -> void:
	match control_type:
		3, 4: # Scale
			value *= 0.25
	position = get_parent().value_to_pos(value, true, apply_local_transform)
	if parent_control_node != null:
		position -= get_parent().value_to_pos(Vector2(0, 0), true, apply_local_transform)
		position += parent_control_node.get_center_position()
	position -= 0.5*size
	for c in children_control_nodes:
		c.update_position(c.get_value())
	queue_redraw()

func _on_Point_gui_input(event : InputEvent):
	var axes = get_parent().get_node("Axes")
	axes.hide()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		init_pos = position + event.position
	elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		var new_pos = position + event.position
		var value = get_parent().pos_to_value(new_pos, true, apply_local_transform)
		var init_value = get_parent().pos_to_value(init_pos, true, apply_local_transform)
		if parent_control_node != null:
			value -= get_parent().pos_to_value(parent_control_node.get_center_position(), true, apply_local_transform)
			init_value -= get_parent().pos_to_value(parent_control_node.get_center_position(), true, apply_local_transform)

		if event.shift_pressed:
			# Don't snap axes for rect, scale and angle gizmos
			if not (control_type > 0 and control_type <= 4) and parameter_a == "":
				if abs(value.x - init_value.x) > abs(value.y - init_value.y):
					value.y = init_value.y
				else:
					value.x = init_value.x
				if axes:
					axes.show()
					axes.point = init_pos

		if event.is_command_or_control_pressed():
			var snap : float = 0.0
			var grid = get_parent().get_node("Guides")
			if grid != null and grid.visible:
				snap = grid.grid_size
			if is_xy:
				if snap > 0.0:
					value.x = round((value.x-0.5)*snap)/snap+0.5
					value.y = round((value.y-0.5)*snap)/snap+0.5

					# Snap axes to grid
					init_value = round((init_value-Vector2(0.5,0.5))*snap)/snap+Vector2(0.5,0.5)
					axes.point = get_parent().value_to_pos(init_value)
			elif parameter_a != "":
				var l = value.length()
				var a = value.angle()
				snap = PI/12.0
				a = round(a/snap)*snap
				value = l*Vector2(cos(a), sin(a))
		if event.shift_pressed:
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
				value = value/value.length()
				if control_type == 2:
					value *= 0.25
			if parameter_a == "":
				value = Vector2(value.length(), 0.0)
		match control_type:
			3, 4: # Scale
				value *= 4.0
		dragging = true
		update_parameters(value)
		update_position(value)
		dragging = false
		for c in children_control_nodes:
			c.update_position(c.get_value())
