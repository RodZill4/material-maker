extends MMGraphNodeGeneric
class_name MMGraphNodeRemote


var old_state : Dictionary

var links = {}


@onready var grid = $Controls


func _ready():
	super._ready()

func add_control(text : String, control : Control, is_named_param : bool, short_description : String = "", long_description : String = "", is_first : bool = false, is_last : bool = false) -> void:
	var line_edit : LineEdit = LineEdit.new()
	line_edit.set_text(control.name)
	line_edit.custom_minimum_size.x = 80
	grid.add_child(line_edit)
	line_edit.connect("text_changed", Callable(self, "on_param_name_changed").bind(control.name, line_edit))
	line_edit.connect("text_submitted", Callable(self, "on_param_name_entered").bind(control.name, line_edit))
	line_edit.connect("focus_exited", Callable(self, "on_param_name_entered2").bind(control.name, line_edit))
	var label = preload("res://material_maker/widgets/linked_widgets/editable_label.tscn").instantiate()
	label.set_text(text)
	label.connect("label_changed", Callable(self, "on_label_changed").bind(control.name))
	grid.add_child(label)
	var description = preload("res://material_maker/widgets/desc_button/desc_button.tscn").instantiate()
	description.short_description = short_description
	description.long_description = long_description
	description.connect("descriptions_changed", Callable(self, "_on_descriptions_changed").bind(control.name))
	grid.add_child(description)
	grid.add_child(control)
	control.connect("mouse_entered", Callable(self, "on_enter_widget").bind(control))
	control.connect("mouse_exited", Callable(self, "on_exit_widget").bind(control))
	control.tooltip_text = ""
	var button = Button.new()
	if is_named_param:
		button.icon = preload("res://material_maker/icons/edit.tres")
		grid.add_child(button)
		button.connect("pressed", Callable(self, "_on_Edit_pressed").bind(control.name))
		button.tooltip_text = "Configure named parameter "+control.name
	else:
		button.icon = preload("res://material_maker/icons/link.tres")
		grid.add_child(button)
		button.connect("pressed", Callable(self, "_on_Link_pressed").bind(control.name))
		button.tooltip_text = "Link another parameter"
	button = Button.new()
	button.icon = preload("res://material_maker/icons/remove.tres")
	button.tooltip_text = "Remove parameter"
	grid.add_child(button)
	button.connect("pressed", Callable(self, "remove_parameter").bind(control.name))
	button = Button.new()
	button.icon = preload("res://material_maker/icons/up.tres")
	button.tooltip_text = "Move parameter up"
	grid.add_child(button)
	if is_first:
		button.disabled = true
	else:
		button.connect("pressed", Callable(self, "move_parameter").bind(control.name, -1))
	button = Button.new()
	button.icon = preload("res://material_maker/icons/down.tres")
	button.tooltip_text = "Move parameter down"
	grid.add_child(button)
	if is_last:
		button.disabled = true
	else:
		button.connect("pressed", Callable(self, "move_parameter").bind(control.name, 1))

func update_node() -> void:
	await get_tree().process_frame
	# Show or hide the close button
	close_button.visible = generator.can_be_deleted()
	# Delete the contents and wait until it's done
	for c in grid.get_children():
		grid.remove_child(c)
		c.free()
	title = generator.get_type_name()
	controls = {}
	var parameter_count : int = generator.get_parameter_defs().size()
	for i in range(parameter_count):
		var p = generator.get_parameter_defs()[i]
		var control = create_parameter_control(p, false)
		if control != null:
			control.name = p.name
			controls[control.name] = control
			var widget = generator.get_widget(p.name)
			var shortdesc : String = widget.shortdesc if widget.has("shortdesc") else ""
			var longdesc : String = widget.longdesc if widget.has("longdesc") else ""
			var is_named_param : bool = ( p.widget_type == "named_parameter" )
			add_control(generator.get_widget(p.name).label, control, is_named_param, shortdesc, longdesc, i == 0, i == parameter_count-1)
			if generator.widgets[i].type == "config_control" and control is OptionButton:
				var current = null
				if control.get_item_count() > 0 and generator.parameters.has(p.name):
					control.selected = generator.parameters[p.name]
					current = control.get_item_text(control.selected)
				control.add_separator()
				control.add_item("<add configuration>")
				if current != null:
					control.add_separator()
					control.add_item("<update "+current+">")
					control.add_item("<remove "+current+">")
	size = Vector2(0, 0)
	initialize_properties()

func _on_value_changed(new_value, variable : String) -> void:
	var widget = generator.get_widget(variable)
	if !widget.has("type"):
		return
	if widget.type == "config_control":
		var configuration_count = widget.configurations.size()
		var control = controls[variable]
		if control is OptionButton:
			if new_value < configuration_count:
				super._on_value_changed(new_value, variable)
				var current = control.get_item_text(new_value)
				control.set_item_text(configuration_count+3, "<update "+current+">")
				control.set_item_text(configuration_count+4, "<remove "+current+">")
			else:
				var current = control.get_item_text(generator.parameters[variable])
				var command = new_value - widget.configurations.size()
				match command:
					1:
						var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
						add_child(dialog)
						var status = await dialog.enter_text("Configuration", "Enter a name for the new configuration", "")
						if status.ok:
							generator.add_configuration(variable, status.text)
					3:
						generator.update_configuration(variable, current)
					4:
						generator.parameters[variable] = 0
						generator.remove_configuration(variable, current)
					_:
						print(command)
			return
	super._on_value_changed(new_value, variable)

func undo_redo_register_change(action_name : String, previous_state : Dictionary):
	var new_state = generator.serialize().duplicate(true)
	if new_state.hash() == previous_state.hash():
		return
	get_parent().undoredo_create_step(action_name, generator.get_hier_name(), previous_state, new_state)
		
func move_parameter(widget_name : String, offset : int) -> void:
	old_state = generator.serialize().duplicate(true)
	generator.move_parameter(widget_name, offset)
	undo_redo_register_change("Move parameter", old_state)

func remove_parameter(widget_name : String) -> void:
	old_state = generator.serialize().duplicate(true)
	generator.remove_parameter(widget_name)
	undo_redo_register_change("Remove parameter", old_state)

func on_param_name_changed(new_name : String, param_name : String, line_edit : LineEdit) -> void:
	if generator.rename(param_name, new_name, true):
		line_edit.add_theme_color_override("font_color", mm_globals.main_window.theme.get_color("font_color", "LineEdit"))
	else:
		line_edit.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))

func on_param_name_entered(new_name : String, param_name : String, _line_edit : LineEdit) -> void:
	old_state = generator.serialize().duplicate(true)
	generator.rename(param_name, new_name)
	undo_redo_register_change("Change parameter name", old_state)

func on_param_name_entered2(param_name : String, line_edit : LineEdit) -> void:
	old_state = generator.serialize().duplicate(true)
	on_param_name_entered(line_edit.text, param_name, line_edit)
	undo_redo_register_change("Change parameter name", old_state)

func on_label_changed(new_label, param_name) -> void:
	old_state = generator.serialize().duplicate(true)
	generator.set_label(param_name, new_label)
	undo_redo_register_change("Change parameter label", old_state)

func _on_descriptions_changed(shortdesc, longdesc, param_name) -> void:
	old_state = generator.serialize().duplicate(true)
	var widget = generator.get_widget(param_name)
	if widget != null:
		if shortdesc == "":
			widget.erase("shortdesc")
		else:
			widget.shortdesc = shortdesc
		if longdesc == "":
			widget.erase("longdesc")
		else:
			widget.longdesc = longdesc
	undo_redo_register_change("Change parameter description", old_state)

func link_parameter(widget_name : String, target_generator : MMGenBase, target_parameter : String) -> void:
	generator.link_parameter(widget_name, target_generator, target_parameter)
	undo_redo_register_change("Change parameter name", old_state)

func _on_AddLink_pressed() -> void:
	old_state = generator.serialize().duplicate(true)
	var control = generator.create_linked_control("Unnamed")
	var widget = Control.new()
	widget.name = control
	add_control("Unnamed", widget, false)
	var link = MMNodeLink.new(get_parent())
	link.pick(widget, self, control, true)

func _on_AddConfig_pressed() -> void:
	old_state = generator.serialize().duplicate(true)
	var control = generator.create_config_control("Unnamed")
	var widget = Control.new()
	widget.name = control
	add_control("Unnamed", widget, false)
	var link = MMNodeLink.new(get_parent())
	link.pick(widget, self, control, true)

func _on_AddNamed_pressed():
	old_state = generator.serialize().duplicate(true)
	var _control = generator.create_named_parameter("Unnamed")
	update_node()
	undo_redo_register_change("Add named parameter", old_state)

func _on_Link_pressed(param_name) -> void:
	var link = MMNodeLink.new(get_parent())
	if controls.has(param_name):
		old_state = generator.serialize().duplicate(true)
		link.pick(controls[param_name], self, param_name)

func _on_Edit_pressed(param_name) -> void:
	for p in generator.get_parameter_defs():
		if p.name == param_name:
			var dialog = preload("res://material_maker/nodes/remote/named_parameter_dialog.tscn").instantiate()
			add_child(dialog)
			var result = await dialog.configure_param(p.min, p.max, p.step, p.default)
			if result.keys().size() == 4:
				old_state = generator.serialize().duplicate(true)
				generator.configure_named_parameter(param_name, result.min, result.max, result.step, result.default)
				undo_redo_register_change("Configure named parameter", old_state)

func _on_Remote_resize_request(new_minsize) -> void:
	size = new_minsize

func _on_HBoxContainer_minimum_size_changed() -> void:
	print("_on_HBoxContainer_minimum_size_changed "+str($HBoxContainer.custom_minimum_size))

func on_parameter_changed(p, v) -> void:
	if p == "":
		update_node()
	else:
		super.on_parameter_changed(p, v)
		if generator.name == "gen_parameter" and generator.get_parent() is MMGenBase:
			generator.get_parent().set_parameter(p, v)

func on_enter_widget(widget) -> void:
	var w = generator.get_widget(widget.name)
	if !w.has("linked_widgets"):
		return
	var new_links = []
	for l in w.linked_widgets:
		var graph_node = get_parent().get_node("node_"+l.node)
		if graph_node != null:
			var control = graph_node.controls[l.widget]
			if control != null:
				var link = MMNodeLink.new(get_parent())
				link.show_link(widget, control)
				new_links.push_back(link)
	# free existing links if any
	on_exit_widget(widget)
	# store new links
	links[widget] = new_links

func on_exit_widget(widget) -> void:
	if links.has(widget):
		for l in links[widget]:
			l.queue_free()
		links.erase(widget)
