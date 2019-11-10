extends MMGraphNodeBase

func set_generator(g) -> void:
	.set_generator(g)
	generator.connect("parameter_changed", self, "on_parameter_changed")
	update_node()

func on_parameter_changed(p, v) -> void:
	if p == "__update_all__":
		call_deferred("update_node")

func update_up_down_buttons() -> void:
	for c in get_children():
		if ! (c is Button):
			c.update_up_down_button()

func update_node() -> void:
	for c in get_children():
		remove_child(c)
		c.free()
	rect_size = Vector2(0, 0)
	title = generator.get_type_name()
	var color = Color(0.0, 0.5, 0.0, 0.5)
	for p in generator.get_io_defs():
		set_slot(get_child_count(), generator.name != "gen_inputs", 0, color, generator.name != "gen_outputs", 0, color)
		var port : Control
		if generator.is_editable():
			port = preload("res://addons/material_maker/nodes/ios/port.tscn").instance()
			if p.has("name"):
				port.set_label(p.name)
		else:
			port = Label.new()
			port.text = p.name
		add_child(port)
	if generator.is_editable():
		var add_button : Button = preload("res://addons/material_maker/nodes/ios/add.tscn").instance()
		add_child(add_button)
		add_button.connect("pressed", generator, "add_port")
		set_slot(get_child_count()-1, false, 0, color, false, 0, color)
		update_up_down_buttons()

