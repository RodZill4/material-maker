extends MMGraphNodeBase
class_name MMGraphNodeGeneric


var controls = {}
var ignore_parameter_change = ""
var output_count = 0

var preview : ColorRect
var preview_timer : Timer = Timer.new()
var generic_button : TextureButton


const GENERIC_ICON : Texture2D = preload("res://material_maker/icons/add_generic.tres")


func _ready() -> void:
	super._ready()
	add_to_group("updated_from_locale")

func init_buttons():
	super.init_buttons()
	generic_button = add_button(GENERIC_ICON, self.on_generic_pressed, self.generic_button_create_popup)
	generic_button.tooltip_text = tr("Add more ports/parameters (left mouse button) / Variadic node menu (right mouse button)")

func on_generic_pressed():
	update_generic(generator.generic_size+1)

func generic_button_create_popup():
	var popup_menu : PopupMenu = PopupMenu.new()
	var minimum = get_generic_minimum()
	if minimum < generator.generic_size:
		popup_menu.add_item(str(minimum), minimum)
		popup_menu.add_separator()
	for c in range(generator.generic_size+1, generator.generic_size+4):
		popup_menu.add_item(str(c), c)
	add_child(popup_menu)
	popup_menu.connect("popup_hide",Callable(popup_menu,"queue_free"))
	popup_menu.connect("id_pressed",Callable(self,"update_generic"))
	mm_globals.popup_menu(popup_menu, self)


func set_generator(g : MMGenBase) -> void:
	super.set_generator(g)
	generator.parameter_changed.connect(self.on_parameter_changed)
	update_node()

func update():
	if generator != null and generator.has_method("is_generic") and generator.is_generic():
		generic_button.visible = true
	else:
		generic_button.visible = false
	super.update()

func get_generic_minimum():
	var rv : int = 0
	var generic_inputs = generator.get_generic_range(generator.shader_model.inputs, "name")
	var generic_input_count = generic_inputs.last-generic_inputs.first
	var generic_outputs = generator.get_generic_range(generator.shader_model.outputs, "type", 1)
	var generic_output_count = generic_outputs.last-generic_outputs.first
	for i in generator.generic_size:
		for p in generic_input_count:
			if generator.get_source(generic_inputs.first+i*generic_input_count+p) != null:
				rv = i+1
				break
		if rv == i+1:
			continue
		for p in generic_output_count:
			if ! generator.get_targets(generic_outputs.first+i*generic_output_count+p).is_empty():
				rv = i+1
				break
	if rv < 1:
		rv = 1
	return rv

func update_generic(generic_size : int) -> void:
	if generic_size == generator.generic_size:
		return
	await get_tree().process_frame
	var generator_hier_name : String = generator.get_hier_name()
	var parent_hier_name : String = generator.get_parent().get_hier_name()
	var before_connections = []
	var after_connections = []
	var generic_inputs = generator.get_generic_range(generator.shader_model.inputs, "name")
	var gi_count = generic_inputs.last-generic_inputs.first
	var first_after_gi = generic_inputs.first+gi_count*generator.generic_size
	var gi_ports_offset = gi_count*(generic_size-generator.generic_size)
	for i in range(first_after_gi, generator.get_input_defs().size()):
		var source = generator.get_source(i)
		if source != null:
			before_connections.append({from=source.generator.name, from_port=source.output_index, to=generator.name, to_port=i})
			after_connections.append({from=source.generator.name, from_port=source.output_index, to=generator.name, to_port=i+gi_ports_offset})
	var generic_outputs = generator.get_generic_range(generator.shader_model.outputs, "type", 1)
	var go_count = generic_outputs.last-generic_outputs.first
	var first_after_go = generic_outputs.first+go_count*generator.generic_size
	var go_ports_offset = go_count*(generic_size-generator.generic_size)
	for o in range(first_after_go, generator.get_output_defs().size()):
		for target in generator.get_targets(o):
			before_connections.append({from=generator.name, from_port=o, to=target.generator.name, to_port=target.input_index})
			after_connections.append({from=generator.name, from_port=o+go_ports_offset, to=target.generator.name, to_port=target.input_index})

	var undo_actions = [
		{ type="remove_connections", parent=parent_hier_name, connections=after_connections },
		{ type="setgenericsize", node=generator_hier_name, size=generator.generic_size },
		{ type="add_to_graph", parent=parent_hier_name, generators=[], connections=before_connections }
	]
	var redo_actions = [
		{ type="remove_connections", parent=parent_hier_name, connections=before_connections },
		{ type="setgenericsize", node=generator_hier_name, size=generic_size },
		{ type="add_to_graph", parent=parent_hier_name, generators=[], connections=after_connections }
	]
	get_parent().undoredo.add("Disconnect nodes", undo_actions, redo_actions)
	for c in redo_actions:
		get_parent().undoredo_command(c)

static func update_control_from_parameter(parameter_controls : Dictionary, p : String, v) -> void:
	if parameter_controls.has(p):
		var o = parameter_controls[p]
		if o is Control and o.scene_file_path == "res://material_maker/widgets/float_edit/float_edit.tscn":
			o.set_value(v)
		elif o is HSlider:
			o.value = v
		elif o is LineEdit:
			o.text = v
		elif o is SizeOptionButton:
			o.size_value = v
		elif o is OptionButton:
			o.selected = v
		elif o is CheckBox:
			o.button_pressed = v
		elif o is ColorPickerButton:
			o.color = MMType.deserialize_value(v)
		elif o is Control and o.scene_file_path == "res://material_maker/widgets/file_picker_button/file_picker_button.tscn":
			o.path = v
		elif o is Control and o.scene_file_path == "res://material_maker/widgets/image_picker_button/image_picker_button.tscn":
			o.do_set_image_path(v)
		elif o is Control and o.scene_file_path == "res://material_maker/widgets/gradient_editor/gradient_edit.tscn":
			var gradient : MMGradient = MMGradient.new()
			gradient.deserialize(v)
			o.value = gradient
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/curve_edit/curve_edit.tscn":
			var curve : MMCurve = MMCurve.new()
			curve.deserialize(v)
			o.value = curve
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/polygon_edit/polygon_edit.tscn":
			var polygon : MMPolygon = MMPolygon.new()
			polygon.deserialize(v)
			o.value = polygon
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/splines_edit/splines_edit.tscn":
			var splines : MMSplines = MMSplines.new()
			splines.deserialize(v)
			o.value = splines
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/pixels_edit/pixels_edit.tscn":
			var pixels : MMPixels = MMPixels.new()
			pixels.deserialize(v)
			o.value = pixels
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/lattice_edit/lattice_edit.tscn":
			var lattice : MMLattice = MMLattice.new()
			lattice.deserialize(v)
			o.value = lattice
		else:
			print("unsupported widget "+str(o))

func on_parameter_changed(p : String, v) -> void:
	if ignore_parameter_change == p:
		return
	if p == "__update_all__":
		update_node()
	else:
		MMGraphNodeGeneric.update_control_from_parameter(controls, p, v)
		update_parameter_tooltip(p, v)
	get_parent().set_need_save()

static func initialize_controls_from_generator(control_list, gen, object) -> void:
	var parameter_names = []
	for p in gen.get_parameter_defs():
		parameter_names.push_back(p.name)
	for c in control_list.keys():
		if parameter_names.find(c) == -1:
			continue
		var o = control_list[c]
		if gen.parameters.has(c):
			object.on_parameter_changed(c, gen.get_parameter(c))
		if o is Control and o.scene_file_path == "res://material_maker/widgets/float_edit/float_edit.tscn":
			o.connect("value_changed_undo",Callable(object,"_on_float_value_changed").bind( o.name ))
		elif o is LineEdit:
			o.connect("text_changed",Callable(object,"_on_text_changed").bind( o.name ))
		elif o is SizeOptionButton:
			o.connect("size_value_changed",Callable(object,"_on_value_changed").bind( o.name ))
		elif o is OptionButton:
			o.connect("item_selected",Callable(object,"_on_value_changed").bind( o.name ))
		elif o is CheckBox:
			o.connect("toggled",Callable(object,"_on_value_changed").bind( o.name ))
		elif o is ColorPickerButton:
			o.connect("color_changed_undo",Callable(object,"_on_color_changed").bind( o.name ))
		elif o is Control and o.scene_file_path == "res://material_maker/widgets/file_picker_button/file_picker_button.tscn":
			o.connect("file_selected",Callable(object,"_on_file_changed").bind( o.name ))
		elif o is Control and o.scene_file_path == "res://material_maker/widgets/image_picker_button/image_picker_button.tscn":
			o.connect("on_file_selected",Callable(object,"_on_file_changed").bind( o.name ))
		elif o is Control and o.scene_file_path == "res://material_maker/widgets/gradient_editor/gradient_edit.tscn":
			o.connect("updated",Callable(object,"_on_gradient_changed").bind( o.name ))
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/curve_edit/curve_edit.tscn":
			o.connect("updated",Callable(object,"_on_curve_changed").bind( o.name ))
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/polygon_edit/polygon_edit.tscn":
			o.connect("updated",Callable(object,"_on_polygon_changed").bind( o.name ))
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/splines_edit/splines_edit.tscn":
			o.connect("updated",Callable(object,"_on_splines_changed").bind( o.name ))
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/pixels_edit/pixels_edit.tscn":
			o.connect("updated",Callable(object,"_on_pixels_changed").bind( o.name ))
		elif o is Button and o.scene_file_path == "res://material_maker/widgets/lattice_edit/lattice_edit.tscn":
			o.connect("updated",Callable(object,"_on_lattice_changed").bind( o.name ))
		else:
			print("unsupported widget "+str(o))

func initialize_properties() -> void:
	MMGraphNodeGeneric.initialize_controls_from_generator(controls, generator, self)

func update_parameter_tooltip(p : String, v):
	if ! controls.has(p):
		return
	for d in generator.get_parameter_defs():
		if d.name == p:
			controls[p].tooltip_text = MMGraphNodeGeneric.get_parameter_tooltip(d, v)
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

func _on_splines_changed(new_splines, old_value, variable : String) -> void:
	set_generator_parameter_ext(variable, new_splines, MMType.serialize_value(old_value))

func _on_pixels_changed(new_pixels, old_value, variable : String) -> void:
	set_generator_parameter_ext(variable, new_pixels, MMType.serialize_value(old_value))

func _on_lattice_changed(new_lattice, old_value, variable : String) -> void:
	set_generator_parameter_ext(variable, new_lattice, MMType.serialize_value(old_value))

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
		control = preload("res://material_maker/widgets/float_edit/float_edit.tscn").instantiate()
		if ! accept_float_expressions:
			control.float_only = true
		control.min_value = p.min
		control.max_value = p.max
		control.step = 0.005 if !p.has("step") else p.step
		if p.has("default"):
			control.value = p.default
		control.custom_minimum_size.x = 60
	elif p.type == "size":
		control = SizeOptionButton.new()
		control.min_size = p.first
		control.max_size = p.last
		control.size_value = p.first if !p.has("default") else p.default
	elif p.type == "enum":
		control = preload("res://material_maker/widgets/option_edit/option_edit.tscn").instantiate()
		for i in range(p.values.size()):
			var value = p.values[i]
			control.add_item(value.name)
			control.selected = 0 if !p.has("default") else p.default
		control.custom_minimum_size.x = 80
	elif p.type == "boolean":
		control = CheckBox.new()
		control.theme_type_variation = "MM_NodeCheckbox"
	elif p.type == "color":
		control = ColorPickerButton.new()
		control.set_script(preload("res://material_maker/widgets/color_picker_button/color_picker_button.gd"))
		control.custom_minimum_size.x = 40
	elif p.type == "gradient":
		control = preload("res://material_maker/widgets/gradient_editor/gradient_edit.tscn").instantiate()
		control.custom_minimum_size.x = 80
	elif p.type == "curve":
		control = preload("res://material_maker/widgets/curve_edit/curve_edit.tscn").instantiate()
	elif p.type == "polygon":
		control = preload("res://material_maker/widgets/polygon_edit/polygon_edit.tscn").instantiate()
	elif p.type == "polyline":
		control = preload("res://material_maker/widgets/polygon_edit/polygon_edit.tscn").instantiate()
		control.set_closed(false)
	elif p.type == "splines":
		control = preload("res://material_maker/widgets/splines_edit/splines_edit.tscn").instantiate()
	elif p.type == "pixels":
		control = preload("res://material_maker/widgets/pixels_edit/pixels_edit.tscn").instantiate()
	elif p.type == "lattice":
		control = preload("res://material_maker/widgets/lattice_edit/lattice_edit.tscn").instantiate()
	elif p.type == "string":
		control = LineEdit.new()
		control.custom_minimum_size.x = 80
	elif p.type == "image_path":
		control = preload("res://material_maker/widgets/image_picker_button/image_picker_button.tscn").instantiate()
	elif p.type == "file":
		control = preload("res://material_maker/widgets/file_picker_button/file_picker_button.tscn").instantiate()
		control.custom_minimum_size.x = 80
		if p.has("filters"):
			for f in p.filters:
				control.add_filter(f)
	control.tooltip_text = get_parameter_tooltip(p)
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
		size = Vector2(0, 0)
	else:
		if preview == null:
			preview = preload("res://material_maker/panels/preview_2d/preview_2d_node.tscn").instantiate()
			preview.shader_context_defs = get_parent().shader_context_defs
			preview_timer.one_shot = true
			preview_timer.connect("timeout", Callable(self, "do_update_preview"))
		if preview_timer.get_parent():
			preview_timer.get_parent().remove_child(preview_timer)
		if preview.get_parent():
			preview.get_parent().remove_child(preview)
		preview.add_child(preview_timer)
		var child_count = get_child_count()
		#var preview_parent = get_child(child_count-1)
		#while preview_parent is Container:
			#child_count = preview_parent.get_child_count()
			#preview_parent = preview_parent.get_child(child_count-1)
		#if preview_parent == null:
			#preview_parent = Control.new()
			#get_child(get_child_count()-1).add_child(preview_parent)
		#preview_parent.add_child(preview)
		var preview_parent: Control = null
		if has_node("PreviewParent"):
			preview_parent = get_node("PreviewParent")
		else:
			preview_parent = Control.new()
			preview_parent.name = "PreviewParent"
			add_child(preview_parent)
		preview_parent.add_child(preview)
		preview.visible = false
		update_preview()
		size = Vector2(100, 96)

func update_preview() -> void:
	if generator == null or generator.preview == -1:
		return
	if preview and not preview.is_inside_tree():
		restore_preview_widget()
	if preview_timer.is_inside_tree():
		preview_timer.start(0.2)

func do_update_preview() -> void:
	preview.set_generator(generator, generator.preview, true)

	var scale_modifier : float = get_global_transform().get_scale().x
	var titlebar_stylebox :=  get_theme_stylebox("titlebar", "GraphNode")
	var title_bar_height := get_titlebar_hbox().size.y +titlebar_stylebox.content_margin_bottom+titlebar_stylebox.content_margin_top
	var margin: int = 8
	preview.global_position = Vector2(margin, title_bar_height+margin)*scale_modifier + global_position
	preview.size = size - Vector2.ONE*margin*2 - Vector2(0,title_bar_height)
	preview.visible = true

func update_title() -> void:
	title = TranslationServer.translate(generator.get_type_name())
	if generator == null or generator.minimized:
		var font : Font = get_theme_font("default_font")
		var max_title_width = 28
		if font.get_string_size(title).x > max_title_width:
			for i in range(1, title.length()-1):
				if font.get_string_size(title.left(i)+"...").x > max_title_width:
					title = title.left(i-1)+"..."
					break

func update_node() -> void:
	var minimum_line_height = get_theme_constant("minimum_line_height", "MM_Node") if has_theme_constant("minimum_line_height", "MM_Node") else 25
	# Clean node
	clear_all_slots()
	save_preview_widget()
	for c in get_children():
		remove_child(c)
		c.free()
	# Show or hide the close button
	close_button.visible = generator.can_be_deleted()
	# Rebuild node
	update_title()
	# Resize to minimum
	size = Vector2(0, 0)
	# Regex for labels
	var regex = RegEx.new()
	regex.compile("^(\\d+):(.*)")
	# Inputs
	var inputs = generator.get_input_defs()
	var index = -1
	var input_labels := []
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
		while get_child_count() <= index:
			hsizer = HBoxContainer.new()
			hsizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
			hsizer.custom_minimum_size.y = minimum_line_height
			add_child(hsizer)
			set_slot(get_child_count()-1, false, 0, Color(), false, 0, Color())
			# Add empty input label
			var empty_control : Control = Control.new()
			empty_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			input_labels.append(empty_control)
			hsizer.add_child(empty_control)
			# Add empty parameter label
			empty_control = Control.new()
			empty_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hsizer.add_child(empty_control)
		if label != "":
			var label_widget : Label = Label.new()
			label_widget.text = label
			label_widget.theme_type_variation = "MM_NodePropertyLabel"
			var replace : Control = hsizer.get_child(0)
			hsizer.remove_child(replace)
			replace.free()
			input_labels.erase(replace)
			hsizer.add_child(label_widget)
			hsizer.move_child(label_widget, 0)
			input_labels.append(label_widget)
		set_slot(index, enable_left, type_left, color_left, false, 0, Color())
	
	# Parameters
	if !generator.minimized:
		controls = {}
		index = -1
		var previous_focus = null
		var first_focus = null
		var property_labels := []
		for p in generator.get_parameter_defs():
			if !p.has("name") or !p.has("type"):
				continue
			var control = MMGraphNodeGeneric.create_parameter_control(p, generator.accept_float_expressions())
			if control != null:
				var label : String = p.name
				var first : bool = true
				control.name = label
				controls[control.name] = control
				if p.has("label"):
					label = p.label
				var result = regex.search(label)
				if result:
					index = result.get_string(1).to_int()-1
					label = result.get_string(2)
					if index < get_child_count() and get_child(index).get_child_count() > 2:
						first = false
				elif label.substr(0, 2) == "-:":
					label = label.right(-2)
					first = false
				else:
					index += 1
				var hsizer : HBoxContainer
				while index >= get_child_count():
					hsizer = HBoxContainer.new()
					hsizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
					add_child(hsizer)
					# Add empty input label
					var empty_control : Control = Control.new()
					empty_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
					input_labels.append(empty_control)
					hsizer.add_child(empty_control)
					# Add empty parameter label
					empty_control = Control.new()
					empty_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
					hsizer.add_child(empty_control)
				hsizer = get_child(index)
				hsizer.custom_minimum_size.y = minimum_line_height
				if label != "":
					var label_widget = Label.new()
					label_widget.text = label
					property_labels.append(label_widget)
					label_widget.theme_type_variation = "MM_NodePropertyLabel"
					if first:
						var replace : Control = hsizer.get_child(1)
						hsizer.remove_child(replace)
						if replace in property_labels:
							property_labels.erase(replace)
						replace.free()
						hsizer.add_child(label_widget)
						hsizer.move_child(label_widget, 1)
					else:
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
		
		var param_label_width = property_labels.reduce(func(accum, label): return max(accum, label.size.x), 0)
		param_label_width = min(100, param_label_width)
		
		var input_label_width : int = 0
		input_label_width = get_children().reduce(
			func(accum, child): return max(child.get_child(0).size.x, accum) if child.get_child_count() else accum
			, 0)
		if input_label_width > 0 and not property_labels.is_empty():
			input_label_width += 10
		
		for r in get_children():
			if not (r.get_child(0) is Label or r.get_child(1) is Label):
				continue
			var input_label : Control = r.get_child(0)
			input_label.custom_minimum_size.x = input_label_width
			if input_label is Label:
				input_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			var param_label : Control = r.get_child(1)
			param_label.custom_minimum_size.x = param_label_width
			if param_label is Label:
				param_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		
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
			hsizer.custom_minimum_size.y = minimum_line_height if !generator.minimized else 12
	
	# Edit buttons
	if generator.is_editable():
		for theme_stylebox in ["titlebar", "titlebar_selected"]:
			remove_theme_stylebox_override(theme_stylebox)
		var edit_buttons = preload("res://material_maker/nodes/edit_buttons.tscn").instantiate()
		add_child(edit_buttons)
		edit_buttons.connect_buttons(self, "edit_generator", "load_generator", "save_generator")
		set_slot(edit_buttons.get_index(), false, 0, Color(0.0, 0.0, 0.0), false, 0, Color(0.0, 0.0, 0.0))
	if generator.minimized:
		size = Vector2(96, 96)
	# Preview
	restore_preview_widget()


func load_generator() -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	if mm_globals.config.has_section_key("path", "template"):
		dialog.current_dir = mm_globals.config.get_value("path", "template")
	var files = await dialog.select_files()
	if files.size() > 0:
		do_load_generator(files[0])

func do_load_generator(file_name : String) -> void:
	mm_globals.config.set_value("path", "template", file_name.get_base_dir())
	var new_generator = null
	if file_name.ends_with(".mmn"):
		var file : FileAccess = FileAccess.open(file_name, FileAccess.READ)
		if file != null:
			new_generator = MMGenShader.new()
			var test_json_conv = JSON.new()
			test_json_conv.parse(file.get_as_text())
			new_generator.set_shader_model(test_json_conv.get_data())

	else:
		new_generator = await mm_loader.load_gen(file_name)
	if new_generator != null:
		var gen_name = mm_loader.generator_name_from_path(file_name)
		if gen_name != "":
			new_generator.model = gen_name
		var parent_generator = generator.get_parent()
		parent_generator.replace_generator(generator, new_generator)
		generator = new_generator
		update_node.call_deferred()

func save_generator() -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	#dialog.custom_minimum_size = Vector2i(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	if mm_globals.config.has_section_key("path", "template"):
		dialog.current_dir = mm_globals.config.get_value("path", "template")
	var files = await dialog.select_files()
	if files.size() > 0:
		MMGraphNodeGeneric.do_save_generator(files[0], generator)

static func do_save_generator(file_name : String, gen : MMGenBase) -> void:
	mm_globals.config.set_value("path", "template", file_name.get_base_dir())
	mm_loader.save_gen(file_name, gen)

func on_clicked_output(index : int, with_shift : bool) -> bool:
	if super.on_clicked_output(index, with_shift):
		return true
	if ! with_shift:
		if generator.preview == index:
			generator.preview = -1
		else:
			generator.preview = index
			update_preview()
		restore_preview_widget()
		update()
		return true
	return false


func _input(_event:InputEvent) -> void:
	if not generator.minimized and preview:
		var rect := get_global_rect()
		var margin := 8
		rect.position += Vector2.ONE*margin
		rect.size -= Vector2.ONE*margin*2
		if rect.has_point(get_global_mouse_position()):
			preview.visible = false
		else:
			var preview_parent = preview.get_parent()
			# Fake move of preview in hierarchy, so it's shown in front of whatever
			# control that has been created recently
			if preview_parent:
				preview_parent.move_child(preview, preview_parent.get_child_count()-1)
			preview.visible = true


func update_from_locale() -> void:
	update_title()
