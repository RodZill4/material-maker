extends GraphNode

var generator = null setget set_generator

var controls = []

var uses_seed : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_generator(g):
	generator = g
	if g.get("shader_model") != null:
		update_node(g.shader_model)
	else:
		update_node({})

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

func update_node(data):
	if typeof(data) != TYPE_DICTIONARY:
		return
	# Clean node
	var custom_node_buttons = null
	for c in get_children():
		if c.name != "CustomNodeButtons":
			remove_child(c)
			c.queue_free()
		else:
			custom_node_buttons = c
	# Rebuild node
	title = generator.get_type_name()
	uses_seed = false
	if data.has("instance") and data.instance.find("$(seed)"):
		uses_seed = true
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
		print(input)
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
	# Outputs
	var outputs = generator.get_output_defs()
	for i in range(outputs.size()):
		var output = outputs[i]
		print(output)
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
	if custom_node_buttons != null:
		move_child(custom_node_buttons, get_child_count()-1)
