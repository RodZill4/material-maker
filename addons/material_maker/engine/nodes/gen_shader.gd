@tool
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
	var desc_list : PackedStringArray = PackedStringArray()
	if shader_model.has("shortdesc"):
		desc_list.push_back(TranslationServer.translate(shader_model.shortdesc))
	if shader_model.has("longdesc"):
		desc_list.push_back(TranslationServer.translate(shader_model.longdesc))
	return "\n".join(desc_list)

func get_type() -> String:
	return "shader"

func get_type_name() -> String:
	if shader_model.has("name"):
		return shader_model.name
	return super.get_type_name()

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
	super.set_parameter(n, v)
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

func get_preprocessed_output_def(output_index : int) -> Dictionary:
	if shader_model_preprocessed.has("outputs") and shader_model_preprocessed.outputs.size() > output_index:
		return shader_model_preprocessed.outputs[output_index]
	else:
		return {}

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
	code = code.replace("#count", str(generic_size))
	while code != "":
		var for_position : int = code.find("#for")
		if for_position == -1:
			rv += code
			break
		rv += code.left(for_position)
		code = code.right(-(for_position+4))
		var end_position : int = code.find("#end")
		var generic_code : String
		if end_position == -1:
			generic_code = code
			code = ""
		else:
			generic_code = code.left(end_position)
			code = code.right(-(end_position+4))
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
					if colon_position != -1 and label.left(colon_position).is_valid_int():
						var param_position : int = label.left(colon_position).to_int()
						if param_position > first_generic_input and param_position <= last_generic_input:
							param_position += gi*(last_generic_input-first_generic_input)
							parameter.label = str(param_position)+label.right(-colon_position)
					parameters.append(parameter)
		else:
			for i in range(r.begin, r.end):
				var parameter = shader_model.parameters[i]
				var label : String = parameter.label
				var colon_position = label.find(":")
				if colon_position != -1 and label.left(colon_position).is_valid_int():
					var param_position : int = label.left(colon_position).to_int()
					if param_position >= last_generic_input:
						param_position += (generic_size-1)*(last_generic_input-first_generic_input)
						parameter = parameter.duplicate()
						parameter.label = str(param_position)+label.right(-colon_position)
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
	for f in [ "code", "instance" ]:
		if shader_model_preprocessed.has(f):
			shader_model_preprocessed[f] = expand_generic_code(shader_model_preprocessed[f], first_generic_value)

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
	for f in [ "code", "instance" ]:
		if shader_model.has(f) and ( shader_model[f].find("$seed") != -1 or shader_model[f].find("$(seed)") != -1 ):
			model_uses_seed = true
			break
	if get_parent() != null and get_parent().has_method("check_input_connects"):
		get_parent().check_input_connects(self)
	all_sources_changed()

#
# Shader generation
#

func find_keyword_call(string : String, keyword : String):
	var search_string : String = "$%s(" % keyword
	var position : int = string.find(search_string)
	if position == -1:
		return ""
	var parameter_begin : int = position+search_string.length()
	var end : int = find_matching_parenthesis(string, parameter_begin-1)
	if end > 0:
		return string.substr(parameter_begin, end-parameter_begin)
	print("find_keyword_call failure")
	print(keyword)
	print(string)
	return "#error"

func replace_input_with_function_call(string : String, input : String, seed_parameter : String = ", _seed_variation_", input_suffix : String = "") -> String:
	var genname = "o"+str(get_instance_id())
	while true:
		var uv : String = find_keyword_call(string, input+input_suffix)
		if uv == "#error":
			print("syntax error (1)")
			print(string)
			break
		elif uv == "":
			break
		string = string.replace("$%s(%s)" % [ input+input_suffix, uv ], "%s_input_%s(%s%s)" % [ genname, input, uv, seed_parameter ])
	return string

func is_word_letter(l) -> bool:
	return "azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN1234567890_".find(l) != -1

func replace_rnd(string : String, offset : int = 0) -> String:
	while true:
		var params = find_keyword_call(string, "rnd")
		if params == "" or params == "#error":
			break
		var replace = "$rnd(%s)" % params
		while true:
			var position : int = string.find(replace)
			if position == -1:
				break
			var with = "param_rnd(%s, $seed+%f)" % [ params, sin(position+offset)*0.5+0.5 ]
			string = string.replace(replace, with)
	return string

func replace_rndi(string : String, offset : int = 0) -> String:
	while true:
		var params = find_keyword_call(string, "rndi")
		if params == "" or params == "#error":
			break
		var replace = "$rndi(%s)" % params
		while true:
			var position : int = string.find(replace)
			if position == -1:
				break
			var with = "param_rndi(%s, $seed+%f)" % [ params, sin(position)+offset ]
			string = string.replace(replace, with)
	return string

const WORD_LETTERS : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

func generate_parameter_declarations(rv : ShaderCode) -> void:
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

func generate_input_function(index : int, input: Dictionary, rv : ShaderCode, context : MMGenContext) -> void:
	var genname = "o"+str(get_instance_id())
	var source = get_source(index)
	if source == null:
		return
	var local_context = MMGenContext.new(context)
	var source_rv : ShaderCode = source.generator.get_shader_code(mm_io_types.types[input.type].params, source.output_index, local_context)
	rv.add_uniforms(source_rv.uniforms)
	rv.defs += source_rv.defs
	rv.add_globals(source_rv.globals)
	rv.defs += "%s %s_input_%s(%s, float _seed_variation_) {\n" % [ mm_io_types.types[input.type].type, genname, input.name, mm_io_types.types[input.type].paramdefs ]
	rv.defs += "%s\n" % source_rv.code
	rv.defs += "return %s;\n}\n" % source_rv.output_values[input.type]

func process_parameters(rv : ShaderCode, variables : Dictionary, generate_declarations : bool) -> void:
	var genname = "o"+str(get_instance_id())
	var rnd_offset = 0
	if has_randomness():
		if generate_declarations:
			rv.add_uniform("seed_%s" % genname, "float", get_seed())
		variables.seed = "(seed_%s+fract(_seed_variation_))" % genname
	for p in shader_model_preprocessed.parameters:
		if p.type == "float":
			if parameters[p.name] is float:
				if generate_declarations:
					rv.add_uniform("p_%s_%s" % [ genname, p.name ], "float", parameters[p.name])
				variables[p.name] = "p_%s_%s" % [ genname, p.name ]
			else:
				var string_value : String = str(parameters[p.name])
				string_value = replace_rnd(string_value, rnd_offset)
				string_value = replace_rndi(string_value, rnd_offset)
				variables[p.name] = "("+string_value+")"
			rnd_offset += 17
		elif p.type == "color":
			if generate_declarations:
				rv.add_uniform("p_%s_%s" % [ genname, p.name ], "vec4", parameters[p.name])
			variables[p.name] = "p_%s_%s" % [ genname, p.name ]
		elif p.type == "enum":
			variables[p.name] = ""
			if ! p.values.is_empty():
				var value = parameters[p.name]
				if ! ( value is int or value is float ) or value < 0 or value >= p.values.size():
					value = 0
				variables[p.name] = p.values[value].value
		elif p.type == "boolean":
			variables[p.name] = "true" if parameters[p.name] else "false"
		elif p.type == "size":
			variables[p.name] = "%.1f" % pow(2, parameters[p.name])
		elif p.type == "gradient":
			var g = parameters[p.name]
			if !(g is MMGradient):
				g = MMGradient.new()
				g.deserialize(parameters[p.name])
			if generate_declarations:
				rv.add_uniforms(g.get_parameters(genname+"_"+p.name))
				rv.defs += g.get_shader(genname+"_"+p.name)
			variables[p.name] = genname+"_"+p.name+"_gradient_fct"
		elif p.type == "curve":
			var value = parameters[p.name]
			if !(value is MMCurve):
				value = MMCurve.new()
				value.deserialize(parameters[p.name])
			var params = value.get_shader_params(genname+"_"+p.name)
			if generate_declarations:
				for sp in params.keys():
					rv.add_uniform(sp, "float", params[sp])
				rv.defs += value.get_shader(genname+"_"+p.name)
			variables[p.name] = genname+"_"+p.name+"_curve_fct"
		elif p.type == "polygon" or p.type == "polyline":
			var value = parameters[p.name]
			if not value is MMPolygon:
				value = MMPolygon.new()
				value.deserialize(parameters[p.name])
			if generate_declarations:
				rv.add_uniforms(value.get_parameters(genname+"_"+p.name))
			variables[p.name] = value.get_shader(genname+"_"+p.name)
		elif p.type == "splines":
			var value = parameters[p.name]
			if not value is MMSplines:
				value = MMSplines.new()
				value.deserialize(parameters[p.name])
			if generate_declarations:
				rv.add_uniforms(value.get_parameters(genname+"_"+p.name))
			variables[p.name] = value.get_shader(genname+"_"+p.name)
		elif p.type == "pixels":
			var g = parameters[p.name]
			if !(g is MMPixels):
				g = MMPixels.new()
				g.deserialize(parameters[p.name])
			if generate_declarations:
				rv.add_uniforms(g.get_parameters(genname+"_"+p.name))
				rv.defs += g.get_shader(genname+"_"+p.name)
			variables[p.name] = genname+"_"+p.name+"_pixels_fct"
			variables[p.name+"_size"] = genname+"_"+p.name+"_size"
		elif p.type == "lattice":
			var value = parameters[p.name]
			if not value is MMLattice:
				value = MMLattice.new()
				value.deserialize(parameters[p.name])
			if generate_declarations:
				rv.add_uniforms(value.get_parameters(genname+"_"+p.name))
			variables[p.name] = value.get_shader(genname+"_"+p.name)
			variables[p.name+"_size"] = "ivec2(%d, %d)" % [ value.size.x, value.size.y ]
		else:
			print("ERROR: Unsupported parameter "+p.name+" of type "+p.type)

func replace_input(input_name : String, suffix : String, parameters : String, variables : Dictionary, rv : ShaderCode, context : MMGenContext, input : int) -> String:
	var input_def : Dictionary = shader_model_preprocessed.inputs[input]
	var source = get_source(input)
	if source == null:
		var old_uv = variables.uv
		variables.uv = parameters
		var replaced : String = replace_variables(input_def.default, variables, rv, context)
		variables.uv = old_uv
		return replaced
	if suffix != null:
		if source.generator.has_method("get_output_attributes"):
			var attributes = source.generator.get_output_attributes(source.output_index)
			var attribute_name : String = suffix
			if attribute_name == "size":
				attribute_name = "texture_size"
			if attributes != null and attributes is Dictionary and attributes.has(attribute_name):
				return attributes[attribute_name]
		if suffix == "texture" or suffix == "size":
			return "(error: Cannot find attribute %s for input %s)" % [ suffix, input_name ]
	if input_def.has("function") and input_def.function:
		var function_name : String = "o%s_input_%s" % [ str(get_instance_id()), input_def.name ]
		if suffix == "variation":
			return function_name+parameters
		else:
			return function_name+"("+parameters+", _seed_variation_)"
	var source_rv : ShaderCode = source.generator.get_shader_code(parameters, source.output_index, context)
	rv.add_uniforms(source_rv.uniforms)
	rv.defs += source_rv.defs
	rv.add_globals(source_rv.globals)
	rv.code += source_rv.code
	rv.alias = source_rv
	return source_rv.output_values[input_def.type]

func process_inputs(rv : ShaderCode, variables : Dictionary, context : MMGenContext, generate_declarations : bool) -> void:
	if ! shader_model_preprocessed.has("inputs"):
		return
	for i in range(shader_model_preprocessed.inputs.size()):
		var input = shader_model_preprocessed.inputs[i]
		if generate_declarations and input.has("function") and input.function:
			generate_input_function(i, input, rv, context)
		variables[input.name] = { has_parameters=true, has_suffix=true, replace_callable=self.replace_input.bind(i) }

func replace_variables(string : String, variables : Dictionary, rv : ShaderCode, context : MMGenContext) -> String:
	var string_end : String = ""
	while true:
		#print("Replacing variable in:")
		#print(string)
		var dollar_position = string.rfind("$")
		if dollar_position == -1:
			break
		var variable_end : int
		var variable : String
		if string[dollar_position+1] == "(":
			variable_end = find_matching_parenthesis(string, dollar_position+1)+1
			variable = string.substr(dollar_position+2, variable_end-3-dollar_position)
		else:
			variable_end = string.length() - string.right(-dollar_position-1).lstrip(WORD_LETTERS).length()
			variable = string.substr(dollar_position+1, variable_end-dollar_position-1)
		#print("Found variable "+variable)
		#print("End of string: "+string.right(-variable_end))
		string_end = string.right(-variable_end)+string_end
		string = string.left(dollar_position)
		var replace_with
		if variables.has(variable):
			replace_with = variables[variable]
		else:
			replace_with = "(error: "+variable+" not found)"
		if replace_with is String:
			string += replace_with
		elif replace_with is Dictionary:
			var replace_all : bool = (dollar_position == 0)
			string_end = string_end.strip_edges()
			var function_parameters : String = ""
			var function_suffix : String = ""
			if replace_with.has("has_suffix") and replace_with.has_suffix and string_end[0] == ".":
				string_end = string_end.right(-1).strip_edges()
				var suffix_end : int = string_end.length()-string_end.lstrip(WORD_LETTERS).length()
				function_suffix = string_end.left(suffix_end)
				#print("Suffix: "+function_suffix)
				string_end = string_end.right(-suffix_end).strip_edges()
			if replace_with.has("has_parameters") and replace_with.has_parameters and string_end[0] == "(":
				var parameters_end : int = find_matching_parenthesis(string_end, 0)
				if parameters_end < string_end.length()-1:
					replace_all = false
				function_parameters = string_end.left(parameters_end+1)
				if function_parameters[1] == "(" and find_matching_parenthesis(function_parameters, 1) == function_parameters.length()-2:
					function_parameters = function_parameters.left(-1).right(-1)
				#print("Parameters: "+function_parameters)
				string_end = string_end.right(-parameters_end-1)
			else:
				replace_all = false
			string += replace_with.replace_callable.call(variable, function_suffix, function_parameters, variables, rv, context)
			if not replace_all:
				rv.alias = null
			#print("replace_with is Dictionary: "+str(replace_with))
		else:
			print("unsupported replace_with: "+str(replace_with))
			string += replace_with
	#print("Result: "+string+string_end)
	return string+string_end

func get_common_replace_variables(uv : String, rv : ShaderCode) -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var parent : Node = get_parent()
	var variables : Dictionary = {}
	variables.uv = uv
	variables.time = "elapsed_time"
	if ! mm_renderer.get_global_parameters().is_empty():
		for gp in mm_renderer.get_global_parameters():
			variables[gp] = "mm_global_"+gp
	if parent.has_method("get_named_parameters"):
		var named_parameters : Dictionary = parent.get_named_parameters()
		for np in named_parameters.keys():
			variables[np] = named_parameters[np].id
			rv.add_uniform(named_parameters[np].id, "float", named_parameters[np].value)
	variables["name"] = genname
	if seed_locked:
		variables["seed"] = "seed_"+genname
	else:
		variables["seed"] = "(seed_"+genname+"+fract(_seed_variation_))"
	variables["node_id"] = str(get_instance_id())
	return variables

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	var genname = "o"+str(get_instance_id())
	var parent : Node = get_parent()
	var rv : ShaderCode = ShaderCode.new()
	if shader_model_preprocessed == null:
		return rv
	var generate_declarations = ! context.has_variant(self)
	var output = get_preprocessed_output_def(output_index)
	if output.is_empty():
		return rv
	var variables : Dictionary = get_common_replace_variables(uv, rv)
	process_parameters(rv, variables, generate_declarations)
	process_inputs(rv, variables, context, generate_declarations)
	# Add includes, globals and instance code
	if generate_declarations:
		if shader_model_preprocessed.has("includes"):
			for i in shader_model_preprocessed.includes:
				var g = mm_loader.get_predefined_global(i)
				if g != "":
					rv.add_global(g, i)
		if shader_model_preprocessed.has("global"):
			rv.add_global(shader_model_preprocessed.global, "%s (%s)" % [ get_hier_name(), genname ])
		if shader_model_preprocessed.has("instance"):
			var instance_code = replace_variables(shader_model_preprocessed.instance, variables, rv, context)
			instance_code = instance_code.strip_edges()
			if instance_code != "":
				rv.defs += "\n// #instance: %s (%s)\n" % [ get_hier_name(), genname ]
				rv.defs += replace_variables(shader_model_preprocessed.instance, variables, rv, context)
				rv.defs += "\n\n"
	# Add inline code
	if shader_model_preprocessed.has("code") and output[output.type].find("@NOCODE") == -1:
		var variant_index = context.get_variant(self, uv)
		var genname_uv : String = genname+"_"+str(context.get_variant(self, uv))
		variables["name_uv"] = genname_uv
		if variant_index == -1:
			var code : String = replace_variables(shader_model_preprocessed.code, variables, rv, context)
			if code != "":
				rv.code += "\n// #code: %s (%s)\n" % [ get_hier_name(), genname ]
				rv.code += code
	# Add output_code
	var variant_string = uv+","+str(output_index)
	var variant_index = context.get_variant(self, variant_string)
	var assign_output : bool = false
	if variant_index == -1:
		variant_index = context.get_variant(self, variant_string)
		assign_output = true
	var use_alias : bool = false
	for f in mm_io_types.types.keys():
		if output.has(f):
			var output_string = output[f].replace("@NOCODE", "").replace("@KEEPTYPE", "").strip_edges()
			var expression = replace_variables(output_string, variables, rv, context)
			if rv.alias != null and output[f].find("@KEEPTYPE") != -1:
					use_alias = true
			if not use_alias:
				var variable_name : String = "%s_%d_%d_%s" % [ genname, output_index, variant_index, f ]
				if assign_output:
					rv.code += "\n// #output%d: %s (%s)\n" % [ output_index, get_hier_name(), genname ]
					rv.code += "%s %s = %s;\n" % [ mm_io_types.types[f].type, variable_name, expression ]
				rv.output_values[f] = variable_name
	
	if use_alias:
		rv.output_values = rv.alias.output_values
		rv.output_type   = rv.alias.output_type
	else:
		rv.output_type = output.type
	
	return rv

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

func do_edit(node, edit_window_scene : PackedScene, tab : String = "") -> void:
	if shader_model != null:
		var edit_window = edit_window_scene.instantiate()
		mm_globals.main_window.add_dialog(edit_window)
		edit_window.set_model_data(get_shader_model_for_edit())
		edit_window.connect("node_changed", Callable(node, "update_shader_generator"))
		edit_window.connect("popup_hide", Callable(edit_window, "queue_free"))
		edit_window.get_window().content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
		edit_window.get_window().min_size = Vector2(950, 450) * edit_window.get_window().content_scale_factor
		edit_window.hide()
		edit_window.popup_centered()
		if tab != "":
			edit_window.show_tab(tab)

func edit(node, tab : String = "") -> void:
	do_edit(node, load("res://material_maker/windows/node_editor/node_editor.tscn"), tab)
