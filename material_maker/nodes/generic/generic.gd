extends MMGraphNodeBase
class_name MMGraphNodeGeneric


var controls = {}
var ignore_parameter_change = ""
var output_count = 0

var preview : ColorRect
var preview_timer : Timer = Timer.new()
var generic_button : NodeButton


const GENERIC_ICON : Texture = preload("res://material_maker/icons/add.tres")


func _ready() -> void:
	generic_button = add_button(GENERIC_ICON, true)
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

func update():
	if generator != null and generator.has_method("is_generic") and generator.is_generic():
		generic_button.hidden = false
	else:
		generic_button.hidden = true
	.update()

var next_generic : int = 1

func on_node_button(b : NodeButton, event : InputEvent) -> bool:
	if b == generic_button:
		if ! event is InputEventMouseButton or ! event.pressed:
			return false
		match event.button_index:
			BUTTON_LEFT:
				generator.set_generic_size(generator.generic_size+1)
				update_node()
			BUTTON_RIGHT:
				get_generic_minimum()
				var popup : PopupPanel = PopupPanel.new()
				var spinbox : SpinBox = SpinBox.new()
				spinbox.min_value = get_generic_minimum()
				spinbox.max_value = 32
				spinbox.value = generator.generic_size
				popup.add_child(spinbox)
				add_child(popup)
				popup.connect("popup_hide", popup, "queue_free")
				spinbox.connect("value_changed", self, "update_generic")
				popup.connect("tree_exited", self, "commit_generic")
				next_generic = generator.generic_size
				popup.popup(Rect2(get_global_mouse_position(), popup.get_minimum_size()))
				accept_event()
	else:
		return .on_node_button(b, event)
	return false

func get_generic_minimum():
	var generic_inputs = generator.get_generic_range(generator.shader_model.inputs, "name")
	var generic_input_count = generic_inputs.last-generic_inputs.first
	var rv : int = 0
	for i in generator.generic_size:
		for p in generic_input_count:
			if generator.get_source(generic_inputs.first+i*generic_input_count+p) != null:
				rv = i+1
				break
	if rv < 1:
		rv = 1
	return rv

func update_generic(size : float) -> void:
	next_generic = int(size)

func commit_generic() -> void:
	generator.set_generic_size(next_generic)
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
			o.connect("value_changed_undo", object, "_on_float_value_changed", [ o.name ])
		elif o is LineEdit:
			o.connect("text_changed", object, "_on_text_changed", [ o.name ])
		elif o is SizeOptionButton:
			o.connect("size_value_changed", object, "_on_value_changed", [ o.name ])
		elif o is OptionButton:
			o.connect("item_selected", object, "_on_value_changed", [ o.name ])
		elif o is CheckBox:
			o.connect("toggled", object, "_on_value_changed", [ o.name ])
		elif o is ColorPickerButton:
			o.connect("color_changed_undo", object, "_on_color_changed", [ o.name ])
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

func set_generator_parameter_ext(variable : String, value, old_value, merge_undo : bool = false):
	ignore_parameter_change = variable
	generator.set_parameter(variable, value)
	ignore_parameter_change = ""
	get_parent().set_need_save()
	update_parameter_tooltip(variable, str(value))
	if old_value != null and get_parent().get("undoredo") != null:
		var serialized_value = MMType.serialize_value(value)
		if typeof(old_value) != typeof(serialized_value) or old_value != serialized_value:
			var node_hier_name = generator.get_hier_name()
			var undo_command = { type="setparams", node=node_hier_name, params={ variable:old_value } }
			var redo_command = { type="setparams", node=node_hier_name, params={ variable:serialized_value } }
			get_parent().undoredo.add("Set parameter value", [ undo_command ], [ redo_command ], merge_undo)

func set_generator_parameter(variable : String, value, merge_undo : bool = false):
	var old_value = MMType.serialize_value(generator.get_parameter(variable))
	set_generator_parameter_ext(variable, value, old_value, merge_undo)

func _on_text_changed(new_text, variable : String) -> void:
	set_generator_parameter(variable, new_text)

func _on_value_changed(new_value, variable : String) -> void:
	set_generator_parameter(variable, new_value)

func _on_float_value_changed(new_value, merge_undo : bool = false, variable : String = "") -> void:
	set_generator_parameter(variable, new_value, merge_undo)

func _on_color_changed(new_color, old_value, variable : String) -> void:
	set_generator_parameter_ext(variable, new_color, MMType.serialize_value(old_value))

func _on_file_changed(new_file, variable : String) -> void:
	set_generator_parameter(variable, new_file)

func _on_gradient_changed(new_gradient, merge_undo : bool = false, variable : String = "") -> void:
	set_generator_parameter(variable, new_gradient.duplicate(), merge_undo)

func _on_curve_changed(new_curve, old_value, variable : String) -> void:
	set_generator_parameter_ext(variable, new_curve, MMType.serialize_value(old_value))

func _on_polygon_changed(new_polygon, old_value, variable : String) -> void:
	set_generator_parameter_ext(variable, new_polygon, MMType.serialize_value(old_value))

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
	preview_disconnect()
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
	preview_connect()
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
		if label != "":
			var label_widget : Label = Label.new()
			label_widget.text = label
			hsizer.add_child(label_widget)
		else:
			var control : Control = Control.new()
			control.rect_min_size.y = 25 if !generator.minimized else 12
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
			hsizer.rect_min_size.y = 25 if !generator.minimized else 12
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

func load_generator() -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	if mm_globals.config.has_section_key("path", "template"):
		dialog.current_dir = mm_globals.config.get_value("path", "template")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		do_load_generator(files[0])

func do_load_generator(file_name : String) -> void:
	mm_globals.config.set_value("path", "template", file_name.get_base_dir())
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
	if mm_globals.config.has_section_key("path", "template"):
		dialog.current_dir = mm_globals.config.get_value("path", "template")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		do_save_generator(files[0])

func do_save_generator(file_name : String) -> void:
	mm_globals.config.set_value("path", "template", file_name.get_base_dir())
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

func on_clicked_output(index : int, with_shift : bool) -> bool:
	if .on_clicked_output(index, with_shift):
		return true
	if ! with_shift:
		if generator.preview == index:
			generator.preview = -1
			preview_disconnect()
		else:
			generator.preview = index
			update_preview()
		restore_preview_widget()
		update()
		return true
	return false

func preview_connect_node(node : Control) -> void:
	if node is Control and !node.is_connected("mouse_entered", self, "on_mouse_entered"):
		if node is Popup:
			node.connect("mouse_entered", self, "on_mouse_entered")
			node.connect("popup_hide", self, "on_mouse_exited")
		else:
			node.connect("mouse_entered", self, "on_mouse_entered")
			node.connect("mouse_exited", self, "on_mouse_exited")
		for child in node.get_children():
			preview_connect_node(child)

func preview_disconnect_node(node : Control) -> void:
	if node is Control and node.is_connected("mouse_entered", self, "on_mouse_entered"):
		if node is Popup:
			node.disconnect("mouse_entered", self, "on_mouse_entered")
			node.disconnect("popup_hide", self, "on_mouse_exited")
		else:
			node.disconnect("mouse_entered", self, "on_mouse_entered")
			node.disconnect("mouse_exited", self, "on_mouse_exited")
		for child in node.get_children():
			preview_disconnect_node(child)

func preview_connect() -> void:
	if !get_tree().is_connected("node_added", self, "on_node_added"):
		get_tree().connect("node_added", self, "on_node_added")
	preview_connect_node(self)

func preview_disconnect() -> void:
	if get_tree().is_connected("node_added", self, "on_node_added"):
		get_tree().disconnect("node_added", self, "on_node_added")
	preview_disconnect_node(self)

func on_node_added(n : Node):
	#print("Adding "+str(n)+", parent = "+str(n.get_parent()))
	if n is Control and is_a_parent_of(n):
		preview_connect_node(n)

func on_mouse_entered():
	if !generator.minimized:
		preview.visible = false

func on_mouse_exited():
	if !generator.minimized:
		var preview_parent = preview.get_parent()
		# Fake move of preview in hierarchy, so it's shown in front of whatever
		# control that has been created recently
		preview_parent.move_child(preview, preview_parent.get_child_count()-1)
		preview.visible = true

func update_from_locale() -> void:
	update_title()
