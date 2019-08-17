tool
extends MMGenBase
class_name MMGenShader

var shader_model : Dictionary = {}
var generated_variants = []

func get_type():
	return "shader"

func get_type_name():
	if shader_model.has("name"): 
		return shader_model.name
	return .get_type_name()

func get_parameter_defs():
	if shader_model == null or !shader_model.has("parameters"):
		return []
	else:
		return shader_model.parameters

func set_shader_model(data: Dictionary):
	shader_model = data
	init_parameters()

func find_keyword_call(string, keyword):
	var search_string = "$%s(" % keyword
	var position = string.find(search_string)
	if position == -1:
		return null
	var parenthesis_level = 0
	var parameter_begin = position+search_string.length()
	var parameter_end = -1
	for i in range(parameter_begin, string.length()):
		if string[i] == '(':
			parenthesis_level += 1
		elif string[i] == ')':
			if parenthesis_level == 0:
				return string.substr(parameter_begin, i-parameter_begin)
			parenthesis_level -= 1
	return ""

func replace_input(string, context, input, type, src, default):
	var required_defs = ""
	var required_code = ""
	while true:
		var uv = find_keyword_call(string, input)
		if uv == null:
			break
		elif uv == "":
			print("syntax error")
			break
		var src_code
		if src == null:
			src_code = subst(default, "(%s)" % uv)
		else:
			print(src.to_str())
			src_code = src.generator.get_shader_code(uv, src.output_index, context)
			src_code.string = src_code[type]
		required_defs += src_code.defs
		required_code += src_code.code
		string = string.replace("$%s(%s)" % [ input, uv ], src_code.string)
	return { string=string, defs=required_defs, code=required_code }

func is_word_letter(l):
	return "azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN1234567890_".find(l) != -1

func replace_variable(string, variable, value):
	string = string.replace("$(%s)" % variable, value)
	var keyword_size = variable.length()+1
	var new_string = ""
	while !string.empty():
		var pos = string.find("$"+variable)
		if pos == -1:
			new_string += string
			break
		new_string += string.left(pos)
		string = string.right(pos)
		if string.empty() or !is_word_letter(string[0]):
			new_string += value
		else:
			new_string += "$"+variable
		string = string.right(keyword_size)
	return new_string

func subst(string, context, uv = ""):
	var required_defs = ""
	var required_code = ""
	string = replace_variable(string, "name", name)
	string = replace_variable(string, "seed", str(get_seed()))
	if uv != "":
		string = replace_variable(string, "uv", "("+uv+")")
	if shader_model.has("parameters") and typeof(shader_model.parameters) == TYPE_ARRAY:
		for p in shader_model.parameters:
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
			elif p.type == "gradient":
				value_string = p.name+"_gradient_fct"
			if value_string != null:
				string = replace_variable(string, p.name, value_string)
	if shader_model.has("inputs") and typeof(shader_model.inputs) == TYPE_ARRAY:
		for i in range(shader_model.inputs.size()):
			var input = shader_model.inputs[i]
			var source = get_source(i)
			var result = replace_input(string, context, input.name, input.type, source, input.default)
			string = result.string
			required_defs += result.defs
			required_code += result.code
	return { string=string, defs=required_defs, code=required_code }

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	var output_info = [ { field="rgba", type="vec4" }, { field="rgb", type="vec3" }, { field="f", type="float" } ]
	var rv = { defs="", code="" }
	var variant_string = uv+","+str(output_index)
	if shader_model != null and shader_model.has("outputs") and shader_model.outputs.size() > output_index:
		var output = shader_model.outputs[output_index]
		rv.defs = ""
		if shader_model.has("instance") && !context.has_variant(self):
			rv.defs += subst(shader_model.instance, context).string
		for p in shader_model.parameters:
			if p.type == "gradient":
				var g = parameters[p.name]
				if !(g is MMGradient):
					g = MMGradient.new()
					g.deserialize(parameters[p.name])
				rv.defs += g.get_shader(p.name+"_gradient_fct")
		var variant_index = context.get_variant(self, variant_string)
		if variant_index == -1:
			variant_index = context.get_variant(self, variant_string)
			generated_variants.append(variant_string)
			for t in output_info:
				if output.has(t.field):
					var subst_output = subst(output[t.field], context, uv)
					rv.defs += subst_output.defs
					rv.code += subst_output.code
					rv.code += "%s %s_%d_%d_%s = %s;\n" % [ t.type, name, output_index, variant_index, t.field, subst_output.string ]
		for t in output_info:
			if output.has(t.field):
				rv[t.field] = "%s_%d_%d_%s" % [ name, output_index, variant_index, t.field ]
	return rv

func get_globals():
	var list = .get_globals()
	if typeof(shader_model) == TYPE_DICTIONARY and shader_model.has("global") and list.find(shader_model.global) == -1:
		list.append(shader_model.global)
	return list
