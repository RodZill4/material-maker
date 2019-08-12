tool
extends MMGenBase
class_name MMGenShader

var model_data = null
var generated_variants = []

func set_model_data(data: Dictionary):
	model_data = data

func initialize(data: Dictionary):
	if data.has("name"):
		name = data.name
	if data.has("parameters"):
		parameters = data.parameters

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
			src_code = src.get_shader_code(uv)
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
			elif p.type == "gradient":
				value_string = p.name+"_gradient_fct"
			if value_string != null:
				string = replace_variable(string, p.name, value_string)
	if model_data.has("inputs") and typeof(model_data.inputs) == TYPE_ARRAY:
		for i in range(model_data.inputs.size()):
			var input = model_data.inputs[i]
			var source = get_source(i)
			var result = replace_input(string, context, input.name, input.type, source, input.default)
			string = result.string
			required_defs += result.defs
			required_code += result.code
	return { string=string, defs=required_defs, code=required_code }

func _get_shader_code(uv, slot = 0, context = MMGenContext.new()):
	if context == null:
		context = {}
	var output_info = [ { field="rgba", type="vec4" }, { field="rgb", type="vec3" }, { field="f", type="float" } ]
	var rv = { defs="", code="" }
	var variant_string = uv+","+str(slot)
	if model_data != null and model_data.has("outputs") and model_data.outputs.size() > slot:
		var output = model_data.outputs[slot]
		rv.defs = ""
		if model_data.has("instance") && !context.has_variant(self):
			rv.defs += subst(model_data.instance, context).string
		for p in model_data.parameters:
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
