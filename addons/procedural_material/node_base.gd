tool
extends GraphNode

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
		elif o is OptionButton:
			set(o.name, o.selected)
			o.connect("item_selected", self, "_on_value_changed", [ o.name ])
		elif o is CheckBox:
			set(o.name, o.pressed)
			o.connect("toggled", self, "_on_value_changed", [ o.name ])
		elif o is ColorPickerButton:
			set(o.name, o.color)
			o.connect("color_changed", self, "_on_color_changed", [ o.name ])

func get_seed():
	return int(offset.x)*3+int(offset.y)*5

func update_property_widgets():
	for o in property_widgets:
		if o is LineEdit:
			o.text = str(get(o.name))
		elif o is SpinBox:
			o.value = get(o.name)
		elif o is OptionButton:
			o.selected = get(o.name)
		elif o is CheckBox:
			o.pressed = get(o.name)
		elif o is ColorPickerButton:
			o.color = get(o.name)

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
	for i in range(5):
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
	return e

func generate_shader(slot = 0):
	var code
	code = "shader_type canvas_item;\n\n"
	var file = File.new()
	file.open("res://addons/procedural_material/common.shader", File.READ)
	code += file.get_as_text()
	code += "\n"
	for c in get_parent().get_children():
		if c is GraphNode:
			c.reset()
	var src_code = get_shader_code("UV", slot)
	var shader_code = src_code.defs
	shader_code += "void fragment() {\n"
	shader_code += src_code.code
	shader_code += "COLOR = vec4("+src_code.rgb+", 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

func serialize():
	var type = get_script().resource_path
	type = type.right(type.find_last("/")+1)
	type = type.left(type.find_last("."))
	var data = { name=name, type=type, node_position={x=offset.x, y=offset.y} }
	for w in property_widgets:
		var v = w.name
		data[v] = serialize_element(get(v))
	return data

func deserialize(data):
	if data.has("node_position"):
		offset = Vector2(data.node_position.x, data.node_position.y)
	for w in property_widgets:
		var variable = w.name
		if data.has(variable):
			var value = deserialize_element(data[variable])
			set(variable, value)
	update_property_widgets()

# Generic code for convolution nodes

func get_shader_code_convolution(convolution, uv):
	var rv = { defs="", code="" }
	var src = get_source()
	if src == null:
		return rv
	var variant_index = generated_variants.find(uv)
	var need_defs = false
	if generated_variants.empty():
		need_defs = true
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		var inputs_code = ""
		var code = "vec3 %s_%d_rgb = " % [ name, variant_index ]
		if convolution.has("translate"):
			code += "vec3(%.9f, %.9f, %.9f)+" % [ convolution.translate.x, convolution.translate.y, convolution.translate.z ]
		if convolution.has("scale"):
			code += "%.9f*" % [ convolution.scale ]
		if convolution.has("normalize") and convolution.normalize:
			code += "normalize"
		code += "("
		if convolution.has("translate_before_normalize"):
			code += "vec3(%.9f, %.9f, %.9f)+" % [ convolution.translate_before_normalize.x, convolution.translate_before_normalize.y, convolution.translate_before_normalize.z ]
		if convolution.has("scale_before_normalize"):
			code += "%.9f*" % [ convolution.scale_before_normalize ]
		code += "("
		var first = true
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var i = 5*(dy+2)+dx+2
				var coef = convolution.kernel[i]
				if typeof(coef) == TYPE_REAL:
					coef = Vector3(coef, coef, coef)
				if typeof(coef) != TYPE_VECTOR3 or coef == Vector3(0, 0, 0):
					continue
				var src_code = src.get_shader_code(uv+"+vec2(%.9f, %.9f)" % [ dx*convolution.epsilon, dy*convolution.epsilon ])
				if need_defs:
					rv.defs = src_code.defs
					need_defs = false
				inputs_code += src_code.code
				if !first:
					code += "+"
				else:
					first = false
				code += "vec3(%.9f, %.9f, %.9f)*(%s)"% [ coef.x, coef.y, coef.z, src_code.rgb ]
		code += "));"
		rv.code += inputs_code + code
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv

