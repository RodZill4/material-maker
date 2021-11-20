extends MMGraphNodeBase
class_name MMGraphNodeGeneric

var controls = {}
var ignore_parameter_change = ""
var output_count = 0

var preview : ColorRect
var preview_timer : Timer = Timer.new()

func _ready() -> void:
	add_to_group("updated_from_locale")

func _draw() -> void:
	._draw()
	if generator != null and generator.preview >= 0 and get_connection_output_count() > 0:
		var conn_pos = get_connection_output_position(generator.preview)
		conn_pos /= get_global_transform().get_scale()
		draw_texture(preload("res://material_maker/icons/output_preview.tres"), conn_pos-Vector2(8, 8), get_color("title_color"))

func set_generator(g : MMGenBase) -> void:
	.set_generator(g)
	generator.connect("parameter_changed", self, "on_parameter_changed")
	update_node()

static func update_control_from_parameter(parameter_controls : Dictionary, p : String, v) -> void:
	if parameter_controls.has(p):
		var o = parameter_controls[p]
		if o is Control and o.filename == "res://material_maker/widgets/float_edit/float_edit.tscn":
			o.value = v
		elif o is HSlider:
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
		elif o is Control and o.filename == "res://material_maker/widgets/image_picker_button/image_picker_button.tscn":
			o.do_set_image_path(v)
		elif o is Control and o.filename == "res://material_maker/widgets/gradient_editor/gradient_editor.tscn":
			var gradient : MMGradient = MMGradient.new()
			gradient.deserialize(v)
			o.value = gradient
		elif o is Button and o.filename == "res://material_maker/widgets/curve_edit/curve_edit.tscn":
			var curve : MMCurve = MMCurve.new()
			curve.deserialize(v)
			o.value = curve
		elif o is Button and o.filename == "res://material_maker/widgets/polygon_edit/polygon_edit.tscn":
			var polygon : MMPolygon = MMPolygon.new()
			polygon.deserialize(v)
			o.value = polygon
		else:
			print("unsupported widget "+str(o))

func on_parameter_changed(p : String, v) -> void:
	if ignore_parameter_change == p:
		return
	if p == "__update_all__":
		update_node()
	else:
		update_control_from_parameter(controls, p, v)
		update_parameter_tooltip(p, v)
	get_parent().set_need_save()

static func initialize_controls_from_generator(control_list, generator, object) -> void:
	var parameter_names = []
	for p in generator.get_parameter_defs():
		parameter_names.push_back(p.name)
	for c in control_list.keys():
		if parameter_names.find(c) == -1:
			continue
		var o = control_list[c]
		if generator.parameters.has(c):
			object.on_parameter_changed(c, generator.get_parameter(c))
		if o is Control and o.filename == "res://material_maker/widgets/float_edit/float_edit.tscn":
			o.connect("value_changed", object, "_on_value_changed", [ o.name ])
		elif o is LineEdit:
			o.connect("text_changed", object, "_on_text_changed", [ o.name ])
		elif o is SizeOptionButton:
			o.connect("size_value_changed", object, "_on_value_changed", [ o.name ])
		elif o is OptionButton:
			o.connect("item_selected", object, "_on_value_changed", [ o.name ])
		elif o is CheckBox:
			o.connect("toggled", object, "_on_value_changed", [ o.name ])
		elif o is ColorPickerButton:
			o.connect("color_changed", object, "_on_color_changed", [ o.name ])
		elif o is Control and o.filename == "res://material_maker/widgets/file_picker_button/file_picker_button.tscn":
			o.connect("file_selected", object, "_on_file_changed", [ o.name ])
		elif o is Control and o.filename == "res://material_maker/widgets/image_picker_button/image_picker_button.tscn":
			o.connect("on_file_selected", object, "_on_file_changed", [ o.name ])
		elif o is Control and o.filename == "res://material_maker/widgets/gradient_editor/gradient_editor.tscn":
			o.connect("updated", object, "_on_gradient_changed", [ o.name ])
		elif o is Button and o.filename == "res://material_maker/widgets/curve_edit/curve_edit.tscn":
			o.connect("updated", object, "_on_curve_changed", [ o.name ])
		elif o is Button and o.filename == "res://material_maker/widgets/polygon_edit/polygon_edit.tscn":
			o.connect("updated", object, "_on_polygon_changed", [ o.name ])
		else:
			print("unsupported widget "+str(o))

func initialize_properties() -> void:
	initialize_controls_from_generator(controls, generator, self)

func update_parameter_tooltip(p : String, v):
	if ! controls.has(p):
		return
	for d in generator.get_parameter_defs():
		if d.name == p:
			controls[p].hint_tooltip = get_parameter_tooltip(d, v)
			break

func set_generator_parameter(variable : String, value):
	var old_value = MMType.serialize_value(generator.get_parameter(variable))
	ignore_parameter_change = variable
	generator.set_parameter(variable, value)
	ignore_parameter_change = ""
	get_parent().set_need_save()
	update_parameter_tooltip(variable, str(value))
	if get_parent().get("undoredo") != null:
		var node_hier_name = generator.get_hier_name()
		var undo_command = { type="setparam", node=node_hier_name, param=variable, value=old_value }
		var redo_command = { type="setparam", node=node_hier_name, param=variable, value=MMType.serialize_value(generator.get_parameter(variable)) }
		get_parent().undoredo.add("Set parameter value", [ undo_command ], [ redo_command ], true)

func _on_text_changed(new_text, variable : String) -> void:
	set_generator_parameter(variable, new_text)

func _on_value_changed(new_value, variable : String) -> void:
	set_generator_parameter(variable, new_value)

func _on_color_changed(new_color, variable : String) -> void:
	set_generator_parameter(variable, new_color)

func _on_file_changed(new_file, variable : String) -> void:
	set_generator_parameter(variable, new_file)

func _on_gradient_changed(new_gradient, variable : String) -> void:
	set_generator_parameter(variable, new_gradient.duplicate())

func _on_curve_changed(new_curve, variable : String) -> void:
	set_generator_parameter(variable, new_curve.duplicate())

func _on_polygon_changed(new_polygon, variable : String) -> void:
	set_generator_parameter(variable, new_polygon.duplicate())

static func get_parameter_tooltip(p : Dictionary, parameter_value = null) -> String:
	var tooltip : String
	if p.has("shortdesc"):
		tooltip = TranslationServer.translate(p.shortdesc)+" ("+TranslationServer.translate(p.name)+")"
		if parameter_value != null:
			tooltip += " = "+str(parameter_value)
		if p.has("longdesc"):
			tooltip += "\n"+TranslationServer.translate(p.longdesc)
	elif p.has("longdesc"):
		tooltip += TranslationServer.translate(p.longdesc)
	return wrap_string(tooltip)

static func create_parameter_control(p : Dictionary, accept_float_expressions : bool) -> Control:
	var control = null
	if !p.has("type"):
		return null
	if p.type == "float":
		control = preload("res://material_maker/widgets/float_edit/float_edit.tscn").instance()
		if ! accept_float_expressions:
			control.float_only = true
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
		control.rect_min_size.x = 80
	elif p.type == "boolean":
		control = CheckBox.new()
	elif p.type == "color":
		control = ColorPickerButton.new()
		control.set_script(preload("res://material_maker/widgets/color_picker_button/color_picker_button.gd"))
		control.rect_min_size.x = 40
	elif p.type == "gradient":
		control = preload("res://material_maker/widgets/gradient_editor/gradient_editor.tscn").instance()
	elif p.type == "curve":
		control = preload("res://material_maker/widgets/curve_edit/curve_edit.tscn").instance()
	elif p.type == "polygon":
		control = preload("res://material_maker/widgets/polygon_edit/polygon_edit.tscn").instance()
	elif p.type == "polyline":
		control = preload("res://material_maker/widgets/polygon_edit/polygon_edit.tscn").instance()
		control.set_closed(false)
	elif p.type == "string":
		control = LineEdit.new()
		control.rect_min_size.x = 80
	elif p.type == "image_path":
		control = preload("res://material_maker/widgets/image_picker_button/image_picker_button.tscn").instance()
	elif p.type == "file":
		control = preload("res://material_maker/widgets/file_picker_button/file_picker_button.tscn").instance()
		control.rect_min_size.x = 80
		if p.has("filters"):
			for f in p.filters:
				control.add_filter(f)
	control.hint_tooltip = get_parameter_tooltip(p)
	return control

func save_preview_widget() -> void:
	if preview != null and preview.is_inside_tree():
		preview.get_parent().remove_child(preview)
	if preview_timer != null:
		preview_timer.stop()

func restore_preview_widget() -> void:
	if generator == null or generator.preview == -1:
		if preview != null and preview.is_inside_tree():
			preview.get_parent().remove_child(preview)
		rect_size = Vector2(0, 0)
	else:
		if preview == null:
			preview = preload("res://material_maker/panels/preview_2d/preview_2d_node.tscn").instance()
			preview.shader_context_defs = get_parent().shader_context_defs
			preview_timer.one_shot = true
			preview_timer.connect("timeout", self, "do_update_preview")
			preview.add_child(preview_timer)
		var child_count = get_child_count()
		var preview_parent = get_child(child_count-1)
		while preview_parent is Container:
			child_count = preview_parent.get_child_count()
			preview_parent = preview_parent.get_child(child_count-1)
		if preview_parent == null:
			preview_parent = Control.new()
			get_child(get_child_count()-1).add_child(preview_parent)
		preview_parent.add_child(preview)
		preview.visible = false
		update_preview()
		rect_size = Vector2(100, 96)

func update_preview() -> void:
	if generator == null or generator.preview == -1:
		return
	preview_timer.start(0.2)

func do_update_preview() -> void:
	if !preview.is_inside_tree():
		restore_preview_widget()
	preview.set_generator(generator, generator.preview, true)
	var pos = Vector2(0, 0)
	var parent = preview.get_parent()
	while parent != self:
		pos += parent.rect_position
		parent = parent.get_parent()
	preview.rect_position = Vector2(18, 24)-pos
	preview.rect_size = rect_size-Vector2(38, 28)
	preview.visible = true

func update_rendering_time(t : int) -> void:
	.update_rendering_time(t)
	update_title()

func update_title() -> void:
	title = TranslationServer.translate(generator.get_type_name())
	if rendering_time > 0:
		title += " ("+str(rendering_time)+"ms)"
	if generator == null or generator.minimized:
		var font : Font = get_font("default_font")
		var max_title_width = 28
		if font.get_string_size(title).x > max_title_width:
			for i in range(1, title.length()-1):
				if font.get_string_size(title.left(i)+"...").x > max_title_width:
					title = title.left(i-1)+"..."
					break

func update_node() -> void:
	# Clean node
	clear_all_slots()
	save_preview_widget()
	for c in get_children():
		remove_child(c)
		c.free()
	# Show or hide the close button
	show_close = generator.can_be_deleted()
	# Rebuild node
	update_title()
	# Resize to minimum
	rect_size = Vector2(0, 0)
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
		if !generator.minimized:
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
		if !generator.minimized and label != "":
			var label_widget : Label = Label.new()
			label_widget.text = label
			hsizer.add_child(label_widget)
		else:
			var control : Control = Control.new()
			control.rect_min_size.y = 12
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
	if !generator.minimized:
		controls = {}
		index = -1
		var previous_focus = null
		var first_focus = null
		for p in generator.get_parameter_defs():
			if !p.has("name") or !p.has("type"):
				continue
			var control = create_parameter_control(p, generator.accept_float_expressions())
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
				if previous_focus != null:
					previous_focus.focus_next = control.get_path()
					control.focus_previous = previous_focus.get_path()
				else:
					first_focus = control
				previous_focus = control
		if first_focus != null:
			previous_focus.focus_next = first_focus.get_path()
			first_focus.focus_previous = previous_focus.get_path()
		initialize_properties()
	# Outputs
	var outputs = generator.get_output_defs()
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
			hsizer.rect_min_size.y = 12
	# Edit buttons
	if generator.is_editable():
		for theme in ["frame", "selectedframe"]:
			add_stylebox_override(theme, null)
		var edit_buttons = preload("res://material_maker/nodes/edit_buttons.tscn").instance()
		add_child(edit_buttons)
		edit_buttons.connect_buttons(self, "edit_generator", "load_generator", "save_generator")
		set_slot(edit_buttons.get_index(), false, 0, Color(0.0, 0.0, 0.0), false, 0, Color(0.0, 0.0, 0.0))
	if generator.minimized:
		rect_size = Vector2(96, 96)
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
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		if config_cache.has_section_key("path", "template"):
			dialog.current_dir = config_cache.get_value("path", "template")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		do_load_generator(files[0])

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
		call_deferred("update_node")

func save_generator() -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		if config_cache.has_section_key("path", "template"):
			dialog.current_dir = config_cache.get_value("path", "template")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		do_save_generator(files[0])

func do_save_generator(file_name : String) -> void:
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		config_cache.set_value("path", "template", file_name.get_base_dir())
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		var data = generator.serialize()
		data.name = file_name.get_file().get_basename()
		data.node_position = { x=0, y=0 }
		for k in [ "uids", "export_paths" ]:
			if data.has(k):
				data.erase(k)
		file.store_string(JSON.print(data, "\t", true))
		file.close()
		mm_loader.update_predefined_generators()

func on_clicked_output(index : int) -> void:
	if generator.preview == index:
		generator.preview = -1
		disconnect("mouse_entered", self, "on_mouse_entered")
		disconnect("mouse_exited", self, "on_mouse_exited")
	else:
		generator.preview = index
		connect("mouse_entered", self, "on_mouse_entered")
		connect("mouse_exited", self, "on_mouse_exited")
		update_preview()
	restore_preview_widget()
	update()

func on_mouse_entered():
	if !generator.minimized:
		preview.visible = false

func on_mouse_exited():
	if !generator.minimized and !get_global_rect().has_point(get_global_mouse_position()):
		preview.visible = true


func update_from_locale() -> void:
	update_title()
