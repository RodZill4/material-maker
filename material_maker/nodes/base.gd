extends GraphNode
class_name MMGraphNodeBase

var generator : MMGenBase = null setget set_generator
var show_inputs : bool = false
var show_outputs : bool = false

var rendering_time : int = -1

const MINIMIZE_ICON : Texture = preload("res://material_maker/icons/minimize.tres")
const RANDOMNESS_ICON : Texture = preload("res://material_maker/icons/randomness_unlocked.tres")
const RANDOMNESS_LOCKED_ICON : Texture = preload("res://material_maker/icons/randomness_locked.tres")
const CUSTOM_ICON : Texture = preload("res://material_maker/icons/custom.png")
const PREVIEW_ICON : Texture = preload("res://material_maker/icons/preview.png")
const PREVIEW_LOCKED_ICON : Texture = preload("res://material_maker/icons/preview_locked.png")

static func wrap_string(s : String, l : int = 50) -> String:
	var length = s.length()
	var p = 0
	while p + l < length:
		var next_cr = s.find("\n", p)
		var next_sp = s.find(" ", p+l)
		if next_cr >= 0 and next_cr < next_sp:
			p = next_cr+1
		elif next_sp >= 0:
			s[next_sp] = "\n"
			p = next_sp+1
		else:
			break
	return s

func _ready() -> void:
	add_to_group("generator_node")
	connect("offset_changed", self, "_on_offset_changed")
	connect("gui_input", self, "_on_gui_input")

func _exit_tree() -> void:
	get_parent().call_deferred("check_last_selected")


func on_generator_changed(g):
	if generator == g:
		update()


func _draw() -> void:
	var color : Color = get_color("title_color")
	var icon = MINIMIZE_ICON
	draw_texture_rect(icon, Rect2(rect_size.x-40, 4, 16, 16), false, color)
	if generator != null and generator.has_randomness():
		icon = RANDOMNESS_LOCKED_ICON if generator.is_seed_locked() else RANDOMNESS_ICON
		draw_texture_rect(icon, Rect2(rect_size.x-56, 4, 16, 16), false)
	var inputs = generator.get_input_defs()
	var font : Font = get_font("default_font")
	var scale = get_global_transform().get_scale()
	if generator != null and generator.model == null and (generator is MMGenShader or generator is MMGenGraph):
		draw_texture_rect(CUSTOM_ICON, Rect2(3, 8, 7, 7), false, color)
	for i in range(inputs.size()):
		if inputs[i].has("group_size") and inputs[i].group_size > 1:
			var conn_pos1 = get_connection_input_position(i)
# warning-ignore:narrowing_conversion
			var conn_pos2 = get_connection_input_position(min(i+inputs[i].group_size-1, inputs.size()-1))
			conn_pos1 /= scale
			conn_pos2 /= scale
			draw_line(conn_pos1, conn_pos2, color)
		if show_inputs:
			var string : String = TranslationServer.translate(inputs[i].shortdesc) if inputs[i].has("shortdesc") else TranslationServer.translate(inputs[i].name)
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_connection_input_position(i)/scale-Vector2(string_size.x+12, -string_size.y*0.3), string, color)
	var outputs = generator.get_output_defs()
	var preview_port : Array = [ -1, -1 ]
	var preview_locked : Array = [ false, false ]
	for i in range(2):
		if get_parent().locked_preview[i] != null and get_parent().locked_preview[i].generator == generator:
			preview_port[i] = get_parent().locked_preview[i].output_index
			preview_locked[i] = true
		elif get_parent().current_preview[i] != null and get_parent().current_preview[i].generator == generator:
			preview_port[i] = get_parent().current_preview[i].output_index
	if preview_port[0] == preview_port[1]:
		preview_port[1] = -1
		preview_locked[0] = preview_locked[0] || preview_locked[1]
	for i in range(outputs.size()):
		if outputs[i].has("group_size") and outputs[i].group_size > 1:
# warning-ignore:narrowing_conversion
			var conn_pos1 = get_connection_output_position(i)
			var conn_pos2 = get_connection_output_position(min(i+outputs[i].group_size-1, outputs.size()-1))
			conn_pos1 /= scale
			conn_pos2 /= scale
			draw_line(conn_pos1, conn_pos2, color)
		var j = -1
		if i == preview_port[0]:
			j = 0
		elif i == preview_port[1]:
			j = 1
		if j != -1:
			var conn_pos = get_connection_output_position(i)
			conn_pos /= scale
			draw_texture_rect(PREVIEW_LOCKED_ICON if preview_locked[j] else PREVIEW_ICON, Rect2(conn_pos.x-14, conn_pos.y-4, 7, 7), false, color)
		if show_outputs:
			var string : String = TranslationServer.translate(outputs[i].shortdesc) if outputs[i].has("shortdesc") else (tr("Output")+" "+str(i))
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_connection_output_position(i)/scale+Vector2(12, string_size.y*0.3), string, color)

func update_node() -> void:
	pass

func set_generator(g) -> void:
	generator = g
	g.connect("rendering_time", self, "update_rendering_time")

func update_rendering_time(t : int) -> void:
	rendering_time = t

func reroll_generator_seed() -> void:
	generator.reroll_seed()

func _on_seed_menu(id):
	match id:
		0:
			generator.toggle_lock_seed()
			update()
			get_parent().send_changed_signal()
		1:
			OS.clipboard = "seed=%.9f" % generator.seed_value
		2:
			if OS.clipboard.left(5) == "seed=":
				generator.set_seed(OS.clipboard.right(5).to_float())

func _on_offset_changed() -> void:
	generator.set_position(offset)
	# This is the old behavior
	#reroll_generator_seed()

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Rect2(rect_size.x-40, 4, 16, 16).has_point(event.position):
			if event.button_index == BUTTON_LEFT:
				generator.minimized = !generator.minimized
				update_node()
				accept_event();
		elif Rect2(rect_size.x-56, 4, 16, 16).has_point(event.position):
			match event.button_index:
				BUTTON_LEFT:
					reroll_generator_seed()
				BUTTON_RIGHT:
					var menu : PopupMenu = PopupMenu.new()
					menu.add_item(tr("Unlock seed") if generator.is_seed_locked() else tr("Lock seed"), 0)
					menu.add_separator()
					menu.add_item(tr("Copy seed"), 1)
					if ! generator.is_seed_locked() and OS.clipboard.left(5) == "seed=":
						menu.add_item(tr("Paste seed"), 2)
					add_child(menu)
					menu.popup(Rect2(get_global_mouse_position(), menu.get_minimum_size()))
					menu.connect("popup_hide", menu, "queue_free")
					menu.connect("id_pressed", self, "_on_seed_menu")
					accept_event()
	elif event is InputEventMouseMotion:
		var epos = event.position
		if Rect2(0, 0, rect_size.x-56, 16).has_point(epos):
			var description = generator.get_description()
			if description != "":
				hint_tooltip = wrap_string(description)
			elif generator.model != null:
				hint_tooltip = TranslationServer.translate(generator.model)
			return
		elif Rect2(rect_size.x-56, 4, 16, 16).has_point(epos) and generator.has_randomness():
			hint_tooltip = tr("Change seed (left mouse button) / Show seed menu (right mouse button)")
			return
		hint_tooltip = ""

func get_output_slot(pos : Vector2) -> int:
	var scale = get_global_transform().get_scale()
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
					return i
	return -1

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
						return wrap_string(TranslationServer.translate(input_def.longdesc))
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
						return wrap_string(TranslationServer.translate(output_def.longdesc))
	return ""

func clear_connection_labels() -> void:
	if show_inputs or show_outputs:
		show_inputs = false
		show_outputs = false
		update()
