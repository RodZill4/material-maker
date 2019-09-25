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
	if widget.type == "config_control" and new_value >= widget.configurations.size():
		var command = new_value - widget.configurations.size()
		print(command)
	else:
		._on_value_changed(new_value, variable)

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