extends MMGraphNodeMinimal


const PREVIEW_SIZES : Array[int] = [ 0, 64, 128, 192]


func _ready() -> void:
	super._ready()
	get_titlebar_hbox().get_child(0).hide()
	close_button.visible = false
	theme_type_variation = "MM_Reroute"
	#set_theme_type("Reroute")
	on_connections_changed.call_deferred()

func set_generator(g : MMGenBase) -> void:
	super.set_generator(g)
	generator.parameter_changed.connect(self.on_parameter_changed)
	await set_preview(g.get_parameter("preview"))
	update_node()

func _draw_port(slot_index: int, position: Vector2i, left: bool, color: Color) -> void:
	draw_circle(position, 5, color, true, -1, true)

#func set_theme_type(type : StringName):
	#var current_theme : Theme = mm_globals.main_window.theme
	#for constant in current_theme.get_constant_list(type):
		#add_theme_constant_override(constant, current_theme.get_constant(constant, type))
	#for stylebox in current_theme.get_stylebox_list(type):
		#add_theme_stylebox_override(stylebox, current_theme.get_stylebox(stylebox, type))

func on_connections_changed():
	var graph_edit = get_parent()
	var color : Color = Color(1.0, 1.0, 1.0)
	var type : int = 42
	var port_type : String = "any"
	for c in graph_edit.get_connection_list():
		if c.to_node == name:
			var node : GraphNode = graph_edit.get_node(NodePath(c.from_node))
			color = node.get_slot_color_right(c.from_port)
			type = node.get_slot_type_right(c.from_port)
			port_type = node.generator.get_output_defs()[c.from_port].type
			break
		if c.from_node == name:
			var node : GraphNode = graph_edit.get_node(NodePath(c.to_node))
			color = node.get_slot_color_left(c.to_port)
			type = node.get_slot_type_left(c.to_port)
			port_type = node.generator.get_input_defs()[c.from_port].type
	set_slot(0, true, type, color, true, type, color)
	generator.set_port_type(port_type)
	update_preview()

func update_preview(preview : Control = null):
	if preview == null:
		if $Contents.get_child_count() == 0:
			return
		preview = $Contents.get_child(0)
	var preview_source : MMGenBase.OutputPort = generator.get_source(0)
	if preview_source == null:
		preview.set_generator(null)
	else:
		preview.set_generator(preview_source.generator, preview_source.output_index)


func _input(event:InputEvent) -> void:
	if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and is_visible_in_tree():
		accept_event()
		var menu : PopupMenu = PopupMenu.new()
		menu.add_item("No preview")
		menu.add_item("Small preview")
		menu.add_item("Large preview")
		menu.add_item("Huge preview")
		add_child(menu)
		menu.id_pressed.connect(self.on_context_menu)
		mm_globals.popup_menu(menu, self)


func on_context_menu(id : int):
	var old_value = generator.get_parameter("preview")
	if old_value != id and get_parent().get("undoredo") != null:
		var node_hier_name = generator.get_hier_name()
		var undo_command = { type="setparams", node=node_hier_name, params={ preview=old_value } }
		var redo_command = { type="setparams", node=node_hier_name, params={ preview=id } }
		get_parent().undoredo.add("Set parameter value", [ undo_command ], [ redo_command ])
	generator.set_parameter("preview", id)

func on_parameter_changed(n : String, v):
	if n == "preview":
		var old_size : Vector2 = size
		await set_preview(v)
		disable_undoredo_for_offset = true
		position_offset -= (size-old_size)/2
		disable_undoredo_for_offset = false
	else:
		update_preview()

func set_preview(v : int):
	var preview : Control = null
	if $Contents.get_child_count() > 0:
		preview = $Contents.get_child(0)
	if v == 0:
		if preview:
			preview.queue_free()
		theme_type_variation = "MM_Reroute"
		#set_theme_type("Reroute")
	else:
		if ! preview:
			preview = preload("res://material_maker/panels/preview_2d/preview_2d_node.tscn").instantiate()
			$Contents.add_child(preview)
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			update_preview(preview)
		var preview_size : int = PREVIEW_SIZES[v]
		preview.custom_minimum_size = Vector2(preview_size, preview_size)
		#set_theme_type("ReroutePreview")
		theme_type_variation = "MM_ReroutePreview"
	await get_tree().process_frame
	size = Vector2(0, 0)
