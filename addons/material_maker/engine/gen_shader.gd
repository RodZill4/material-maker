tool
extends MMGenBase
class_name MMGenShader


var shader_model : Dictionary = {}
var shader_model_preprocessed : Dictionary = {}
var model_uses_seed : bool = false
var params_use_seed : bool = false
var generic_size : int = 1

var editable : bool = false


func toggle_editable() -> bool:
	editable = !editable
	if editable:
		model = null
	return true

func is_editable() -> bool:
	return editable


func has_randomness() -> bool:
	return model_uses_seed or params_use_seed

func get_description() -> String:
	var desc_list : PoolStringArray = PoolStringArray()
	if shader_model.has("shortdesc"):
		desc_list.push_back(TranslationServer.translate(shader_model.shortdesc))
	if shader_model.has("longdesc"):
		desc_list.push_back(TranslationServer.translate(shader_model.longdesc))
	return desc_list.join("\n")

func get_type() -> String:
	return "shader"

func get_type_name() -> String:
	if shader_model.has("name"):
		return shader_model.name
	return .get_type_name()

func get_parameter_defs() -> Array:
	if shader_model_preprocessed == null or !shader_model_preprocessed.has("parameters"):
		return []
	else:
		return shader_model_preprocessed.parameters

func set_parameter(n : String, v) -> void:
	var old_value = parameters[n] if parameters.has(n) else null
	var parameter_uses_seed : bool = (v is String and (v.find("$rnd(") != -1 or v.find("$rndi(") != -1))
	var uses_seed_updated : bool = false
	if parameter_uses_seed:
		if ! params_use_seed:
			uses_seed_updated = true
		params_use_seed = true
	elif old_value is String and (old_value.find("$rnd(") != -1 or old_value.find("$rndi(") != -1):
		var new_params_use_seed : bool = false
		for k in parameters.keys():
			if k != n and parameters[k] is String and (parameters[k].find("$rnd(") != -1 or parameters[k].find("$rndi(") != -1):
				new_params_use_seed = true
				break
		if params_use_seed != new_params_use_seed:
			uses_seed_updated = true
			params_use_seed = new_params_use_seed
	.set_parameter(n, v)
	var had_rnd : bool = false
	if old_value is String and (old_value.find("$rnd(") != -1 or old_value.find("$rndi(") != -1):
		had_rnd = true
	var has_rnd : bool = false
	if uses_seed_updated and is_inside_tree():
		get_tree().call_group("generator_node", "on_generator_changed", self)

func get_input_defs() -> Array:
	if shader_model_preprocessed == null or !shader_model_preprocessed.has("inputs"):
		return []
	else:
		return shader_model_preprocessed.inputs

func get_output_defs(_show_hidden : bool = false) -> Array:
	if shader_model_preprocessed == null or !shader_model_preprocessed.has("outputs"):
		return []
	else:
		return shader_model_preprocessed.outputs

func get_preprocessed_output_def(output_index : int):
	if shader_model_preprocessed.has("outputs") and shader_model_preprocessed.outputs.size() > output_index:
		return shader_model_preprocessed.outputs[output_index]
	else:
		return null

#
# Shader model preprocessing
#

# Instance functions fixing
# This adds the variations parameter to all instance functions (defs and calls)

func find_instance_functions(code : String):
	var functions : Array = []
	var regex : RegEx = RegEx.new()
	regex.compile("(\\w+)\\s+(\\w*\\$(?:\\(name\\)\\w*|name))\\s*\\((.*)\\)\\s*{")
	var result : Array = regex.search_all(code)
	for r in result:
		if not r.strings[1] in [ "return" ]:
			functions.push_back(r.strings[2]);
			code = code.replace(r.strings[0], "%s %s(%s, float _seed_variation_) {" % [ r.strings[1], r.strings[2], r.strings[3] ])
	return { code=code, functions=functions }

func fix_instance_functions(code : String, instance_functions : Array):
	var variation_parameter = ", _seed_variation_"
	var variation_parameter_length = variation_parameter.length()
	for f in instance_functions:
		var location : int = 0
		while true:
			location = code.findn(f, location)
			if location == -1:
				break
			if location > 0 and ("a"+code[location-1]).is_valid_identifier():
				location += f.length()
				continue
			var p : int = location + f.length()
			while true:
				match code[p]:
					'(':
						p = find_matching_parenthesis(code, p)
						location = p
						var replace : bool = true
						var length = code.length()-1
						var p2 = p
						while p2 < length:
							p2 += 1
							match code[p2]:
								" ", "\t", "\n", "\r":
									pass
								"{":
									replace = false
								_:
									break
						if replace:
							code = code.insert(p, variation_parameter)
						break
					' ', '\t', '\r', '\n':
						p += 1
					_:
						break
			location = p
	return code

func preprocess_shader_model(data : Dictionary):
	var preprocessed = {}
	if data.has("instance") and data.instance != "":
		# if the instance section is not empty, parameters, code and instance sections must
		# be preprocessed (add variations parameter to instance functions)
		var instance_functions = find_instance_functions(data.instance)
		preprocessed.instance = fix_instance_functions(instance_functions.code, instance_functions.functions)
		if data.has("code"):
			preprocessed.code = fix_instance_functions(data.code, instance_functions.functions)
		if data.has("parameters"):
			preprocessed.parameters = []
			for p in data.parameters:
				if p.type == "enum":
					var replace = false
					var values = []
					for i in p.values.size():
						var v = fix_instance_functions(p.values[i].value, instance_functions.functions)
						if v != p.values[i].value:
							replace = true
						values.push_back({ name=p.values[i].name, value=v })
					if replace:
						p = p.duplicate(true)
						p.values = values
				preprocessed.parameters.push_back(p)
		if data.has("outputs"):
			preprocessed.outputs = []
			for o in data.outputs:
				o = o.duplicate(true)
				if o.has("type") and o.has(o.type):
					o[o.type] = fix_instance_functions(o[o.type], instance_functions.functions)
				else:
					#print("Bad output definition: "+str(o))
					for f in mm_io_types.types.keys():
						if o.has(f):
							o[f] = fix_instance_functions(o[f], instance_functions.functions)
							o.type = f
				preprocessed.outputs.push_back(o)
	else:
		# otherwise just copy those sections
		if data.has("parameters"):
			preprocessed.parameters = data.parameters
		if data.has("code"):
			preprocessed.code = data.code
		if data.has("outputs"):
			preprocessed.outputs = data.outputs
	if data.has("inputs"):
		preprocessed.inputs = data.inputs
	if data.has("includes"):
		preprocessed.includes = data.includes
	if data.has("global"):
		preprocessed.global = data.global
	return preprocessed

# Shader model genericity

func is_generic() -> bool:
	if shader_model.has("parameters"):
		for p in shader_model.parameters:
			if p.name.find("#") != -1:
				return true
	if shader_model.has("inputs"):
		for i in shader_model.inputs:
			if i.name.find("#") != -1:
				return true
	return false

func set_generic_size(size : int) -> void:
	if generic_size == size or ! is_generic():
		return
	generic_size = size
	set_shader_model(shader_model)

func expand_generic_code(code : String, first_generic_value : int = 1) -> String:
	var rv : String = ""
	while code != "":
		var for_position : int = code.find("#for")
		if for_position == -1:
			rv += code
			break
		rv += code.left(for_position)
		code = code.right(for_position+4)
		var end_position : int = code.find("#end")
		var generic_code : String
		if end_position == -1:
			generic_code = code
			code = ""
		else:
			generic_code = code.left(end_position)
			code = code.right(end_position+4)
		for gi in generic_size:
			rv += generic_code.replace("#", str(gi+first_generic_value))
	return rv

# Get the range of generic inputs/parameters/outputs (see how it's called)
func get_generic_range(array : Array, field : String, indirect : bool = false) -> Dictionary:
	var rv : Dictionary = { first = -1, last = -1 }
	for i in array.size():
		var p = array[i]
		var string : String
		if indirect:
			string = p[p[field]]
		else:
			string = p[field]
		if string.find("#") != -1:
			if rv.first == -1:
				rv.first = i
			elif rv.last != -1:
				print("incorrect generic inputs")
				return { first = -1, last = -1 }
		elif rv.first != -1 and rv.last == -1:
			rv.last = i
	if rv.first != -1 and rv.last == -1:
		rv.last = array.size()
	return rv

func expand_generic() -> void:
	# Find generic inputs
	var generic_inputs = get_generic_range(shader_model.inputs, "name")
	var first_generic_input = generic_inputs.first
	var last_generic_input = generic_inputs.last
	# Find generic parameters
	var generic_parameters = get_generic_range(shader_model.parameters, "name")
	var first_generic_parameter = generic_parameters.first
	var last_generic_parameter = generic_parameters.last
	# Find generic outputs
	var generic_outputs = get_generic_range(shader_model.outputs, "type", 1)
	var first_generic_output = generic_outputs.first
	var last_generic_output = generic_outputs.last
	# Build the model
	var first_generic_value : int = 1
	# Build inputs
	if first_generic_input != -1:
		var inputs = []
		for i in first_generic_input:
			inputs.append(shader_model.inputs[i])
		for gi in generic_size:
			var gv = first_generic_value + gi
			for i in range(first_generic_input, last_generic_input):
				var input = shader_model.inputs[i].duplicate()
				input.name = input.name.replace("#", str(gv))
				if input.has("label"):
					input.label = input.label.replace("#", str(gv))
				if input.has("shortdesc"):
					input.shortdesc = input.shortdesc.replace("#", str(gv))
				if input.has("longdesc"):
					input.longdesc = input.longdesc.replace("#", str(gv))
				inputs.append(input)
		for i in range(last_generic_input, shader_model.inputs.size()):
			inputs.append(shader_model.inputs[i])
		shader_model_preprocessed.inputs = inputs
	# Build parameters
	var parameters_ranges = []
	if first_generic_parameter != -1:
		if first_generic_parameter > 0:
			parameters_ranges.append({ begin = 0, end = first_generic_parameter, generic = false })
		parameters_ranges.append({ begin = first_generic_parameter, end = last_generic_parameter, generic = true })
		if last_generic_parameter < shader_model.parameters.size():
			parameters_ranges.append({ begin = last_generic_parameter, end = shader_model.parameters.size(), generic = false })
	else:
		parameters_ranges.append({ begin = 0, end = shader_model.parameters.size(), generic = false })
	var parameters = []
	for r in parameters_ranges:
		if r.generic:
			for gi in generic_size:
				var gv = first_generic_value + gi
				for i in range(r.begin, r.end):
					var parameter = shader_model.parameters[i].duplicate()
					parameter.name = parameter.name.replace("#", str(gv))
					if parameter.has("shortdesc"):
						parameter.shortdesc = parameter.shortdesc.replace("#", str(gv))
					if parameter.has("longdesc"):
						parameter.longdesc = parameter.longdesc.replace("#", str(gv))
					var label : String = parameter.label
					var colon_position = label.find(":")
					if colon_position != -1 and label.left(colon_position).is_valid_integer():
						var param_position : int = label.left(colon_position).to_int()
						if param_position > first_generic_input and param_position <= last_generic_input:
							param_position += gi*(last_generic_input-first_generic_input)
							parameter.label = str(param_position)+label.right(colon_position)
					parameters.append(parameter)
		else:
			for i in range(r.begin, r.end):
				var parameter = shader_model.parameters[i]
				var label : String = parameter.label
				var colon_position = label.find(":")
				if colon_position != -1 and label.left(colon_position).is_valid_integer():
					var param_position : int = label.left(colon_position).to_int()
					if param_position >= last_generic_input:
						param_position += (generic_size-1)*(last_generic_input-first_generic_input)
						parameter = parameter.duplicate()
						parameter.label = str(param_position)+label.right(colon_position)
				parameters.append(parameter)
	shader_model_preprocessed.parameters = parameters
	# Build outputs
	if first_generic_output != -1:
		var outputs = []
		for i in first_generic_output:
			outputs.append(shader_model_preprocessed.outputs[i])
		for gi in generic_size:
			var gv = first_generic_value + gi
			for i in range(first_generic_output, last_generic_output):
				var output = shader_model_preprocessed.outputs[i].duplicate()
				output[output.type] = output[output.type].replace("#", str(gv))
				if output.has("shortdesc"):
					output.shortdesc = output.shortdesc.replace("#", str(gv))
				if output.has("longdesc"):
					output.longdesc = output.longdesc.replace("#", str(gv))
				outputs.append(output)
		for i in range(last_generic_output, shader_model_preprocessed.outputs.size()):
			outputs.append(shader_model_preprocessed.outputs[i])
		shader_model_preprocessed.outputs = outputs
	# Build code
	if shader_model_preprocessed.has("code"):
		shader_model_preprocessed.code = expand_generic_code(shader_model_preprocessed.code, first_generic_value)
	if shader_model_preprocessed.has("instance"):
		shader_model_preprocessed.instance = expand_generic_code(shader_model_preprocessed.instance, first_generic_value)

func set_shader_model(data: Dictionary) -> void:
	shader_model = data
	shader_model_preprocessed = preprocess_shader_model(data)
	if is_generic():
		expand_generic()
	init_parameters()
	model_uses_seed = false
	if shader_model.has("outputs"):
		for i in range(shader_model.outputs.size()):
			var output = shader_model.outputs[i]
			var output_code = ""
			for f in mm_io_types.types.keys():
				if output.has(f):
					shader_model.outputs[i].type = f
					output_code = output[f]
					break
			if output_code == "":
				print("Unsupported output type")
			if output_code.find("$seed") != -1 or output_code.find("$(seed)") != -1:
				model_uses_seed = true
	if shader_model.has("code"):
		if shader_model.code.find("$seed") != -1 or shader_model.code.find("$(seed)") != -1:
			model_uses_seed = true
	if shader_model.has("instance"):
		if shader_model.instance.find("$seed") != -1 or shader_model.instance.find("$(seed)") != -1:
			model_uses_seed = true
	if get_parent() != null and get_parent().has_method("check_input_connects"):
		get_parent().check_input_connects(self)
	all_sources_changed()

#
# Shader generation
#

func find_matching_parenthesis(string : String, i : int, op : String = '(', cp : String = ')') -> int:
	var parenthesis_level = 0
	var length : int = string.length()
	while i < length:
		var c = string[i]
		if c == op:
			parenthesis_level += 1
		elif c == cp:
			parenthesis_level -= 1
			if parenthesis_level == 0:
				return i
		i += 1
		var next_op = string.find(op, i)
		var next_cp = string.find(cp, i)
		var max_p = max(next_op, next_cp)
		if max_p < 0:
			return -1
		var min_p = min(next_op, next_cp)
		i = max_p if min_p < 0 else min_p
	return i

func find_keyword_call(string : String, keyword : String):
	var search_string : String = "$%s(" % keyword
	var position : int = string.find(search_string)
	if position == -1:
		return null
	var parameter_begin : int = position+search_string.length()
	var end : int = find_matching_parenthesis(string, parameter_begin-1)
	if end > 0:
		return string.substr(parameter_begin, end-parameter_begin)
	return null

func replace_input_with_function_call(string : String, input : String, seed_parameter : String = ", _seed_variation_", input_suffix : String = "") -> String:
	var genname = "o"+str(get_instance_id())
	while true:
		var uv = find_keyword_call(string, input+input_suffix)
		if uv == null:
			break
		elif uv == "":
			print("syntax error")
			print(string)
			break
		string = string.replace("$%s(%s)" % [ input+input_suffix, uv ], "%s_input_%s(%s%s)" % [ genname, input, uv, seed_parameter ])
	return string

func replace_input(string : String, context, input : String, type : String, src : OutputPort, default : String) -> Dictionary:
	var required_globals = []
	var required_defs = ""
	var required_code = ""
	var new_pass_required = false
	while true:
		var uv = find_keyword_call(string, input)
		if uv == null:
			break
		elif uv == "":
			print("syntax error")
			print(string)
			break
		elif uv.find("$") != -1:
			new_pass_required = true
			break
		var src_code
		if src == null:
			src_code = subst(default, context, "(%s)" % uv)
		else:
			src_code = src.generator.get_shader_code(uv, src.output_index, context)
			if src_code.has(type):
				src_code.string = src_code[type]
			else:
				src_code.string = "*error missing "+type+"*\n"+JSON.print(src_code)
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
		string = string.replace("$%s(%s)" % [ input, uv ], src_code.string)
	return { string=string, globals=required_globals, defs=required_defs, code=required_code, new_pass_required=new_pass_required }

func is_word_letter(l) -> bool:
	return "azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN1234567890_".find(l) != -1

func replace_rnd(string : String, offset : int = 0) -> String:
	while true:
		var params = find_keyword_call(string, "rnd")
		if params == null:
			break
		var replace = "$rnd(%s)" % params
		while true:
			var position : int = string.find(replace)
			if position == -1:
				break
			var with = "param_rnd(%s, $seed+%f)" % [ params, sin(position)+offset ]
			string = string.replace(replace, with)
	return string

func replace_rndi(string : String, offset : int = 0) -> String:
	while true:
		var params = find_keyword_call(string, "rndi")
		if params == null:
			break
		var replace = "$rndi(%s)" % params
		while true:
			var position : int = string.find(replace)
			if position == -1:
				break
			var with = "param_rndi(%s, $seed+%f)" % [ params, sin(position)+offset ]
			string = string.replace(replace, with)
	return string

func replace_variables(string : String, variables : Dictionary) -> String:
	while true:
		var old_string : String = string
		for variable in variables.keys():
			string = string.replace("$(%s)" % variable, variables[variable])
			var keyword_size : int = variable.length()+1
			var new_string : String = ""
			while !string.empty():
				var pos : int = string.find("$"+variable)
				if pos == -1:
					new_string += string
					break
				new_string += string.left(pos)
				string = string.right(pos)
				if string.length() > keyword_size and is_word_letter(string[keyword_size]):
					new_string += string.left(keyword_size)
					string = string.right(keyword_size)
					continue
				if string.empty() or !is_word_letter(string[0]):
					new_string += variables[variable]
				else:
					new_string += "$"+variable
				string = string.right(keyword_size)
			string = new_string
		if string == old_string:
			break
	return string

func subst(string : String, context : MMGenContext, uv : String = "") -> Dictionary:
	var genname : String = "o"+str(get_instance_id())
	var parent = get_parent()
	var required_globals : Array = []
	if parent.has_method("get_globals"):
		required_globals = [ parent.get_globals() ]
	var required_defs : String = ""
	var required_code : String = ""
	# Named parameters from parent graph are specified first so they don't
	# hide locals
	var variables = {}
	if ! mm_renderer.get_global_parameters().empty():
		for gp in mm_renderer.get_global_parameters():
			variables[gp] = "mm_global_"+gp
	if parent.has_method("get_named_parameters"):
		var named_parameters : Dictionary = parent.get_named_parameters()
		for np in named_parameters.keys():
			variables[np] = named_parameters[np].id
	variables["name"] = genname
	if uv != "":
		var genname_uv : String = genname+"_"+str(context.get_variant(self, uv))
		variables["name_uv"] = genname_uv
	if seed_locked:
		variables["seed"] = "seed_"+genname
	else:
		variables["seed"] = "(seed_"+genname+"+fract(_seed_variation_))"
	variables["node_id"] = str(get_instance_id())
	if shader_model_preprocessed.has("parameters") and typeof(shader_model_preprocessed.parameters) == TYPE_ARRAY:
		var rnd_offset : int = 0
		for p in shader_model_preprocessed.parameters:
			if !p.has("name") or !p.has("type"):
				continue
			var value = parameters[p.name]
			var value_string = null
			if p.type == "float":
				if parameters[p.name] is float:
					value_string = "p_%s_%s" % [ genname, p.name ]
				elif parameters[p.name] is String and parameters[p.name].find("$rnd(") != -1:
					value_string = "("+replace_rnd(parameters[p.name], rnd_offset)+")"
				elif parameters[p.name] is String and parameters[p.name].find("$rndi(") != -1:
					value_string = "("+replace_rndi(parameters[p.name], rnd_offset)+")"
				else:
					print("Error in float parameter "+p.name)
					value_string = "0.0"
				rnd_offset += 17
			elif p.type == "size":
				value_string = "%.9f" % pow(2, value)
			elif p.type == "enum":
				if p.values.empty():
					value_string = ""
				else:
					if ! ( value is int or value is float ) or value < 0 or value >= p.values.size():
						value = 0
					value_string = p.values[value].value
			elif p.type == "color":
				value_string = "p_%s_%s" % [ genname, p.name ]
			elif p.type == "gradient":
				value_string = genname+"_"+p.name+"_gradient_fct"
			elif p.type == "curve":
				value_string = genname+"_"+p.name+"_curve_fct"
			elif p.type == "polygon" or p.type == "polyline":
				if !(value is MMPolygon):
					value = MMPolygon.new()
					value.deserialize(parameters[p.name])
				value_string = value.get_shader()
			elif p.type == "boolean":
				value_string = "true" if value else "false"
			else:
				print("Cannot replace parameter of type "+p.type)
			if value_string != null:
				variables[p.name] = value_string
	if uv != "":
		if uv[0] == "(" and find_matching_parenthesis(uv, 0) == uv.length()-1:
			variables["uv"] = uv
		else:
			variables["uv"] = "("+uv+")"
	variables["time"] = "elapsed_time"
	if shader_model_preprocessed.has("inputs") and typeof(shader_model_preprocessed.inputs) == TYPE_ARRAY:
		for i in range(shader_model_preprocessed.inputs.size()):
			var input = shader_model_preprocessed.inputs[i]
			var source = get_source(i)
			if source == null:
				continue
			var src_attributes = source.generator.get_output_attributes(source.output_index)
			if src_attributes.has("texture"):
				var source_globals = source.generator.get_globals(src_attributes.texture)
				for sg in source_globals:
					if required_globals.find(sg) == -1:
						required_globals.push_back(sg)
			for a in src_attributes.keys():
				if a == "texture_size":
					variables[input.name+".size"] = src_attributes.texture_size
				else:
					variables[input.name+"."+a] = src_attributes[a]
	string = replace_variables(string, variables)
	if shader_model_preprocessed.has("inputs") and typeof(shader_model_preprocessed.inputs) == TYPE_ARRAY:
		var cont = true
		while cont:
			var changed : bool = false
			var new_pass_required : bool = false
			for i in range(shader_model_preprocessed.inputs.size()):
				var input = shader_model_preprocessed.inputs[i]
				var source = get_source(i)
				if input.has("function") and input.function:
					string = replace_input_with_function_call(string, input.name)
					string = replace_input_with_function_call(string, input.name, "", ".variation")
				else:
					var result = replace_input(string, context, input.name, input.type, source, input.default)
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
			cont = changed and new_pass_required
			string = replace_variables(string, variables)
	return { string=string, globals=required_globals, defs=required_defs, code=required_code }

func generate_parameter_declarations(rv : Dictionary):
	var genname = "o"+str(get_instance_id())
	if has_randomness():
		rv.defs += "uniform float seed_%s = %.9f;\n" % [ genname, get_seed() ]
	for p in shader_model_preprocessed.parameters:
		if p.type == "float" and parameters[p.name] is float:
			rv.defs += "uniform float p_%s_%s = %.9f;\n" % [ genname, p.name, parameters[p.name] ]
		elif p.type == "color":
			rv.defs += "uniform vec4 p_%s_%s = vec4(%.9f, %.9f, %.9f, %.9f);\n" % [ genname, p.name, parameters[p.name].r, parameters[p.name].g, parameters[p.name].b, parameters[p.name].a ]
		elif p.type == "gradient":
			var g = parameters[p.name]
			if !(g is MMGradient):
				g = MMGradient.new()
				g.deserialize(parameters[p.name])
			rv.defs += g.get_shader_params(genname+"_"+p.name)
			rv.defs += g.get_shader(genname+"_"+p.name)
		elif p.type == "curve":
			var g = parameters[p.name]
			if !(g is MMCurve):
				g = MMCurve.new()
				g.deserialize(parameters[p.name])
			var params = g.get_shader_params(genname+"_"+p.name)
			for sp in params.keys():
				rv.defs += "uniform float %s = %.9f;\n" % [ sp, params[sp] ]
			rv.defs += g.get_shader(genname+"_"+p.name)
	return rv

func generate_input_declarations(rv : Dictionary, context : MMGenContext):
	var genname = "o"+str(get_instance_id())
	if shader_model_preprocessed.has("inputs"):
		for i in range(shader_model_preprocessed.inputs.size()):
			var input = shader_model_preprocessed.inputs[i]
			if input.has("function") and input.function:
				var source = get_source(i)
				var string = "$%s(%s)" % [ input.name, mm_io_types.types[input.type].params ]
				var local_context = MMGenContext.new(context)
				var result = replace_input(string, local_context, input.name, input.type, source, input.default)
				# Add global definitions
				for d in result.globals:
					if rv.globals.find(d) == -1:
						rv.globals.push_back(d)
				# Add generated definitions
				rv.defs += result.defs
				rv.defs += "%s %s_input_%s(%s, float _seed_variation_) {\n" % [ mm_io_types.types[input.type].type, genname, input.name, mm_io_types.types[input.type].paramdefs ]
				rv.defs += "%s\n" % result.code
				rv.defs += "return %s;\n}\n" % result.string
	return rv

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var rv = { globals=[], defs="", code="" }
	if shader_model_preprocessed == null:
		return rv
	var output = get_preprocessed_output_def(output_index)
	if output == null:
		return rv
	if !context.has_variant(self):
		# Generate parameter declarations
		rv = generate_parameter_declarations(rv)
		# Generate functions for inputs
		rv = generate_input_declarations(rv, context)
		if shader_model_preprocessed.has("instance"):
			var subst_output = subst(shader_model_preprocessed.instance, context, "")
			rv.defs += subst_output.string
	# Add inline code
	if shader_model_preprocessed.has("code") and output[output.type].find("@NOCODE") == -1:
		var variant_index = context.get_variant(self, uv)
		if variant_index == -1:
			variant_index = context.get_variant(self, uv)
			var subst_code = subst(shader_model_preprocessed.code, context, uv)
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
		for f in mm_io_types.types.keys():
			if output.has(f):
				var subst_output = subst(output[f].replace("@NOCODE", ""), context, uv)
				# Add global definitions
				for d in subst_output.globals:
					if rv.globals.find(d) == -1:
						rv.globals.push_back(d)
				# Add generated definitions
				rv.defs += subst_output.defs
				# Add generated code
				rv.code += subst_output.code
				rv.code += "%s %s_%d_%d_%s = %s;\n" % [ mm_io_types.types[f].type, genname, output_index, variant_index, f, subst_output.string ]
	for f in mm_io_types.types.keys():
		if output.has(f):
			rv[f] = "%s_%d_%d_%s" % [ genname, output_index, variant_index, f ]
	rv.type = output.type
	if shader_model_preprocessed.has("includes"):
		for i in shader_model_preprocessed.includes:
			var g = mm_loader.get_predefined_global(i)
			if g != "" and rv.globals.find(g) == -1:
				rv.globals.push_back(g)
	if shader_model_preprocessed.has("global") and rv.globals.find(shader_model_preprocessed.global) == -1:
		rv.globals.push_back(shader_model_preprocessed.global)
	return rv

func remove_comments(s : String) -> String:
	var re : RegEx = RegEx.new()
	re.compile("/\\*(.*?)\\*/")
	s = re.sub(s, "", true)
	re.compile("//([^\\n]*)\\n")
	s = re.sub(s, "", true)
	return s

func split_glsl(s : String) -> Array:
	s = remove_comments(s)
	var a : Array = []
	s = s.strip_edges()
	while s != "":
		var next_semicolon = s.find(";")
		var next_bracket = s.find("{")
		if next_semicolon != -1 and (next_bracket == -1 or next_semicolon < next_bracket):
			a.append(s.left(next_semicolon+1))
			s = s.right(next_semicolon+1)
		elif next_bracket != -1:
			var closing_bracket = find_matching_parenthesis(s, next_bracket, '{', '}')
			a.append(s.left(closing_bracket+1))
			s = s.right(closing_bracket+1)
		else:
			print("Error: "+s)
			break
		s = s.strip_edges()
	return a


func _serialize(data: Dictionary) -> Dictionary:
	data.shader_model = shader_model
	return data

func _serialize_data(data: Dictionary) -> Dictionary:
	if is_generic():
		data.generic_size = generic_size
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("shader_model"):
		set_shader_model(data.shader_model)
	elif data.has("model_data"):
		set_shader_model(data.model_data)
	if data.has("generic_size"):
		set_generic_size(data.generic_size)

func get_shader_model_for_edit():
	return shader_model

func do_edit(node, edit_window_scene : PackedScene) -> void:
	if shader_model != null:
		var edit_window = edit_window_scene.instance()
		node.get_parent().add_child(edit_window)
		edit_window.set_model_data(get_shader_model_for_edit())
		edit_window.connect("node_changed", node, "update_shader_generator")
		edit_window.connect("popup_hide", edit_window, "queue_free")
		edit_window.popup_centered()

func edit(node) -> void:
	do_edit(node, load("res://material_maker/windows/node_editor/node_editor.tscn"))
