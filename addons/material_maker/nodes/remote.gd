tool
extends MMGraphNodeGeneric
class_name MMGraphNodeRemote

func add_control(text, control):
	var index = $Controls.get_child_count() / 4
	var label = preload("res://addons/material_maker/widgets/linked_widgets/editable_label.tscn").instance()
	label.set_text(text)
	$Controls.add_child(label)
	$Controls.add_child(control)
	var button = Button.new()
	button.icon = preload("res://addons/material_maker/icons/link.png")
	$Controls.add_child(button)
	button.connect("pressed", self, "_on_Link_pressed", [ index ])
	button = Button.new()
	button.icon = preload("res://addons/material_maker/icons/remove.png")
	$Controls.add_child(button)
	button.connect("pressed", generator, "remove_parameter", [ index ])

func update_node():
	var i : int = 0
	for c in $Controls.get_children():
		c.queue_free()
	yield(get_tree(), "idle_frame")
	controls = {}
	for p in generator.get_parameter_defs():
		var control = create_parameter_control(p)
		if control != null:
			control.name = p.name
			controls[control.name] = control
			add_control(generator.widgets[i].label, control)
			if generator.widgets[i].type == "config_control":
				var current = null
				if control.get_item_count() > 0:
					control.selected = generator.parameters["param"+str(i)]
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

func _on_value_changed(new_value, variable):
	var param_index = variable.trim_prefix("param").to_int()
	var widget = generator.widgets[param_index]
	if widget.type == "config_control":
		var configuration_count = widget.configurations.size()
		var control = $Controls.get_child(param_index*4+1)
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
					var dialog = preload("res://addons/material_maker/widgets/line_dialog.tscn").instance()
					add_child(dialog)
					dialog.set_texts("Configuration", "Enter a name for the new configuration")
					dialog.connect("ok", self, "do_add_configuration", [ param_index ])
					dialog.popup_centered()
				3:
					generator.update_configuration(param_index, current)
				4:
					generator.parameters[variable] = 0
					generator.remove_configuration(param_index, current)
				_:
					print(command)
	else:
		._on_value_changed(new_value, variable)

func do_add_configuration(config_name, param_index):
	generator.add_configuration(param_index, config_name)

func _on_AddLink_pressed():
	var widget = Control.new()
	add_control("Unnamed", widget)
	var link = MMNodeLink.new(get_parent())
	link.pick(widget, generator, generator.create_linked_control("Unnamed"), true)

func _on_AddConfig_pressed():
	var widget = Control.new()
	add_control("Unnamed", widget)
	var link = MMNodeLink.new(get_parent())
	link.pick(widget, generator, generator.create_config_control("Unnamed"), true)

func _on_Link_pressed(index):
	var link = MMNodeLink.new(get_parent())
	link.pick($Controls.get_child(index*4+1), generator, index)

func _on_Remote_resize_request(new_minsize):
	print("_on_Remote_resize_request")
	rect_size = new_minsize

func _on_HBoxContainer_minimum_size_changed():
	print("_on_HBoxContainer_minimum_size_changed "+str($HBoxContainer.rect_min_size))

func on_parameter_changed(p, v):
	if p == "":
		update_node()
	else:
		.on_parameter_changed(p, v)