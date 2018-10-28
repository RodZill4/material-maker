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
				for i in p.values.size():
					var value = p.values[i]
					control.add_item(value.name)
					control.selected = 0 if !p.has("default") else p.default
			elif p.type == "boolean":
				control = CheckBox.new()
			if control != null:
				var label = p.name
				control.name = label
				control_list.append(control)
				var sizer = HBoxContainer.new()
				sizer.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
				if p.has("label"):
					label = p.label
				if label != "":
					var label_widget = Label.new()
					label_widget.text = label
					label_widget.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
					sizer.add_child(label_widget)
				control.size_flags_horizontal = SIZE_EXPAND | SIZE_FILL
				sizer.add_child(control)
				add_child(sizer)
		initialize_properties(control_list)
	else:
		model_data.parameters = []
	if model_data.has("outputs") and typeof(model_data.outputs) == TYPE_ARRAY:
		for i in model_data.outputs.size():
			var output = model_data.outputs[i]
			var enable_right = false
			var color_right = Color(0.5, 0.5, 0.5)
			if typeof(output) == TYPE_DICTIONARY:
				if output.has("rgb"):
					enable_right = true
					color_right = Color(0.5, 0.5, 1.0)
				elif output.has("f"):
					enable_right = true
			set_slot(i, false, 0, color_right, enable_right, 0, color_right)
	else:
		model_data.outputs = []
	if custom_node_buttons != null:
		move_child(custom_node_buttons, get_child_count()-1)

func subst(string, uv = ""):
	string = string.replace("$(name)", name)
	string = string.replace("$(seed)", str(get_seed()))
	string = string.replace("$(uv)", uv)
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
			if value_string != null:
				string = string.replace("$(%s)" % p.name, value_string)
	return string

func _get_shader_code(uv, slot = 0):
	var rv = { defs="", code="" }
	var variant_string = uv+","+str(slot)
	if model_data != null and model_data.has("outputs") and model_data.outputs.size() > slot:
		var output = model_data.outputs[slot]
		if model_data.has("instance") && generated_variants.empty():
			rv.defs = subst(model_data.instance)
		var variant_index = generated_variants.find(variant_string)
		if variant_index == -1:
			variant_index = generated_variants.size()
			generated_variants.append(variant_string)
			if output.has("rgb"):
				rv.code += "vec3 %s_%d_%d_rgb = %s;\n" % [ name, slot, variant_index, subst(output.rgb, uv) ]
			if output.has("f"):
				rv.code += "float %s_%d_%d_f = %s;\n" % [ name, slot, variant_index, subst(output.f, uv) ]
		if output.has("rgb"):
			rv.rgb = "%s_%d_%d_rgb" % [ name, slot, variant_index ]
		if output.has("f"):
			rv.f = "%s_%d_%d_f" % [ name, slot, variant_index ]
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
