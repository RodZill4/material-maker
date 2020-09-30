extends GraphNode
class_name MMGraphNodeBase

var generator : MMGenBase = null setget set_generator
var show_inputs : bool = false
var show_outputs : bool = false

var rendering_time : int = -1

func _ready() -> void:
	connect("offset_changed", self, "_on_offset_changed")
	connect("gui_input", self, "_on_gui_input")

func _exit_tree() -> void:
	get_parent().call_deferred("check_last_selected")

func _draw() -> void:
	if generator != null and generator.has_randomness():
		var icon = preload("res://material_maker/icons/randomness_locked.tres") if generator.is_seed_locked() else preload("res://material_maker/icons/randomness_unlocked.tres")
		draw_texture_rect(icon, Rect2(rect_size.x-48, 4, 16, 16), false)
	var color : Color = get_color("title_color")
	var inputs = generator.get_input_defs()
	var font : Font = get_font("default_font")
	var scale = get_global_transform().get_scale()
	for i in range(inputs.size()):
		if inputs[i].has("group_size") and inputs[i].group_size > 1:
			var conn_pos1 = get_connection_input_position(i)
			var conn_pos2 = get_connection_input_position(min(i+inputs[i].group_size-1, inputs.size()-1))
			conn_pos1 /= scale
			conn_pos2 /= scale
			draw_line(conn_pos1, conn_pos2, color)
		if show_inputs:
			var string : String = inputs[i].shortdesc if inputs[i].has("shortdesc") else inputs[i].name
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_connection_input_position(i)/scale-Vector2(string_size.x+12, -string_size.y*0.3), string, color)
	var outputs = generator.get_output_defs()
	for i in range(outputs.size()):
		if outputs[i].has("group_size") and outputs[i].group_size > 1:
			var conn_pos1 = get_connection_output_position(i)
			var conn_pos2 = get_connection_output_position(min(i+outputs[i].group_size-1, outputs.size()-1))
			conn_pos1 /= scale
			conn_pos2 /= scale
			draw_line(conn_pos1, conn_pos2, color)
		if show_outputs:
			var string : String = outputs[i].shortdesc if outputs[i].has("shortdesc") else ("Output "+str(i))
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_connection_output_position(i)/scale+Vector2(12, string_size.y*0.3), string, color)

func set_generator(g) -> void:
	generator = g
	g.connect("rendering_time", self, "update_rendering_time")

func update_rendering_time(t : int) -> void:
	rendering_time = t

func _on_offset_changed() -> void:
	generator.set_position(offset)

func _input(event) -> void:
	_on_gui_input(event)

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT and Rect2(rect_size.x-48, 4, 16, 16).has_point(event.position):
		generator.toggle_lock_seed()
		update()
		get_parent().send_changed_signal()
	elif event is InputEventMouseMotion:
		var epos = event.position
		if Rect2(0, 0, rect_size.x-48, 16).has_point(epos):
			var description = generator.get_description()
			if description != "":
				hint_tooltip = description
			elif generator.model != null:
				hint_tooltip = generator.model
			return
		elif Rect2(rect_size.x-48, 4, 16, 16).has_point(epos) and generator.has_randomness():
			if generator.is_seed_locked():
				hint_tooltip = "Unlock the random seed, so it can be modified by moving the node"
			else:
				hint_tooltip = "Lock the random seed to its current value"
			return
		hint_tooltip = ""

func get_slot_tooltip(pos : Vector2) -> String:
	var scale = get_global_transform().get_scale()
	if get_connection_input_count() > 0:
		var input_1 : Vector2 = get_connection_input_position(0)-5*scale
		var input_2 : Vector2 = get_connection_input_position(get_connection_input_count()-1)+5*scale
		var new_show_inputs : bool = Rect2(input_1, input_2-input_1).has_point(pos)
		if new_show_inputs != show_inputs:
			show_inputs = new_show_inputs
			update()
		if new_show_inputs:
			for i in range(get_connection_input_count()):
				if (get_connection_input_position(i)-pos).length() < 5*scale.x:
					var input_def = generator.get_input_defs()[i]
					if input_def.has("longdesc"):
						return input_def.longdesc
			return ""
	if get_connection_output_count() > 0:
		var output_1 : Vector2 = get_connection_output_position(0)-5*scale
		var output_2 : Vector2 = get_connection_output_position(get_connection_output_count()-1)+5*scale
		var new_show_outputs : bool = Rect2(output_1, output_2-output_1).has_point(pos)
		if new_show_outputs != show_outputs:
			show_outputs = new_show_outputs
			update()
		if new_show_outputs:
			for i in range(get_connection_output_count()):
				if (get_connection_output_position(i)-pos).length() < 5*scale.x:
					var output_def = generator.get_output_defs()[i]
					if output_def.has("longdesc"):
						return output_def.longdesc
	return ""

func clear_connection_labels() -> void:
	if show_inputs or show_outputs:
		show_inputs = false
		show_outputs = false
		update()
