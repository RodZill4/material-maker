tool
extends GraphNode

# A class that provides the shader node interface for a node port
class OutPort:
	var node = null
	var port = null
	
	func get_shader_code(uv):
		return node.get_shader_code(uv, port)

	func generate_shader():
		return node.generate_shader(port)
		
	func get_textures():
		return node.get_textures()

var generated = false
var generated_variants = []

var property_widgets = []

const Types = preload("res://addons/material_maker/types/types.gd")

func _ready():
	pass

func initialize_properties(object_list):
	property_widgets = object_list
	for o in object_list:
		if o == null:
			print("error in node "+name)
		elif o is LineEdit:
			set(o.name, float(o.text))
			o.connect("text_changed", self, "_on_text_changed", [ o.name ])
		elif o is SpinBox:
			set(o.name, o.value)
			o.connect("value_changed", self, "_on_value_changed", [ o.name ])
		elif o is HSlider:
			set(o.name, o.value)
			o.connect("value_changed", self, "_on_value_changed", [ o.name ])
		elif o is OptionButton:
			set(o.name, o.selected)
			o.connect("item_selected", self, "_on_value_changed", [ o.name ])
		elif o is CheckBox:
			set(o.name, o.pressed)
			o.connect("toggled", self, "_on_value_changed", [ o.name ])
		elif o is ColorPickerButton:
			set(o.name, o.color)
			o.connect("color_changed", self, "_on_color_changed", [ o.name ])
		elif o is Control and o.filename == "res://addons/material_maker/widgets/gradient_editor.tscn":
			set(o.name, o.value)
			o.connect("updated", self, "_on_gradient_changed", [ o.name ])
		else:
			print("unsupported widget "+str(o))

func get_seed():
	return int(offset.x)*3+int(offset.y)*5

func update_property_widgets():
	for o in property_widgets:
		if o is LineEdit:
			o.text = str(get(o.name))
		elif o is SpinBox:
			o.value = get(o.name)
		elif o is HSlider:
			o.value = get(o.name)
		elif o is OptionButton:
			o.selected = get(o.name)
		elif o is CheckBox:
			o.pressed = get(o.name)
		elif o is ColorPickerButton:
			o.color = get(o.name)
		elif o is Control and o.filename == "res://addons/material_maker/widgets/gradient_editor.tscn":
			o.value = get(o.name)
		else:
			print("Failed to update "+o.name)

func update_shaders():
	get_parent().send_changed_signal()

func _on_text_changed(new_text, variable):
	set(variable, float(new_text))
	update_shaders()

func _on_value_changed(new_value, variable):
	set(variable, new_value)
	update_shaders()

func _on_color_changed(new_color, variable):
	set(variable, new_color)
	update_shaders()

func _on_gradient_changed(new_gradient, variable):
	set(variable, new_gradient)
	update_shaders()

func get_source(index = 0):
	for c in get_parent().get_connection_list():
		if c.to == name and c.to_port == index:
			if c.from_port == 0:
				return get_parent().get_node(c.from)
			else:
				var out_port = OutPort.new()
				out_port.node = get_parent().get_node(c.from)
				out_port.port = c.from_port
				return out_port
	return null

func get_source_f(source):
	var rv
	if source.has("rgb"):
		rv = "dot("+source.rgb+", vec3(1.0))/3.0"
	elif source.has("f"):
		rv = source.f
	else:
		rv = "***error***"
	return rv
	
func get_source_rgb(source):
	var rv
	if source.has("rgb"):
		rv = source.rgb
	elif source.has("f"):
		rv = "vec3("+source.f+")"
	else:
		rv = "***error***"
	return rv

func reset():
	generated = false
	generated_variants = []

func get_shader_code(uv, slot = 0):
	var rv
	if slot == 0:
		rv = _get_shader_code(uv)
	else:
		rv = _get_shader_code(uv, slot)
	if !rv.has("f"):
		if rv.has("rgb"):
			rv.f = "(dot("+rv.rgb+", vec3(1.0))/3.0)"
		else:
			rv.f = "0.0"
	if !rv.has("rgb"):
		if rv.has("f"):
			rv.rgb = "vec3("+rv.f+")"
		else:
			rv.f = "vec3(0.0)"
	return rv

func get_textures():
	var list = {}
	for i in range(get_connection_input_count()):
		var source = get_source(i)
		if source != null:
			var source_list = source.get_textures()
			for k in source_list.keys():
				list[k] = source_list[k]
	return list

func serialize_element(e):
	if typeof(e) == TYPE_COLOR:
		return { type= "Color", r=e.r, g=e.g, b=e.b, a=e.a }
	return e
	
func deserialize_element(e):
	if typeof(e) == TYPE_DICTIONARY:
		if e.has("type") and e.type == "Color":
			return Color(e.r, e.g, e.b, e.a)
	elif typeof(e) == TYPE_ARRAY:
		var gradient = preload("res://addons/material_maker/types/gradient.gd").new()
		gradient.deserialize(e)
		return gradient
	return e

func generate_shader(slot = 0):
	# Reset all nodes
	for c in get_parent().get_children():
		if c is GraphNode:
			c.reset()
	return get_parent().renderer.generate_shader(get_shader_code("UV", slot))

func serialize():
	var type = get_script().resource_path
	type = type.right(type.find_last("/")+1)
	type = type.left(type.find_last("."))
	var data = { name=name, type=type, node_position={x=offset.x, y=offset.y} }
	for w in property_widgets:
		var v = w.name
		data[v] = Types.serialize_value(get(v)) # serialize_element(get(v))
	return data

func deserialize(data):
	if data.has("node_position"):
		offset = Vector2(data.node_position.x, data.node_position.y)
	for w in property_widgets:
		var variable = w.name
		if data.has(variable):
			var value = Types.deserialize_value(data[variable]) #deserialize_element(data[variable])
			set(variable, value)
	update_property_widgets()

# Render targets again for multipass filters

func rerender_targets():
	for c in get_parent().get_connection_list():
		if c.from == name:
			var node = get_parent().get_node(c.to)
			if node != null and node is GraphNode:
				node._rerender()

func _rerender():
	rerender_targets()

# Generic code for convolution nodes

func get_convolution_shader(convolution):
	var shader_code
	shader_code  = "shader_type canvas_item;\n"
	shader_code += "uniform sampler2D input_tex;\n"
	shader_code += "void fragment() {\n"
	shader_code += "vec3 color = vec3(0.0);\n"
	for dy in range(-convolution.y, convolution.y+1):
		for dx in range(-convolution.x, convolution.x+1):
			var i = (2*convolution.x+1)*(dy+convolution.y)+dx+convolution.x
			var coef = convolution.kernel[i]
			if typeof(coef) == TYPE_INT:
				coef = float(coef)
			if typeof(coef) == TYPE_REAL:
				coef = Vector3(coef, coef, coef)
			if typeof(coef) != TYPE_VECTOR3 or coef == Vector3(0, 0, 0):
				continue
			shader_code += "color += vec3(%.9f, %.9f, %.9f) * textureLod(input_tex, UV+vec2(%.9f, %.9f), %.9f).rgb;\n" % [ coef.x, coef.y, coef.z, dx*convolution.epsilon, dy*convolution.epsilon, convolution.epsilon ]
	if convolution.has("scale_before_normalize"):
		shader_code += "color *= %.9f;\n" % [ convolution.scale_before_normalize ]
	if convolution.has("translate_before_normalize"):
		shader_code += "color += vec3(%.9f, %.9f, %.9f);\n" % [ convolution.translate_before_normalize.x, convolution.translate_before_normalize.y, convolution.translate_before_normalize.z ]
	if convolution.has("normalize") and convolution.normalize:
		shader_code += "color = normalize(color);\n"
	if convolution.has("scale"):
		shader_code += "color *= %.9f;\n" % [ convolution.scale ]
	if convolution.has("translate"):
		shader_code += "color += vec3(%.9f, %.9f, %.9f);\n" % [ convolution.translate.x, convolution.translate.y, convolution.translate.z ]
	shader_code += "COLOR = vec4(color, 1.0);\n"
	shader_code += "}\n"
	return shader_code;

func get_shader_code_convolution(src, convolution, uv):
	var rv = { defs="", code="" }
	var variant_index = generated_variants.find(uv)
	var need_defs = false
	if generated_variants.empty():
		need_defs = true
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		var inputs_code = ""
		var code = "vec3 %s_%d_rgb = " % [ name, variant_index ]
		rv.code += inputs_code + code
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv

