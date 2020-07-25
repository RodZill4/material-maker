extends MMGraphNodeGeneric
class_name MMGraphNodeRemote

var links = {}

onready var grid = $Controls

func add_control(text, control) -> void:
	var label = preload("res://material_maker/widgets/linked_widgets/editable_label.tscn").instance()
	label.set_text(text)
	label.connect("label_changed", self, "on_label_changed", [ control.name ])
	grid.add_child(label)
	grid.add_child(control)
	control.connect("mouse_entered", self, "on_enter_widget", [ control ])
	control.connect("mouse_exited", self, "on_exit_widget", [ control ])
	var button = Button.new()
	button.icon = preload("res://material_maker/icons/link.tres")
	grid.add_child(button)
	button.connect("pressed", self, "_on_Link_pressed", [ control.name ])
	button = Button.new()
	button.icon = preload("res://material_maker/icons/remove.tres")
	grid.add_child(button)
	button.connect("pressed", generator, "remove_parameter", [ control.name ])

func update_node() -> void:
	# Show or hide the close button
	show_close = generator.can_be_deleted()
	# Delete the contents and wait until it's done
	var i : int = 0
	for c in grid.get_children():
		c.queue_free()
	yield(get_tree(), "idle_frame")
	title = generator.get_type_name()
	controls = {}
	for p in generator.get_parameter_defs():
		var control = create_parameter_control(p)
		if control != null:
			control.name = p.name
			controls[control.name] = control
			add_control(generator.get_widget(p.name).label, control)
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
		i += 1
	rect_size = Vector2(0, 0)
	initialize_properties()

func _on_value_changed(new_value, variable : String) -> void:
	var widget = generator.get_widget(variable)
	if widget.type == "config_control":
		var configuration_count = widget.configurations.size()
		var control = controls[variable]
		if control is OptionButton:
			if new_value < configuration_count:
				._on_value_changed(new_value, variable)
				var current = control.get_item_text(new_value)
				control.set_item_text(configuration_count+3, "<update "+current+">")
				control.set_item_text(configuration_count+4, "<remove "+current+">")
			else:
				var current = control.get_item_text(generator.parameters[variable])
				var command = new_value - widget.configurations.size()
				match command:
					1:
						var dialog = preload("res://material_maker/widgets/line_dialog.tscn").instance()
						add_child(dialog)
						dialog.set_texts("Configuration", "Enter a name for the new configuration")
						dialog.connect("ok", self, "do_add_configuration", [ variable ])
						dialog.connect("popup_hide", dialog, "queue_free")
						dialog.popup_centered()
					3:
						generator.update_configuration(variable, current)
					4:
						generator.parameters[variable] = 0
						generator.remove_configuration(variable, current)
					_:
						print(command)
			return
	._on_value_changed(new_value, variable)

func do_add_configuration(config_name : String, param_name : String) -> void:
	generator.add_configuration(param_name, config_name)

func on_label_changed(new_label, param_name) -> void:
	generator.set_label(param_name, new_label)

func _on_AddLink_pressed() -> void:
	var control = generator.create_linked_control("Unnamed")
	var widget = Control.new()
	widget.name = control
	add_control("Unnamed", widget)
	var link = MMNodeLink.new(get_parent())
	link.pick(widget, generator, control, true)

func _on_AddConfig_pressed() -> void:
	var control = generator.create_config_control("Unnamed")
	var widget = Control.new()
	widget.name = control
	add_control("Unnamed", widget)
	var link = MMNodeLink.new(get_parent())
	link.pick(widget, generator, control, true)

func _on_Link_pressed(param_name) -> void:
	var link = MMNodeLink.new(get_parent())
	if controls.has(param_name):
		link.pick(controls[param_name], generator, param_name)

func _on_Remote_resize_request(new_minsize) -> void:
	rect_size = new_minsize

func _on_HBoxContainer_minimum_size_changed() -> void:
	print("_on_HBoxContainer_minimum_size_changed "+str($HBoxContainer.rect_min_size))

func on_parameter_changed(p, v) -> void:
	if p == "":
		update_node()
	else:
		.on_parameter_changed(p, v)

func on_enter_widget(widget) -> void:
	var w = generator.get_widget(widget.name)
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
