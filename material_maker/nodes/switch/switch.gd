extends MMGraphNodeGeneric

var fixed_lines : int = 0

func _ready() -> void:
	super._ready()
	update_node()

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
			control.custom_minimum_size.x = 75
			if l.has("tooltip"):
				control.tooltip_text = l.tooltip
			sizer.add_child(control)
			control.connect("value_changed", Callable(self, "_on_value_changed").bind(l.name))
			controls[l.name] = control
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
		add_child(sizer)
	size = Vector2(0, 0)
	for i in range(get_child_count()):
		var sizer = get_child(i)
		var has_input = true
		var has_output = i < output_count
		if i >= input_count:
			sizer.get_child(0).text = ""
			has_input = false
		else:
# warning-ignore:integer_division
			var source : int = i/output_count
			sizer.get_child(0).text = PackedByteArray([65+i%int(output_count)]).get_string_from_ascii()+str(1+source)
			sizer.get_child(0).add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if source == generator.parameters.source else Color(0.5, 0.5, 0.5))
		set_slot(i, has_input, 42, Color(1.0, 1.0, 1.0, 1.0), has_output, 42, Color(1.0, 1.0, 1.0, 1.0))
	# Preview
	restore_preview_widget()
