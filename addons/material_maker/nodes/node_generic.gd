tool
extends "res://addons/material_maker/node_base.gd"

export(String) var model = null setget set_model
var model_data = null
var uses_seed = false

func _ready():
	show_close = true
	connect("offset_changed", self, "_on_offset_changed")

func set_model(m):
	if m != null and typeof(m) == TYPE_STRING:
		var file = File.new()
		var file_name = m
		if !file.file_exists(file_name):
			file_name = "res://addons/material_maker/nodes/%s.mmn" % [ m ]
		if file.file_exists(file_name):
			if file.open(file_name, File.READ) != OK:
				return
			var data = file.get_as_text()
			var status = validate_json(data)
			file.close()
			if status != "":
				print("Incorrect node description (%s)" % status)
				return
			data = parse_json(data)
			model = m
			update_node(data)
	else:
		print("set_model error "+str(m))

func update_node(data):
	if typeof(data) != TYPE_DICTIONARY:
		return
	if !data.has("name"):
		return
	# Clean node
	parameters = {}
	var custom_node_buttons = null
	for c in get_children():
		if c.name != "CustomNodeButtons":
			remove_child(c)
			c.queue_free()
		else:
			custom_node_buttons = c
	# Rebuild node
	title = data.name
	model_data = data
	uses_seed = false
	if model_data.has("instance") and model_data.instance.find("$(seed)"):
		uses_seed = true
	if model_data.has("parameters") and typeof(model_data.parameters) == TYPE_ARRAY:
		var control_list = []
		var sizer = null
		for p in model_data.parameters:
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
				parameters[p.name] = 0.5*(p.min+p.max)
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
			if control != null:
				var label = p.name
				control.name = label
				control_list.append(control)
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
		initialize_properties(control_list)
	else:
		model_data.parameters = []
	if model_data.has("inputs") and typeof(model_data.inputs) == TYPE_ARRAY:
		for i in range(model_data.inputs.size()):
			var input = model_data.inputs[i]
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
	else:
		model_data.inputs = []
	if model_data.has("outputs") and typeof(model_data.outputs) == TYPE_ARRAY:
		for i in range(model_data.outputs.size()):
			var output = model_data.outputs[i]
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
	else:
		model_data.outputs = []
	if custom_node_buttons != null:
		move_child(custom_node_buttons, get_child_count()-1)

func replace_input(string, input, type, src, context = null):
	var required_defs = ""
	var required_code = ""
	var keyword = "$%s(" % input
	while true:
		var position = string.find(keyword)
		if position == -1:
			break
		var parenthesis_level = 0
		var parameter_begin = position+keyword.length()
		var parameter_end = -1
		for i in range(parameter_begin, string.length()):
			if string[i] == '(':
				parenthesis_level += 1
			elif string[i] == ')':
				if parenthesis_level == 0:
					parameter_end = i
					break
				else:
					parenthesis_level -= 1
		if parameter_end != -1:
			var uv = string.substr(parameter_begin, parameter_end-parameter_begin)
			var src_code = src.get_shader_code(uv)
			required_defs += src_code.defs
			required_code += src_code.code
			string = string.replace(string.substr(position, parameter_end-position+1), src_code[type])
		else:
			print("syntax error")
			break
	return { string=string, defs=required_defs, code=required_code }

func replace_variable(string, variable, value):
	string = string.replace("$(%s)" % variable, value)
	return string

func subst(string, uv = "", context = null):
	var required_defs = ""
	var required_code = ""
	string = replace_variable(string, "name", name)
	string = replace_variable(string, "seed", str(get_seed()))
	if uv != "":
		string = replace_variable(string, "uv", uv)
	if model_data.has("parameters") and typeof(model_data.parameters) == TYPE_ARRAY:
		for p in model_data.parameters:
			if !p.has("name") or !p.has("type"):
				continue
			var value = parameters[p.name]
			var value_string = null
			if p.type == "float":
				value_string = "%.9f" % value
			elif p.type == "size":
				value_string = "%.9f" % pow(2, value+p.first)
			elif p.type == "enum":
				value_string = p.values[value].value
			elif p.type == "color":
				value_string = "vec4(%.9f, %.9f, %.9f, %.9f)" % [ value.r, value.g, value.b, value.a ]
			if value_string != null:
				string = replace_variable(string, p.name, value_string)
	if model_data.has("inputs") and typeof(model_data.inputs) == TYPE_ARRAY:
		for i in range(model_data.inputs.size()):
			var input = model_data.inputs[i]
			var source = get_source(i)
			if source == null:
				string = replace_variable(string, input.name, input.default)
			else:
				var result = replace_input(string, input.name, input.type, source, context)
				string = result.string
				required_defs += result.defs
				required_code += result.code
	return { string=string, defs=required_defs, code=required_code }

func _get_shader_code(uv, slot = 0):
	var output_info = [ { field="rgba", type="vec4" }, { field="rgb", type="vec3" }, { field="f", type="float" } ]
	var rv = { defs="", code="" }
	var variant_string = uv+","+str(slot)
	if model_data != null and model_data.has("outputs") and model_data.outputs.size() > slot:
		var output = model_data.outputs[slot]
		if model_data.has("instance") && generated_variants.empty():
			rv.defs = subst(model_data.instance).string
		var variant_index = generated_variants.find(variant_string)
		if variant_index == -1:
			variant_index = generated_variants.size()
			generated_variants.append(variant_string)
			for t in output_info:
				if output.has(t.field):
					var subst_output = subst(output[t.field], uv, rv)
					rv.defs += subst_output.defs
					rv.code += subst_output.code
					rv.code += "%s %s_%d_%d_%s = %s;\n" % [ t.type, name, slot, variant_index, t.field, subst_output.string ]
		for t in output_info:
			if output.has(t.field):
				rv[t.field] = "%s_%d_%d_%s" % [ name, slot, variant_index, t.field ]
	return rv

func get_globals():
	var list = .get_globals()
	if typeof(model_data) == TYPE_DICTIONARY and model_data.has("global") and list.find(model_data.global) == -1:
		list.append(model_data.global)
	return list

func _on_offset_changed():
	update_shaders()

func serialize():
	var return_value = .serialize()
	return_value.type = model
	return return_value
