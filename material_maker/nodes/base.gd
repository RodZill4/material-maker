extends MMGraphNodeMinimal
class_name MMGraphNodeBase


var minimize_button : TextureButton
var randomness_button : TextureButton
var buffer_button : TextureButton

var show_inputs : bool = false
var show_outputs : bool = false


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

const TIME_COLOR_BAD : Color = Color(1, 0, 0)
const TIME_COLOR_AVG : Color = Color(1, 1, 0)
const TIME_COLOR_GOOD : Color = Color(0, 1, 0)
const TIME_BAD : int = 1000
const TIME_AVG : int = 500
const TIME_GOOD : int = 100


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
	super._ready()
	_notification(NOTIFICATION_THEME_CHANGED)
	gui_input.connect(self._on_gui_input)
	update.call_deferred()

func init_buttons():
	super.init_buttons()
	minimize_button = add_button(MINIMIZE_ICON, on_minimize_pressed)
	minimize_button.tooltip_text = tr("Minimize the node")
	randomness_button = add_button(RANDOMNESS_ICON, on_randomness_pressed, randomness_button_create_popup)
	randomness_button.visible = false
	randomness_button.tooltip_text = tr("Change seed (left mouse button) / Show seed menu (right mouse button)")
	buffer_button = add_button(BUFFER_ICON, null, buffer_button_create_popup)
	buffer_button.visible = false

func on_minimize_pressed():
	generator.minimized = !generator.minimized
	var hier_name = generator.get_hier_name()
	get_parent().undoredo.add("Minimize node", [{ type="setminimized", node=hier_name, minimized=!generator.minimized }], [{ type="setminimized", node=hier_name, minimized=generator.minimized }], false)
	update_node()

func on_randomness_pressed():
	reroll_generator_seed()

func randomness_button_create_popup():
	var menu : PopupMenu = PopupMenu.new()
	menu.add_item(tr("Unlock seed") if generator.is_seed_locked() else tr("Lock seed"), 0)
	menu.add_separator()
	menu.add_item(tr("Copy seed"), 1)
	if ! generator.is_seed_locked() and DisplayServer.clipboard_get().left(5) == "seed=":
		menu.add_item(tr("Paste seed"), 2)
	add_child(menu)
	mm_globals.popup_menu(menu, self)
	menu.connect("popup_hide", Callable(menu, "queue_free"))
	menu.connect("id_pressed", Callable(self, "_on_seed_menu"))

func buffer_button_create_popup():
	var menu : PopupMenu = PopupMenu.new()
	menu.add_item(tr("Pause buffers"), MENU_BUFFER_PAUSE)
	menu.set_item_disabled(MENU_BUFFER_PAUSE, generator.get_buffers(MMGenBase.BUFFERS_RUNNING).is_empty())
	menu.add_item(tr("Resume buffers"), MENU_BUFFER_RESUME)
	menu.set_item_disabled(MENU_BUFFER_RESUME, generator.get_buffers(MMGenBase.BUFFERS_PAUSED).is_empty())
	if OS.is_debug_build():
		menu.add_separator()
		menu.add_item(tr("Dump buffers"), MENU_BUFFER_DUMP)
	add_child(menu)
	mm_globals.popup_menu(menu, self)
	menu.connect("popup_hide",Callable(menu,"queue_free"))
	menu.connect("id_pressed",Callable(self,"_on_buffer_menu"))

func on_generator_changed(g):
	if generator == g:
		update()

func get_rendering_time_color(rendering_time : int) -> Color:
	if rendering_time <= TIME_GOOD:
		return TIME_COLOR_GOOD
	elif rendering_time <= TIME_AVG:
		return TIME_COLOR_GOOD.lerp(TIME_COLOR_AVG, float(rendering_time-TIME_GOOD)/float(TIME_AVG-TIME_GOOD))
	elif rendering_time <= TIME_BAD:
		return TIME_COLOR_AVG.lerp(TIME_COLOR_BAD, float(rendering_time-TIME_AVG)/float(TIME_BAD-TIME_AVG))
	else:
		return TIME_COLOR_BAD

func update():
	super.update()
	if generator != null and generator.has_randomness():
		randomness_button.visible = true
		randomness_button.texture_normal = RANDOMNESS_LOCKED_ICON if generator.is_seed_locked() else RANDOMNESS_ICON
	else:
		randomness_button.visible = false
	buffer_button.visible = ! generator.get_buffers().is_empty()
	if buffer_button.visible:
		buffer_button.texture_normal = BUFFER_ICON if generator.get_buffers(MMGenBase.BUFFERS_PAUSED).is_empty() else BUFFER_PAUSED_ICON
		buffer_button.tooltip_text = tr("%d buffer(s), %d paused") % [ generator.get_buffers().size(), generator.get_buffers(MMGenBase.BUFFERS_PAUSED).size() ]

func _notification(what : int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		on_theme_changed()

var portgroup_width : int
var portgroup_stylebox : StyleBox

var portpreview_radius : float
var portpreview_color : Color
var portpreview_width : float


func on_theme_changed() -> void:
	portgroup_width = get_theme_constant("width", "MM_NodePortGroup")
	portgroup_stylebox = get_theme_stylebox("panel", "MM_NodePortGroup")
	queue_redraw()
	
	portpreview_radius = get_theme_constant("portpreview_radius", "GraphNode")
	portpreview_color = get_theme_color("portpreview_color", "GraphNode")
	portpreview_width = get_theme_constant("portpreview_width", "GraphNode")


func _draw_port(slot_index: int, pos: Vector2i, left: bool, color: Color):
	if left:
		var inputs = generator.get_input_defs()
		if slot_index < inputs.size() and inputs[slot_index].has("group_size") and inputs[slot_index].group_size > 1:
			var conn_pos1 = get_input_port_position(slot_index)
			@warning_ignore("narrowing_conversion")
			var conn_pos2 = get_input_port_position(min(slot_index+inputs[slot_index].group_size-1, inputs.size()-1))
			draw_portgroup_stylebox(conn_pos1, conn_pos2)
	else:
		var outputs = generator.get_output_defs()
		if slot_index < outputs.size() and outputs[slot_index].has("group_size") and outputs[slot_index].group_size > 1:
			@warning_ignore("narrowing_conversion")
			var conn_pos1 = get_output_port_position(slot_index)
			var conn_pos2 = get_output_port_position(min(slot_index+outputs[slot_index].group_size-1, outputs.size()-1))
			draw_portgroup_stylebox(conn_pos1, conn_pos2)
	draw_circle(pos, 5, color, true, -1, true)


func _draw() -> void:
	var color : Color = get_theme_color("title_color")
	@warning_ignore("narrowing_conversion")
	var inputs = generator.get_input_defs()
	var font : Font = get_theme_font("default_font")
	if generator != null and generator.model == null and (generator is MMGenShader or generator is MMGenGraph):
		#draw_texture_rect(CUSTOM_ICON, Rect2(3, 8, 7, 7), false, color)
		pass
	for i in range(inputs.size()):
		if show_inputs:
			var string : String = TranslationServer.translate(inputs[i].shortdesc) if inputs[i].has("shortdesc") else TranslationServer.translate(inputs[i].name)
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_input_port_position(i)-Vector2(string_size.x+12, -string_size.y*0.3), string, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
	var outputs = generator.get_output_defs()
	var preview_port : Array = [ -1, -1 ]
	var preview_locked : Array = [ false, false ]
	for i in range(2):
		if get_parent().locked_preview[i] != null:
			if get_parent().locked_preview[i].generator == generator:
				preview_port[i] = get_parent().locked_preview[i].output_index
				preview_locked[i] = true
		elif get_parent().current_preview[i] != null and get_parent().current_preview[i].generator == generator:
			preview_port[i] = get_parent().current_preview[i].output_index
	if preview_port[0] == preview_port[1]:
		preview_port[1] = -1
		preview_locked[0] = preview_locked[0] || preview_locked[1]
	for i in range(outputs.size()):
		var conn_pos = get_output_port_position(i)
		for preview in range(2):
			if i == preview_port[preview]:
				if preview_locked[preview]:
					draw_circle(conn_pos, portpreview_radius, portpreview_color, false, 0.1*portpreview_width, true)
					draw_line(conn_pos+Vector2(-4,4), conn_pos+Vector2(4,-4), portpreview_color, 0.075*portpreview_width, true)
				else:
					draw_circle(conn_pos, portpreview_radius, portpreview_color, false, 0.1*portpreview_width, true)
		if show_outputs:
			var string : StringName = TranslationServer.translate(outputs[i].shortdesc) if outputs[i].has("shortdesc") else StringName(tr("Output")+" "+str(i))
			var string_size : Vector2 = font.get_string_size(string)
			draw_string(font, get_output_port_position(i)+Vector2(12, string_size.y*0.3), string, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
	if false and selected:
		draw_style_box(get_theme_stylebox("node_highlight"), Rect2(Vector2.ZERO, size))
	if generator.rendering_time > 0:
		var time_color : Color = get_rendering_time_color(generator.rendering_time)
		draw_string(font, Vector2i(0, size.y+12), str(generator.rendering_time)+"ms", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, time_color)
	if generator != null and generator.preview >= 0 and get_output_port_count() > 0:
		var conn_pos = get_output_port_position(generator.preview)
		draw_circle(conn_pos, 3, portpreview_color, true)
	
	
func draw_portgroup_stylebox(first_port : Vector2, last_port : Vector2) -> void:
	var stylebox_position: Vector2 = first_port + Vector2(-0.5,-0.5) * portgroup_width
	var stylebox_size: Vector2 = Vector2(portgroup_width, last_port.y - first_port.y + portgroup_width)
	draw_style_box(portgroup_stylebox, Rect2(stylebox_position, stylebox_size))

func set_generator(g) -> void:
	super.set_generator(g)
	g.rendering_time_updated.connect(self.update_rendering_time)

func update_rendering_time(_t : int) -> void:
	queue_redraw()

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

var doubleclicked : bool = false

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.double_click:
				doubleclicked = true
			if event.button_index == MOUSE_BUTTON_RIGHT:
				accept_event()
				var menu : PopupMenu = create_context_menu()
				if menu != null:
					if menu.get_item_count() != 0:
						add_child(menu)
						menu.popup_hide.connect(menu.queue_free)
						menu.id_pressed.connect(self._on_menu_id_pressed)
						mm_globals.popup_menu(menu, self)
					else:
						menu.free()
		elif doubleclicked:
			doubleclicked = false
			if generator is MMGenGraph:
				get_parent().update_view.call_deferred(generator)
			elif generator is MMGenSDF:
				edit_generator()
	elif event is InputEventMouseMotion:
		var epos : Vector2 = event.position
		if Rect2(0, 0, size.x-56, 16).has_point(epos):
			var description = generator.get_description()
			if description != "":
				tooltip_text = MMGraphNodeBase.wrap_string(description)
			elif generator.model != null:
				tooltip_text = TranslationServer.translate(generator.model)
			return
		tooltip_text = ""

func get_slot_from_position(pos : Vector2) -> Dictionary:
	var rv : Dictionary = super.get_slot_from_position(pos)
	var need_update : bool = false
	if rv.show_inputs != show_inputs:
		show_inputs = rv.show_inputs
		need_update = true
	if rv.show_outputs != show_outputs:
		show_outputs = rv.show_outputs
		need_update = true
	if need_update:
		update()
	return rv

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

func create_context_menu() -> PopupMenu:
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
				get_parent().propagate_node_changes.call_deferred(generator)
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
			dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
			dialog.min_size = Vector2(600, 400) * dialog.content_scale_factor
			var result = await dialog.ask(status)
			if result != "ok":
				return
			var node = generator.serialize()
			var share_button = mm_globals.main_window.get_share_button()
			var renderer = await generator.render(self, 0, 1024, true)
			var preview_texture : ImageTexture = ImageTexture.create_from_image(renderer.get_image())
			renderer.release(self)
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
