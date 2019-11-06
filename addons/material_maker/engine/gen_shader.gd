tool
extends MMGenBase
class_name MMGenShader

var shader_model : Dictionary = {}
var uses_seed = false

var editable = false

func toggle_editable() -> bool:
	editable = !editable
	if editable:
		model = null
	return true

func is_editable() -> bool:
	return editable

func has_randomness() -> bool:
	return uses_seed

func get_type() -> String:
	return "shader"

func get_type_name() -> String:
	if shader_model.has("name"):
		return shader_model.name
	return .get_type_name()

func get_parameter_defs() -> Array:
	if shader_model == null or !shader_model.has("parameters"):
		return []
	else:
		return shader_model.parameters

func get_input_defs() -> Array:
	if shader_model == null or !shader_model.has("inputs"):
		return []
	else:
		return shader_model.inputs

func get_output_defs() -> Array:
	if shader_model == null or !shader_model.has("outputs"):
		return []
	else:
		return shader_model.outputs

func set_shader_model(data: Dictionary) -> void:
	shader_model = data
	init_parameters()
	uses_seed = false
	if shader_model.has("outputs"):
		for i in range(shader_model.outputs.size()):
			var output = shader_model.outputs[i]
			var output_code = ""
			if output.has("rgba"):
				shader_model.outputs[i].type = "rgba"
				output_code = output.rgba
			elif output.has("rgb"):
				shader_model.outputs[i].type = "rgb"
				output_code = output.rgb
			elif output.has("f"):
				shader_model.outputs[i].type = "f"
				output_code = output.f
			else:
				print("Unsupported output type")
			if output_code.find("$seed") != -1 or output_code.find("$(seed)") != -1:
				uses_seed = true
	if shader_model.has("code"):
		if shader_model.code.find("$seed") != -1 or shader_model.code.find("$(seed)") != -1:
			uses_seed = true
	if shader_model.has("instance"):
		if shader_model.instance.find("$seed") != -1 or shader_model.instance.find("$(seed)") != -1:
			uses_seed = true

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

func replace_input(string, context, input, type, src, default) -> Dictionary:
	var required_globals = []
	var required_defs = ""
	var required_code = ""
	var required_textures = {}
	var new_pass_required = false
	while true:
		var uv = find_keyword_call(string, input)
		if uv == null:
			break
		elif uv == "":
			print("syntax error")
			break
		elif uv.find("$") != -1:
			new_pass_required = true
			break
		var src_code
		if src == null:
			src_code = subst(default, context, "(%s)" % uv)
		else:
			src_code = src.generator.get_shader_code(uv, src.output_index, context)
			while src_code is GDScriptFunctionState:
				src_code = yield(src_code, "completed")
			src_code.string = src_code[type]
		# Add global definitions
		if src_code.has("globals"):
			for d in src_code.globals:
				if required_globals.find(d) == -1:
					required_globals.push_back(d)
		# Add generated definitions
		if src_code.has("defs"):
			required_defs += src_code.defs
		# Add generated code
		if src_code.has("code"):
			required_code += src_code.code
		# Add textures
		if src_code.has("textures"):
			required_textures = src_code.textures
		string = string.replace("$%s(%s)" % [ input, uv ], src_code.string)
	return { string=string, globals=required_globals, defs=required_defs, code=required_code, textures=required_textures, new_pass_required=new_pass_required }

func is_word_letter(l) -> bool:
	return "azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN1234567890_".find(l) != -1

func replace_variable(string, variable, value) -> String:
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

func subst(string, context, uv = "") -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var required_globals = []
	var required_defs = ""
	var required_code = ""
	var required_textures = {}
	string = replace_variable(string, "name", genname)
	if uv != "":
		var genname_uv = genname+"_"+str(context.get_variant(self, uv))
		string = replace_variable(string, "name_uv", genname_uv)
	var tmp_string = replace_variable(string, "seed", str(get_seed()))
	if tmp_string != string:
		string = tmp_string
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
				value_string = "%.9f" % pow(2, value)
			elif p.type == "enum":
				if value >= p.values.size():
					value = 0
				value_string = p.values[value].value
			elif p.type == "color":
				value_string = "vec4(%.9f, %.9f, %.9f, %.9f)" % [ value.r, value.g, value.b, value.a ]
			elif p.type == "gradient":
				value_string = genname+"_p_"+p.name+"_gradient_fct"
			elif p.type == "boolean":
				value_string = "true" if value else "false"
			else:
				print("Cannot replace parameter of type "+p.type)
			if value_string != null:
				string = replace_variable(string, p.name, value_string)
	if shader_model.has("inputs") and typeof(shader_model.inputs) == TYPE_ARRAY:
		var cont = true
		while cont:
			var changed = false
			var new_pass_required = false
			for i in range(shader_model.inputs.size()):
				var input = shader_model.inputs[i]
				var source = get_source(i)
				var result = replace_input(string, context, input.name, input.type, source, input.default)
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
				if string != result.string:
					changed = true
				if result.new_pass_required:
					new_pass_required = true
				string = result.string
				# Add global definitions
				for d in result.globals:
					if required_globals.find(d) == -1:
						required_globals.push_back(d)
				# Add generated definitions
				required_defs += result.defs
				# Add generated code
				required_code += result.code
				for t in result.textures.keys():
					required_textures[t] = result.textures[t]
			cont = changed and new_pass_required
	return { string=string, globals=required_globals, defs=required_defs, code=required_code, textures=required_textures }

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var output_info = [ { field="rgba", type="vec4" }, { field="rgb", type="vec3" }, { field="f", type="float" } ]
	var rv = { globals=[], defs="", code="", textures={} }
	if shader_model != null and shader_model.has("outputs") and shader_model.outputs.size() > output_index:
		var output = shader_model.outputs[output_index]
		if shader_model.has("instance") && !context.has_variant(self):
			var subst_output = subst(shader_model.instance, context, "")
			while subst_output is GDScriptFunctionState:
				subst_output = yield(subst_output, "completed")
			rv.defs += subst_output.string
			for t in subst_output.textures.keys():
				rv.textures[t] = subst_output.textures[t]
			for p in shader_model.parameters:
				if p.type == "gradient":
					var g = parameters[p.name]
					if !(g is MMGradient):
						g = MMGradient.new()
						g.deserialize(parameters[p.name])
					rv.defs += g.get_shader(genname+"_p_"+p.name+"_gradient_fct")
		# Add inline code
		if shader_model.has("code"):
			var variant_index = context.get_variant(self, uv)
			if variant_index == -1:
				variant_index = context.get_variant(self, uv)
				var subst_code = subst(shader_model.code, context, uv)
				while subst_code is GDScriptFunctionState:
					subst_code = yield(subst_code, "completed")
				# Add global definitions
				for d in subst_code.globals:
					if rv.globals.find(d) == -1:
						rv.globals.push_back(d)
				# Add generated definitions
				rv.defs += subst_code.defs
				# Add generated code
				rv.code += subst_code.code
				rv.code += subst_code.string
		# Add output_code
		var variant_string = uv+","+str(output_index)
		var variant_index = context.get_variant(self, variant_string)
		if variant_index == -1:
			variant_index = context.get_variant(self, variant_string)
			for t in output_info:
				if output.has(t.field):
					var subst_output = subst(output[t.field], context, uv)
					while subst_output is GDScriptFunctionState:
						subst_output = yield(subst_output, "completed")
					# Add global definitions
					for d in subst_output.globals:
						if rv.globals.find(d) == -1:
							rv.globals.push_back(d)
					# Add generated definitions
					rv.defs += subst_output.defs
					# Add generated code
					rv.code += subst_output.code
					rv.code += "%s %s_%d_%d_%s = %s;\n" % [ t.type, genname, output_index, variant_index, t.field, subst_output.string ]
					for t in subst_output.textures.keys():
						rv.textures[t] = subst_output.textures[t]
		for t in output_info:
			if output.has(t.field):
				rv[t.field] = "%s_%d_%d_%s" % [ genname, output_index, variant_index, t.field ]
		if shader_model.has("global") && rv.globals.find(shader_model.global) == -1:
			rv.globals.push_back(shader_model.global)
	return rv


func _serialize(data: Dictionary) -> Dictionary:
	data.shader_model = shader_model
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("shader_model"):
		set_shader_model(data.shader_model)
	elif data.has("model_data"):
		set_shader_model(data.model_data)


func edit(node) -> void:
	if shader_model != null:
		var edit_window = load("res://addons/material_maker/widgets/node_editor/node_editor.tscn").instance()
		node.get_parent().add_child(edit_window)
		edit_window.set_model_data(shader_model)
		edit_window.connect("node_changed", node, "update_generator")
		edit_window.popup_centered()
