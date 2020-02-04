extends MMGraphNodeGeneric

var fixed_lines : int = 0

func _ready() -> void:
	update_node()

func update_preview_buttons(index : int) -> void:
	for i in range(generator.parameters.outputs):
		if i != index:
			var line = get_child(i)
			line.get_child(2).pressed = false

func update_node() -> void:
	if generator == null or !generator.parameters.has("outputs") or !generator.parameters.has("choices"):
		return
	save_preview_widget()
	var new_fixed_lines = 3 if generator.editable else 1
	if new_fixed_lines != fixed_lines:
		fixed_lines = new_fixed_lines
		# Remove all lines
		while get_child_count() > 0:
			var remove = get_child(0)
			remove_child(remove)
			remove.free()
		var lines_list = []
		if generator.editable:
			lines_list.push_back( { name="outputs", tooltip="Outputs count", min=1, max=5 } )
			lines_list.push_back( { name="choices", tooltip="Choices count", min=2, max=10 } )
		lines_list.push_back( { name="source", tooltip="Current choice", min=0, max=generator.parameters.choices-1 } )
		for l in lines_list:
			var sizer = HBoxContainer.new()
			var input_label = Label.new()
			sizer.add_child(input_label)
			if generator.editable:
				var param_label = Label.new()
				param_label.text = l.tooltip
				sizer.add_child(param_label)
			var control : HSlider = HSlider.new()
			control.name = l.name
			control.value = generator.parameters[l.name]
			control.min_value = l.min
			control.max_value = l.max
			control.step = 1
			control.rect_min_size.x = 75
			if l.has("tooltip"):
				control.hint_tooltip = l.tooltip
			sizer.add_child(control)
			control.connect("value_changed", self, "_on_value_changed", [ l.name ])
			controls[l.name] = control
			sizer.add_child(preload("res://material_maker/widgets/preview_button.tscn").instance())
			add_child(sizer)
	else:
		# Keep lines with controls
		while get_child_count() > output_count and get_child_count() > fixed_lines:
			var remove = get_child(get_child_count()-1)
			remove_child(remove)
			remove.free()
	# Populate the GraphNode
	var output_count : int = generator.parameters.outputs
	var input_count : int = output_count * generator.parameters.choices
	controls["source"].max_value = generator.parameters.choices-1
	while get_child_count() < input_count:
		var sizer = HBoxContainer.new()
		var input_label = Label.new()
		sizer.add_child(input_label)
		if get_child_count() < 5:
			var space = Control.new()
			space.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
			sizer.add_child(space)
			var button = preload("res://material_maker/widgets/preview_button.tscn").instance()
			sizer.add_child(button)
			button.connect("toggled", self, "on_preview_button", [ get_child_count()-1 ])
		add_child(sizer)
	rect_size = Vector2(0, 0)
	for i in range(get_child_count()):
		var sizer = get_child(i)
		var has_input = true
		var has_output = false
		if i < 5:
			has_output = i < output_count
			sizer.get_child(sizer.get_child_count()-1).visible = has_output
		if i >= input_count:
			sizer.get_child(0).text = ""
			has_input = false
		else:
			sizer.get_child(0).text = PoolByteArray([65+i%int(output_count)]).get_string_from_ascii()+str(1+i/int(output_count))
			sizer.get_child(0).add_color_override("font_color", Color(1.0, 1.0, 1.0) if i/int(output_count) == generator.parameters.source else Color(0.5, 0.5, 0.5))
		set_slot(i, has_input, 42, Color(1.0, 1.0, 1.0, 1.0), has_output, 42, Color(1.0, 1.0, 1.0, 1.0))
	# Preview
	restore_preview_widget()
