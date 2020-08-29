extends MMGraphNodeBase
class_name MMGraphNodeGeneric

var controls = {}
var ignore_parameter_change = ""
var output_count = 0

var preview : ColorRect
#var preview : TextureRect
var preview_index : int = -1
var preview_position : int
var preview_size : int
var preview_timer : Timer = null

func _draw() -> void:
	._draw()
	if preview_index >= 0:
		var conn_pos = get_connection_output_position(preview_index)
		conn_pos /= get_global_transform().get_scale()
		draw_texture(preload("res://material_maker/icons/output_preview.tres"), conn_pos-Vector2(8, 8), get_color("title_color"))

func set_generator(g : MMGenBase) -> void:
	.set_generator(g)
	generator.connect("parameter_changed", self, "on_parameter_changed")
	update_node()

func on_parameter_changed(p : String, v) -> void:
	if ignore_parameter_change == p:
		return
	if p == "__update_all__":
		update_node()
	elif controls.has(p):
		var o = controls[p]
		if o is Control and o.filename == "res://material_maker/widgets/float_edit/float_edit.tscn":
			o.value = v
		elif o is LineEdit:
			o.text = v
		elif o is SizeOptionButton:
			o.size_value = v
		elif o is OptionButton:
			o.selected = v
		elif o is CheckBox:
			o.pressed = v
		elif o is ColorPickerButton:
			o.color = MMType.deserialize_value(v)
		elif o is Control and o.filename == "res://material_maker/widgets/file_picker_button/file_picker_button.tscn":
			o.path = v
		elif o is Control and o.filename == "res://material_maker/widgets/gradient_editor/gradient_editor.tscn":
			var gradient : MMGradient = MMGradient.new()
			gradient.deserialize(v)
			o.value = gradient
		else:
			print("unsupported widget "+str(o))
	get_parent().set_need_save()

func initialize_properties() -> void:
	var parameter_names = []
	for p in generator.get_parameter_defs():
		parameter_names.push_back(p.name)
	for c in controls:
		if parameter_names.find(c) == -1:
			continue
		var o = controls[c]
		if generator.parameters.has(c):
			on_parameter_changed(c, generator.parameters[c])
		if o is Control and o.filename == "res://material_maker/widgets/float_edit/float_edit.tscn":
			o.connect("value_changed", self, "_on_value_changed", [ o.name ])
		elif o is LineEdit:
			o.connect("text_changed", self, "_on_text_changed", [ o.name ])
		elif o is SizeOptionButton:
			o.connect("size_value_changed", self, "_on_value_changed", [ o.name ])
		elif o is OptionButton:
			o.connect("item_selected", self, "_on_value_changed", [ o.name ])
		elif o is CheckBox:
			o.connect("toggled", self, "_on_value_changed", [ o.name ])
		elif o is ColorPickerButton:
			o.connect("color_changed", self, "_on_color_changed", [ o.name ])
		elif o is Control and o.filename == "res://material_maker/widgets/file_picker_button/file_picker_button.tscn":
			o.connect("on_file_selected", self, "_on_file_changed", [ o.name ])
		elif o is Control and o.filename == "res://material_maker/widgets/gradient_editor/gradient_editor.tscn":
			o.connect("updated", self, "_on_gradient_changed", [ o.name ])
		else:
			print("unsupported widget "+str(o))

func _on_text_changed(new_text, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_text)
	ignore_parameter_change = ""
	get_parent().set_need_save()

func _on_value_changed(new_value, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_value)
	ignore_parameter_change = ""
	get_parent().set_need_save()

func _on_color_changed(new_color, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_color)
	ignore_parameter_change = ""
	get_parent().set_need_save()

func _on_file_changed(new_file, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, new_file)
	ignore_parameter_change = ""
	get_parent().set_need_save()

func _on_gradient_changed(new_gradient, variable : String) -> void:
	ignore_parameter_change = variable
	generator.set_parameter(variable, MMType.serialize_value(new_gradient))
	ignore_parameter_change = ""
	get_parent().set_need_save()

func create_parameter_control(p : Dictionary) -> Control:
	var control = null
	if p.type == "float":
		control = preload("res://material_maker/widgets/float_edit/float_edit.tscn").instance()
		control.min_value = p.min
		control.max_value = p.max
		control.step = 0.005 if !p.has("step") else p.step
		if p.has("default"):
			control.value = p.default
		control.rect_min_size.x = 80
	elif p.type == "size":
		control = SizeOptionButton.new()
		control.min_size = p.first
		control.max_size = p.last
		control.size_value = p.first if !p.has("default") else p.default
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
		control.set_script(preload("res://material_maker/widgets/color_picker_button/color_picker_button.gd"))
		control.rect_min_size.x = 40
	elif p.type == "gradient":
		control = preload("res://material_maker/widgets/gradient_editor/gradient_editor.tscn").instance()
	elif p.type == "string":
		control = LineEdit.new()
	elif p.type == "file":
		control = preload("res://material_maker/widgets/file_picker_button/file_picker_button.tscn").instance()
		if p.has("filters"):
			for f in p.filters:
				control.add_filter(f)
	if p.has("shortdesc"):
		control.hint_tooltip = p.shortdesc+" ("+p.name+")"
	if p.has("longdesc"):
		control.hint_tooltip += "\n"+p.longdesc
	return control

func save_preview_widget() -> void:
	if preview != null and preview.get_parent() == self:
		remove_child(preview)
	if preview_timer != null:
		preview_timer.stop()
		remove_child(preview_timer)

func restore_preview_widget() -> void:
	if preview == null:
		preview = preload("res://material_maker/panels/preview_2d/preview_2d_node.tscn").instance()
		preview.shader = "uniform vec2 size;void fragment() {COLOR = preview_2d(UV);}"
		preview.visible = false
	preview_position = get_child_count()
	if preview.visible:
		add_child(preview)
		update_preview()
	set_slot(preview_position, false, 0, Color(0.0, 0.0, 0.0), false, 0, Color(0.0, 0.0, 0.0))
	# Preview timer
	if preview_timer == null:
		preview_timer = Timer.new()
		preview_timer.one_shot = true
		preview_timer.connect("timeout", self, "do_update_preview")
	add_child(preview_timer)

func update_rendering_time(t : int) -> void:
	.update_rendering_time(t)
	update_title()

func update_title() -> void:
	if rendering_time < 0:
		title = generator.get_type_name()
	else:
		title = generator.get_type_name()+" ("+str(rendering_time)+"ms)"

func update_node() -> void:
	# Clean node
	clear_all_slots()
	save_preview_widget()
	for c in get_children():
		remove_child(c)
		c.free()
	rect_size = Vector2(0, 0)
	# Show or hide the close button
	show_close = generator.can_be_deleted()
	# Rebuild node
	update_title()
	# Regex for labels
	var regex = RegEx.new()
	regex.compile("^(\\d+):(.*)")
	# Inputs
	var inputs = generator.get_input_defs()
	var index = -1
	for i in range(inputs.size()):
		var input = inputs[i]
		var enable_left = false
		var color_left = Color(0.5, 0.5, 0.5)
		var type_left = 0
		if typeof(input) == TYPE_DICTIONARY:
			enable_left = true
			if mm_io_types.types.has(input.type):
				color_left = mm_io_types.types[input.type].color
				type_left = mm_io_types.types[input.type].slot_type
		var label = ""
		if input.has("label"):
			label = input.label
		var result = regex.search(label)
		if result:
			index = result.get_string(1).to_int()-1
			label = result.get_string(2)
		else:
			index += 1
		var hsizer : HBoxContainer
		while get_child_count() < index:
			hsizer = HBoxContainer.new()
			hsizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
			add_child(hsizer)
			hsizer.add_child(Control.new())
			set_slot(get_child_count()-1, false, 0, Color(), false, 0, Color())
		hsizer = HBoxContainer.new()
		hsizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
		add_child(hsizer)
		if label != "":
			var label_widget : Label = Label.new()
			label_widget.text = label
			hsizer.add_child(label_widget)
		else:
			var control : Control = Control.new()
			control.rect_min_size.y = 16
			hsizer.add_child(control)
		set_slot(index, enable_left, type_left, color_left, false, 0, Color())
	var input_names_width : int = 0
	for c in get_children():
		var width = c.get_child(0).rect_size.x
		if width > input_names_width:
			input_names_width = width
	if input_names_width > 0:
		input_names_width += 3
	for c in get_children():
		c.get_child(0).rect_min_size.x = input_names_width
	# Parameters
	controls = {}
	index = -1
	for p in generator.get_parameter_defs():
		if !p.has("name") or !p.has("type"):
			continue
		var control = create_parameter_control(p)
		if control != null:
			var label = p.name
			control.name = label
			controls[control.name] = control
			if p.has("label"):
				label = p.label
			var result = regex.search(label)
			if result:
				index = result.get_string(1).to_int()-1
				label = result.get_string(2)
			else:
				index += 1
			var hsizer : HBoxContainer
			while index >= get_child_count():
				hsizer = HBoxContainer.new()
				hsizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
				var empty_control : Control = Control.new()
				empty_control.rect_min_size.x = input_names_width
				hsizer.add_child(empty_control)
				add_child(hsizer)
			hsizer = get_child(index)
			if label != "":
				var label_widget = Label.new()
				label_widget.text = label
				label_widget.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
				hsizer.add_child(label_widget)
			control.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
			if hsizer != null:
				hsizer.add_child(control)
	initialize_properties()
	# Outputs
	var outputs = generator.get_output_defs()
	var button_width = 0
	output_count = outputs.size()
	for i in range(output_count):
		var output = outputs[i]
		var enable_right : bool = true
		var color_right : Color = Color(0.5, 0.5, 0.5)
		var type_right : int = 0
		assert(typeof(output) == TYPE_DICTIONARY)
		assert(output.has("type"))
		enable_right = true
		if mm_io_types.types.has(output.type):
			color_right = mm_io_types.types[output.type].color
			type_right = mm_io_types.types[output.type].slot_type
		set_slot(i, is_slot_enabled_left(i), get_slot_type_left(i), get_slot_color_left(i), enable_right, type_right, color_right)
		var hsizer : HBoxContainer
		while i >= get_child_count():
			hsizer = HBoxContainer.new()
			hsizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
			add_child(hsizer)
		hsizer = get_child(i)
		if hsizer.get_child_count() == 0:
			hsizer.rect_min_size.y = 16
	if !outputs.empty():
		for i in range(output_count, get_child_count()):
			var hsizer : HBoxContainer = get_child(i)
			var empty_control : Control = Control.new()
			empty_control.rect_min_size.x = button_width
			hsizer.add_child(empty_control)
	# Edit buttons
	if generator.is_editable():
		var edit_buttons = preload("res://material_maker/nodes/edit_buttons.tscn").instance()
		add_child(edit_buttons)
		edit_buttons.connect_buttons(self, "edit_generator", "load_generator", "save_generator")
		set_slot(edit_buttons.get_index(), false, 0, Color(0.0, 0.0, 0.0), false, 0, Color(0.0, 0.0, 0.0))
	# Preview
	restore_preview_widget()

func edit_generator() -> void:
	if generator.has_method("edit"):
		generator.edit(self)

func update_generator(shader_model) -> void:
	generator.set_shader_model(shader_model)
	update_node()
	get_parent().set_need_save()

func load_generator() -> void:
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		if config_cache.has_section_key("path", "template"):
			dialog.current_dir = config_cache.get_value("path", "template")
	dialog.connect("file_selected", self, "do_load_generator")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func do_load_generator(file_name : String) -> void:
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		config_cache.set_value("path", "template", file_name.get_base_dir())
	var new_generator = null
	if file_name.ends_with(".mmn"):
		var file = File.new()
		if file.open(file_name, File.READ) == OK:
			new_generator = MMGenShader.new()
			new_generator.set_shader_model(parse_json(file.get_as_text()))
			file.close()
	else:
		new_generator = mm_loader.load_gen(file_name)
	if new_generator != null:
		var gen_name = mm_loader.generator_name_from_path(file_name)
		if gen_name != "":
			new_generator.model = gen_name
		var parent_generator = generator.get_parent()
		parent_generator.replace_generator(generator, new_generator)
		generator = new_generator
		update_node()

func save_generator() -> void:
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		if config_cache.has_section_key("path", "template"):
			dialog.current_dir = config_cache.get_value("path", "template")
	dialog.connect("file_selected", self, "do_save_generator")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func do_save_generator(file_name : String) -> void:
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		config_cache.set_value("path", "template", file_name.get_base_dir())
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		var data = generator.serialize()
		data.name = file_name.get_file().get_basename()
		data.node_position = { x=0, y=0 }
		file.store_string(JSON.print(data, "\t", true))
		file.close()
		mm_loader.update_predefined_generators()

func on_clicked_output(index : int) -> void:
	if preview_index == index:
		preview_index = -1
		preview.visible = false
		remove_child(preview)
		rect_size = Vector2(0, 0)
	else:
		preview_index = index
		if preview.visible:
			update_preview()
		else:
# warning-ignore:void_assignment
			var status = update_preview(get_child(0).rect_size.x)
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
	update()

func update_preview(size : int = 0) -> void:
	if preview_index == -1:
		return
	if size != 0:
		preview_size = size
	preview_timer.start(0.2)

func do_update_preview() -> void:
	if !preview.visible:
		add_child(preview)
		move_child(preview, preview_position)
		preview.visible = true
	preview.set_generator(generator, preview_index)
	preview.rect_min_size = Vector2(preview_size, preview_size)
