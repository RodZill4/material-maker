extends MMGraphNodeMinimal
class_name MMGraphNodeBase


class NodeButton:
	var hidden : bool = false
	var texture : Texture2D
	var modulate_texture : bool = false

	func _init(t : Texture2D, m : bool = false):
		hidden = false
		texture = t
		modulate_texture = m


var show_inputs : bool = false
var show_outputs : bool = false

var buttons : Array = []
var minimize_button : NodeButton
var randomness_button : NodeButton
var buffer_button : NodeButton

var rendering_time : int = -1


const MINIMIZE_ICON : Texture2D = preload("res://material_maker/icons/minimize.tres")
const RANDOMNESS_ICON : Texture2D = preload("res://material_maker/icons/randomness_unlocked.tres")
const RANDOMNESS_LOCKED_ICON : Texture2D = preload("res://material_maker/icons/randomness_locked.tres")
const BUFFER_ICON : Texture2D = preload("res://material_maker/icons/buffer.tres")
const BUFFER_PAUSED_ICON : Texture2D = preload("res://material_maker/icons/buffer_paused.tres")
const CUSTOM_ICON : Texture2D = preload("res://material_maker/icons/custom.png")
const PREVIEW_ICON : Texture2D = preload("res://material_maker/icons/preview.png")
const PREVIEW_LOCKED_ICON : Texture2D = preload("res://material_maker/icons/preview_locked.png")

const MENU_PROPAGATE_CHANGES : int = 1000
const MENU_SHARE_NODE : int        = 1001

const MENU_BUFFER_PAUSE : int  = 0
const MENU_BUFFER_RESUME : int = 1
const MENU_BUFFER_DUMP : int   = 2

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

func _init():
	minimize_button = add_button(MINIMIZE_ICON, true)
	randomness_button = add_button(RANDOMNESS_ICON)
	randomness_button.hidden = true
	buffer_button = add_button(BUFFER_ICON)
	buffer_button.hidden = true

func _ready() -> void:
	super._ready()
	gui_input.connect(self._on_gui_input)
	update.call_deferred()

func add_button(texture : Texture2D, modulate_texture : bool = false) -> NodeButton:
	var button : NodeButton = NodeButton.new(texture, modulate_texture)
	buttons.push_back(button)
	return button

func on_generator_changed(g):
	if generator == g:
		update()

func update():
	if generator != null and generator.has_randomness():
		randomness_button.hidden = false
		randomness_button.texture = RANDOMNESS_LOCKED_ICON if generator.is_seed_locked() else RANDOMNESS_ICON
	else:
		randomness_button.hidden = true
	buffer_button.hidden = generator.get_buffers().is_empty()
	if ! buffer_button.hidden:
		buffer_button.texture = BUFFER_ICON if generator.get_buffers(MMGenBase.BUFFERS_PAUSED).is_empty() else BUFFER_PAUSED_ICON
	queue_redraw()

func _draw() -> void:
	var color : Color = get_theme_color("title_color")
	# warning-ignore:narrowing_conversion
	var button_x : int = size.x-40
	for b in buttons:
		if b.hidden:
			continue
		draw_texture_rect(b.texture, Rect2(button_x, 4, 16, 16), false, color if b.modulate_texture else Color(1, 1, 1, 1))
		button_x -= 16
	var inputs = generator.get_input_defs()
	var font : Font = get_theme_font("default_font")
	var global_scale = get_global_transform().get_scale()
	if generator != null and generator.model == null and (generator is MMGenShader or generator is MMGenGraph):
		draw_texture_rect(CUSTOM_ICON, Rect2(3, 8, 7, 7), false, color)
	for i in range(inputs.size()):
		if inputs[i].has("group_size") and inputs[i].group_size > 1:
			var conn_pos1 = get_connection_input_position(i)
			# warning-ignore:narrowing_conversion
			var conn_pos2 = get_connection_input_position(min(i+inputs[i].group_size-1, inputs.size()-1))
			conn_pos1 /= global_scale
			conn_pos2 /= global_scale
			draw_line(conn_pos1, conn_pos2, color)
		if show_inputs:
			var string : String = TranslationServer.translate(inputs[i].shortdesc) if inputs[i].has("shortdesc") else TranslationServer.translate(inputs[i].name)
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_connection_input_position(i)/global_scale-Vector2(string_size.x+12, -string_size.y*0.3), string, 0, -1, 16, color)
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
			conn_pos1 /= global_scale
			conn_pos2 /= global_scale
			draw_line(conn_pos1, conn_pos2, color)
		var j = -1
		if i == preview_port[0]:
			j = 0
		elif i == preview_port[1]:
			j = 1
		if j != -1:
			var conn_pos = get_connection_output_position(i)
			conn_pos /= global_scale
			draw_texture_rect(PREVIEW_LOCKED_ICON if preview_locked[j] else PREVIEW_ICON, Rect2(conn_pos.x-14, conn_pos.y-4, 7, 7), false, color)
		if show_outputs:
			var string : StringName = TranslationServer.translate(outputs[i].shortdesc) if outputs[i].has("shortdesc") else StringName(tr("Output")+" "+str(i))
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_connection_output_position(i)/global_scale+Vector2(12, string_size.y*0.3), string, 0, -1, 16, color)
	if (selected):
		draw_style_box(get_theme_stylebox("node_highlight"), Rect2(Vector2.ZERO, size))

func set_generator(g) -> void:
	super.set_generator(g)
	g.connect("rendering_time", Callable(self, "update_rendering_time"))

func update_rendering_time(t : int) -> void:
	rendering_time = t

func set_generator_seed(s : float):
	if generator.is_seed_locked():
		return
	var old_seed : float = generator.get_seed()
	generator.set_seed(s)
	var hier_name = generator.get_hier_name()
	get_parent().undoredo.add("Set seed", [{ type="setseed", node=hier_name, seed=old_seed }], [{ type="setseed", node=hier_name, seed=s }], false)

func reroll_generator_seed() -> void:
	set_generator_seed(randf())

func _on_seed_menu(id):
	match id:
		0:
			var old_seed_locked : bool = generator.is_seed_locked()
			generator.toggle_lock_seed()
			update()
			get_parent().send_changed_signal()
			var hier_name = generator.get_hier_name()
			get_parent().undoredo.add("Lock/unlock seed", [{ type="setseedlocked", node=hier_name, seedlocked=old_seed_locked }], [{ type="setseedlocked", node=hier_name, seedlocked=!old_seed_locked }], false)
		1:
			DisplayServer.clipboard_set("seed=%.9f" % generator.seed_value)
		2:
			if DisplayServer.clipboard_get().left(5) == "seed=":
				set_generator_seed(DisplayServer.clipboard_get().right(-5).to_float())

func _on_buffer_menu(id):
	match id:
		MENU_BUFFER_PAUSE:
			for b in generator.get_buffers(MMGenBase.BUFFERS_RUNNING):
				b.set_paused(true)
			update()
		MENU_BUFFER_RESUME:
			for b in generator.get_buffers(MMGenBase.BUFFERS_PAUSED):
				b.set_paused(false)
			update()
		MENU_BUFFER_DUMP:
			for b in generator.get_buffers():
				mm_deps.print_stats(b)

func on_node_button(b : NodeButton, event : InputEvent) -> bool:
	if b == minimize_button:
		if event.button_index == MOUSE_BUTTON_LEFT:
			generator.minimized = !generator.minimized
			var hier_name = generator.get_hier_name()
			get_parent().undoredo.add("Minimize node", [{ type="setminimized", node=hier_name, minimized=!generator.minimized }], [{ type="setminimized", node=hier_name, minimized=generator.minimized }], false)
			update_node()
			return true
	elif b == randomness_button:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				reroll_generator_seed()
				return true
			MOUSE_BUTTON_RIGHT:
				var menu : PopupMenu = PopupMenu.new()
				menu.add_item(tr("Unlock seed") if generator.is_seed_locked() else tr("Lock seed"), 0)
				menu.add_separator()
				menu.add_item(tr("Copy seed"), 1)
				if ! generator.is_seed_locked() and DisplayServer.clipboard_get().left(5) == "seed=":
					menu.add_item(tr("Paste seed"), 2)
				add_child(menu)
				menu.popup(Rect2(get_global_mouse_position(), menu.get_minimum_size()))
				menu.connect("popup_hide", Callable(menu, "queue_free"))
				menu.connect("id_pressed", Callable(self, "_on_seed_menu"))
				return true
	elif b == buffer_button:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				var menu : PopupMenu = PopupMenu.new()
				menu.add_item(tr("Pause buffers"), MENU_BUFFER_PAUSE)
				menu.set_item_disabled(MENU_BUFFER_PAUSE, generator.get_buffers(MMGenBase.BUFFERS_RUNNING).is_empty())
				menu.add_item(tr("Resume buffers"), MENU_BUFFER_RESUME)
				menu.set_item_disabled(MENU_BUFFER_RESUME, generator.get_buffers(MMGenBase.BUFFERS_PAUSED).is_empty())
				if OS.is_debug_build():
					menu.add_separator()
					menu.add_item(tr("Dump buffers"), MENU_BUFFER_DUMP)
				add_child(menu)
				menu.popup(Rect2(get_global_mouse_position(), Vector2(0, 0)))
				menu.connect("popup_hide",Callable(menu,"queue_free"))
				menu.connect("id_pressed",Callable(self,"_on_buffer_menu"))
				return true
	return false

func update_button_tooltip(b : NodeButton) -> bool:
	if b == minimize_button:
		tooltip_text = tr("Minimize the node")
		return true
	elif b == randomness_button:
		tooltip_text = tr("Change seed (left mouse button) / Show seed menu (right mouse button)")
		return true
	elif b == buffer_button:
		tooltip_text = tr("%d buffer(s), %d paused") % [ generator.get_buffers().size(), generator.get_buffers(MMGenBase.BUFFERS_PAUSED).size() ]
		return true
	return false

var doubleclicked : bool = false

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			# warning-ignore:narrowing_conversion
			var button_x : int = size.x-40
			for b in buttons:
				if b.hidden:
					continue
				if Rect2(button_x, 4, 16, 16).has_point(event.position):
					if on_node_button(b, event):
						accept_event()
						return
				button_x -= 16
			if event.double_click:
				doubleclicked = true
			if event.button_index == MOUSE_BUTTON_RIGHT:
				accept_event()
				var menu = create_context_menu()
				if menu != null:
					if menu.get_item_count() != 0:
						add_child(menu)
						menu.connect("modal_closed",Callable(menu,"queue_free"))
						menu.connect("id_pressed",Callable(self,"_on_menu_id_pressed"))
						menu.popup(Rect2(get_global_mouse_position(), Vector2(0, 0)))
					else:
						menu.free()
		elif doubleclicked:
			doubleclicked = false
			if generator is MMGenGraph:
				get_parent().call_deferred("update_view", generator)
			elif generator is MMGenSDF:
				edit_generator()
	elif event is InputEventMouseMotion:
		var epos : Vector2 = event.position
		# warning-ignore:narrowing_conversion
		var button_x : int = size.x-40
		for b in buttons:
			if b.hidden:
				continue
			if Rect2(button_x, 4, 16, 16).has_point(epos):
				if update_button_tooltip(b):
					accept_event()
					return
			button_x -= 16
		if Rect2(0, 0, size.x-56, 16).has_point(epos):
			var description = generator.get_description()
			if description != "":
				tooltip_text = MMGraphNodeBase.wrap_string(description)
			elif generator.model != null:
				tooltip_text = TranslationServer.translate(generator.model)
			return
		tooltip_text = ""

func get_input_slot(pos : Vector2) -> int:
	var return_value = super.get_input_slot(pos)
	var new_show_inputs : bool = (return_value != -2)
	if new_show_inputs != show_inputs:
		show_inputs = new_show_inputs
		update()
	return return_value

func get_output_slot(pos : Vector2) -> int:
	var return_value = super.get_output_slot(pos)
	var new_show_outputs : bool = (return_value != -2)
	if new_show_outputs != show_outputs:
		show_outputs = new_show_outputs
		update()
	return return_value

func get_slot_from_position(pos : Vector2) -> Dictionary:
	var global_scale = get_global_transform().get_scale()
	if get_connection_input_count() > 0:
		var input_1 : Vector2 = get_connection_input_position(0)-5*global_scale
		var input_2 : Vector2 = get_connection_input_position(get_connection_input_count()-1)+5*global_scale
		var new_show_inputs : bool = Rect2(input_1, input_2-input_1).has_point(pos)
		if new_show_inputs != show_inputs:
			show_inputs = new_show_inputs
			update()
		if new_show_inputs:
			for i in range(get_connection_input_count()):
				if (get_connection_input_position(i)-pos).length() < 5*global_scale.x:
					return { type="input", index=i }
	if get_connection_output_count() > 0:
		var output_1 : Vector2 = get_connection_output_position(0)-5*global_scale
		var output_2 : Vector2 = get_connection_output_position(get_connection_output_count()-1)+5*global_scale
		var new_show_outputs : bool = Rect2(output_1, output_2-output_1).has_point(pos)
		if new_show_outputs != show_outputs:
			show_outputs = new_show_outputs
			update()
		if new_show_outputs:
			for i in range(get_connection_output_count()):
				if (get_connection_output_position(i)-pos).length() < 5*global_scale.x:
					return { type="output", index=i }
	return { type="none", index=-1 }

func get_slot_tooltip(pos : Vector2, io : Dictionary = {}) -> String:
	if io.is_empty():
		io = get_slot_from_position(pos)
	match io.type:
		"input":
			mm_globals.set_tip_text("")
			var input_def = generator.get_input_defs()[io.index]
			if input_def.has("longdesc"):
				return MMGraphNodeBase.wrap_string(TranslationServer.translate(input_def.longdesc))
		"output":
			
			var output_def = generator.get_output_defs()[io.index]
			if output_def.has("longdesc"):
				return MMGraphNodeBase.wrap_string(TranslationServer.translate(output_def.longdesc))
		_:
			mm_globals.set_tip_text("")
	return ""

func set_slot_tip_text(pos : Vector2, io : Dictionary = {}):
	if io.is_empty():
		io = get_slot_from_position(pos)
	match io.type:
		"output":
			if Input.is_key_pressed(KEY_CTRL):
				if Input.is_key_pressed(KEY_SHIFT):
					mm_globals.set_tip_text("#LMB: Lock/Unlock in 2D preview (2), #RMB: Add/Remove reroute node")
				else:
					mm_globals.set_tip_text("#LMB: Lock/Unlock in 2D preview, #RMB: Toggle preview")
			else:
				if Input.is_key_pressed(KEY_SHIFT):
					mm_globals.set_tip_text("#LMB: Show in 2D preview (2), #RMB: Add/Remove reroute node")
				else:
					mm_globals.set_tip_text("#LMB: Show in 2D preview, #RMB: Toggle preview")
			return true
	return false

func clear_connection_labels() -> void:
	if show_inputs or show_outputs:
		show_inputs = false
		show_outputs = false
		update()

func create_context_menu():
	var menu : PopupMenu = PopupMenu.new()
	if generator != null and generator.model == null and (generator is MMGenShader or generator is MMGenGraph):
		var share_button = mm_globals.main_window.get_share_button()
		if share_button.can_share():
			menu.add_item(tr("Share node on website"), MENU_SHARE_NODE)
	if generator is MMGenGraph and !get_parent().get_propagation_targets(generator).is_empty():
		menu.add_item(tr("Propagate changes"), MENU_PROPAGATE_CHANGES)
	return menu

func _on_menu_id_pressed(id : int) -> void:
	match id:
		MENU_PROPAGATE_CHANGES:
			var dialog = load("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instantiate()
			dialog.dialog_text = "Propagate changes from %s to %d nodes?" % [ generator.get_type_name(), get_parent().get_propagation_targets(generator).size() ]
			dialog.add_cancel_button("Cancel");
			add_child(dialog)
			var result = await dialog.ask()
			if result == "ok":
				get_parent().call_deferred("propagate_node_changes", generator)
		MENU_SHARE_NODE:
			# Prepare warning dialog
			var status : Array = []
			if generator.get_description() == "":
				status.append({ ok=false, message="The node does not have a description"})
			else:
				status.append({ ok=true, message="The node has a description" })
			var bad : PackedStringArray
			# Parameters
			bad = PackedStringArray()
			for p in generator.get_parameter_defs():
				if p.has("longdesc") and p.has("shortdesc") and p.longdesc != "" and p.shortdesc != "":
					continue
				bad.append(p.name)
			if bad.is_empty():
				status.append({ ok=true, message="All parameters have a short and a long description" })
			else:
				status.append({ ok=false, message="The following parameters do not have a short and a long description: "+", ".join(bad) })
			# Inputs
			bad = PackedStringArray()
			for i in generator.get_input_defs():
				if i.has("longdesc") and i.has("shortdesc") and i.longdesc != "" and i.shortdesc != "":
					continue
				bad.append(i.name)
			if bad.is_empty():
				status.append({ ok=true, message="All inputs have a short and a long description" })
			else:
				status.append({ ok=false, message="The following inputs do not have a short and a long description: "+", ".join(bad) })
			# Outputs
			bad = PackedStringArray()
			for o in generator.get_output_defs():
				if o.has("longdesc") and o.has("shortdesc") and o.longdesc != "" and o.shortdesc != "":
					continue
				bad.append(o.name)
			if bad.is_empty():
				status.append({ ok=true, message="All outputs have a short and a long description" })
			else:
				status.append({ ok=false, message="The following outputs do not have a short and a long description: "+", ".join(bad) })
			# Show warning dialog
			var dialog = preload("res://material_maker/tools/share/share_node_dialog.tscn").instantiate()
			var result = await dialog.ask(status)
			if result != "ok":
				return
			var node = generator.serialize()
			var share_button = mm_globals.main_window.get_share_button()
			var preview = await generator.render(self, 0, 1024, true)
			var preview_texture : ImageTexture = ImageTexture.new()
			preview_texture.set_image(preview.get_image())
			share_button.send_asset("node", node, preview_texture)

var edit_generator_prev_state : Dictionary
var edit_generator_next_state : Dictionary

func edit_generator() -> void:
	if generator.has_method("edit"):
		edit_generator_prev_state = generator.get_parent().serialize().duplicate(true)
		edit_generator_next_state = {}
		generator.edit(self)

func update_shader_generator(shader_model) -> void:
	generator.set_shader_model(shader_model)
	update_node()
	get_parent().set_need_save()
	edit_generator_next_state = generator.get_parent().serialize().duplicate(true)

func update_sdf_generator(sdf_scene) -> void:
	generator.node_parameters = sdf_scene.parameters
	generator.set_sdf_scene(sdf_scene.scene)
	update_node()
	get_parent().set_need_save()
	edit_generator_next_state = generator.get_parent().serialize().duplicate(true)

func finalize_generator_update() -> void:
	if ! edit_generator_next_state.is_empty():
		get_parent().undoredo_create_step("Edit node", generator.get_parent().get_hier_name(), edit_generator_prev_state, edit_generator_next_state)
		edit_generator_prev_state = {}
		edit_generator_next_state = {}
