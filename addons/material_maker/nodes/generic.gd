tool
extends GraphNode

var generator = null setget set_generator

var controls = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_generator(g):
	generator = g
	update_node()

func on_close_request():
	generator.get_parent().remove_generator(generator)

func on_offset_changed():
	generator.position = offset

func initialize_properties():
	for o in controls:
		if o == null:
			print("error in node "+name)
			continue
		if !generator.parameters.has(o.name):
			continue
		if o is LineEdit:
			o.text = str(generator.parameters[o.name])
			o.connect("text_changed", self, "_on_text_changed", [ o.name ])
		elif o is SpinBox:
			o.value = generator.parameters[o.name]
			o.connect("value_changed", self, "_on_value_changed", [ o.name ])
		elif o is HSlider:
			o.value = generator.parameters[o.name]
			o.connect("value_changed", self, "_on_value_changed", [ o.name ])
		elif o is OptionButton:
			o.selected = generator.parameters[o.name]
			o.connect("item_selected", self, "_on_value_changed", [ o.name ])
		elif o is CheckBox:
			o.pressed = generator.parameters[o.name]
			o.connect("toggled", self, "_on_value_changed", [ o.name ])
		elif o is ColorPickerButton:
			o.color = MMType.deserialize_value(generator.parameters[o.name])
			o.connect("color_changed", self, "_on_color_changed", [ o.name ])
		elif o is Control and o.filename == "res://addons/material_maker/widgets/gradient_editor.tscn":
			var gradient : MMGradient = MMGradient.new()
			gradient.deserialize(generator.parameters[o.name])
			o.value = gradient
			o.connect("updated", self, "_on_gradient_changed", [ o.name ])
		else:
			print("unsupported widget "+str(o))

func update_shaders():
	get_parent().send_changed_signal()

func _on_text_changed(new_text, variable):
	generator.parameters[variable] = float(new_text)
	update_shaders()

func _on_value_changed(new_value, variable):
	generator.parameters[variable] = new_value
	update_shaders()

func _on_color_changed(new_color, variable):
	generator.parameters[variable] = new_color
	update_shaders()

func _on_gradient_changed(new_gradient, variable):
	generator.parameters[variable] = new_gradient
	update_shaders()

func update_node():
	# Clean node
	var custom_node_buttons = null
	for c in get_children():
		if c.name != "CustomNodeButtons":
			remove_child(c)
			c.queue_free()
		else:
			custom_node_buttons = c
	rect_size = Vector2(0, 0)
	# Rebuild node
	title = generator.get_type_name()
	# Parameters
	controls = []
	var sizer = null
	for p in generator.get_parameter_defs():
		if !p.has("name") or !p.has("type"):
			continue
		var control = null
		if p.type == "float":
			if p.has("widget") and p.widget == "spinbox":
				control = SpinBox.new()
			else:
				control = HSlider.new()
			control.min_value = p.min
			control.max_value = p.max
			control.step = 0 if !p.has("step") else p.step
			if p.has("default"):
				control.value = p.default
			control.rect_min_size.x = 80
		elif p.type == "size":
			control = OptionButton.new()
			for i in range(p.first, p.last+1):
				var s = pow(2, i)
				control.add_item("%dx%d" % [ s, s ])
				control.selected = 0 if !p.has("default") else p.default-p.first
		elif p.type == "enum":
			control = OptionButton.new()
			for i in range(p.values.size()):
				var value = p.values[i]
				control.add_item(value.name)
				control.selected = 0 if !p.has("default") else p.default
		elif p.type == "boolean":
			control = CheckBox.new()
		elif p.type == "color":
			control = ColorPickerButton.new()
		elif p.type == "gradient":
			control = preload("res://addons/material_maker/widgets/gradient_editor.tscn").instance()
		if control != null:
			var label = p.name
			control.name = label
			controls.append(control)
			if p.has("label"):
				label = p.label
			if sizer == null or label != "nonewline":
				sizer = HBoxContainer.new()
				sizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
				add_child(sizer)
			if label != "" && label != "nonewline":
				var label_widget = Label.new()
				label_widget.text = label
				label_widget.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
				sizer.add_child(label_widget)
			control.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
			sizer.add_child(control)
	initialize_properties()
	# Inputs
	var inputs = generator.get_input_defs()
	for i in range(inputs.size()):
		var input = inputs[i]
		var enable_left = false
		var color_left = Color(0.5, 0.5, 0.5)
		if typeof(input) == TYPE_DICTIONARY:
			if input.type == "rgb":
				enable_left = true
				color_left = Color(0.5, 0.5, 1.0)
			elif input.type == "rgba":
				enable_left = true
				color_left = Color(0.0, 0.5, 0.0, 0.5)
			else:
				enable_left = true
		set_slot(i, enable_left, 0, color_left, false, 0, Color())
		if i >= get_child_count():
			var control = Control.new()
			control.rect_min_size = Vector2(0, 16)
			add_child(control)
	# Outputs
	var outputs = generator.get_output_defs()
	for i in range(outputs.size()):
		var output = outputs[i]
		var enable_right = false
		var color_right = Color(0.5, 0.5, 0.5)
		if typeof(output) == TYPE_DICTIONARY:
			if output.has("rgb"):
				enable_right = true
				color_right = Color(0.5, 0.5, 1.0)
			elif output.has("rgba"):
				enable_right = true
				color_right = Color(0.0, 0.5, 0.0, 0.5)
			elif output.has("f"):
				enable_right = true
		set_slot(i, is_slot_enabled_left(i), get_slot_type_left(i), get_slot_color_left(i), enable_right, 0, color_right)
		if i >= get_child_count():
			var control = Control.new()
			control.rect_min_size = Vector2(0, 16)
			add_child(control)
	if generator.model == null:
		var edit_buttons = preload("res://addons/material_maker/nodes/edit_buttons.tscn").instance()
		add_child(edit_buttons)
		edit_buttons.connect_buttons(self, "edit_generator", "load_generator", "save_generator")

func edit_generator():
	var edit_window = load("res://addons/material_maker/widgets/node_editor/node_editor.tscn").instance()
	get_parent().add_child(edit_window)
	if generator.shader_model != null:
		edit_window.set_model_data(generator.shader_model)
	edit_window.connect("node_changed", self, "update_generator")
	edit_window.popup_centered()

func update_generator(shader_model):
	generator.shader_model = shader_model
	update_node()

func load_generator():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.mmg,*.mmn;Material Maker Generator")
	dialog.connect("file_selected", self, "do_load_generator")
	dialog.popup_centered()

func do_load_generator(file_name : String):
	var new_generator = null
	if file_name.ends_with(".mmn"):
		var file = File.new()
		if file.open(file_name, File.READ) == OK:
			new_generator = MMGenShader.new()
			new_generator.set_shader_model(parse_json(file.get_as_text()))
			file.close()
	else:
		new_generator = MMGenLoader.load_gen(file_name)
	if new_generator != null:
		var parent_generator = generator.get_parent()
		parent_generator.replace_generator(generator, new_generator)
		generator = new_generator
		update_node()

func save_generator():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	dialog.connect("file_selected", self, "do_save_generator")
	dialog.popup_centered()

func do_save_generator(file_name : String):
	var data = generator.serialize()
	data.node_position = { x=0, y=0 }
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()
