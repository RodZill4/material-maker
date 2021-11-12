tool
extends MMGenBase
class_name MMGenShader


var shader_model : Dictionary = {}
var shader_model_preprocessed : Dictionary = {}
var model_uses_seed = false
var params_use_seed = false

var editable = false

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
	if shader_model == null or !shader_model.has("parameters"):
		return []
	else:
		return shader_model.parameters

func set_parameter(n : String, v) -> void:
	var old_value = parameters[n] if parameters.has(n) else null
	.set_parameter(n, v)
	var had_rnd : bool = false
	if old_value is String and old_value.find("$rnd(") != -1:
		had_rnd = true
	var has_rnd : bool = false
	if v is String and v.find("$rnd(") != -1:
		has_rnd = true
	if had_rnd != has_rnd:
		var use_seed : bool = false
		for k in parameters.keys():
			if parameters[k] is String and parameters[k].find("$rnd(") != -1:
				use_seed = true
				break
		if params_use_seed != use_seed:
			params_use_seed = use_seed
			if is_inside_tree():
				get_tree().call_group("generator_node", "on_generator_changed", self)

func get_input_defs() -> Array:
	if shader_model == null or !shader_model.has("inputs"):
		return []
	else:
		return shader_model.inputs

func get_output_defs(_show_hidden : bool = false) -> Array:
	if shader_model == null or !shader_model.has("outputs"):
		return []
	else:
		return shader_model.outputs


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
		if data.has("code"):
			preprocessed.code = data.code
		if data.has("parameters"):
			preprocessed.parameters = data.parameters
		if data.has("outputs"):
			preprocessed.outputs = data.outputs
	return preprocessed

func set_shader_model(data: Dictionary) -> void:
	shader_model = data
	shader_model_preprocessed = preprocess_shader_model(data)
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
	if get_parent() != null:
		get_parent().check_input_connects(self)
	all_sources_changed()

func find_matching_parenthesis(string : String, i : int) -> int:
	var parenthesis_level = 0
	var length : int = string.length()
	while i < length:
		var c = string[i]
		if c == '(':
			parenthesis_level += 1
		elif c == ')':
			parenthesis_level -= 1
			if parenthesis_level == 0:
				return i
		i += 1
		var next_op = string.find("(", i)
		var next_cp = string.find(")", i)
		var max_p = max(next_op, next_cp)
		if max_p < 0:
			return length
		var min_p = min(next_op, next_cp)
		i = max_p if min_p < 0 else min_p
	return i

func find_keyword_call(string, keyword):
	var search_string = "$%s(" % keyword
	var position = string.find(search_string)
	if position == -1:
		return null
	var parameter_begin = position+search_string.length()
	var end = find_matching_parenthesis(string, parameter_begin-1)
	if end < string.length():
		return string.substr(parameter_begin, end-parameter_begin)
	return ""

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
	var required_textures = {}
	var required_pending_textures = []
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
			assert(! (src_code is GDScriptFunctionState))
			while src_code is GDScriptFunctionState:
				src_code = yield(src_code, "completed")
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
		# Add textures
		if src_code.has("textures"):
			required_textures = src_code.textures
		if src_code.has("pending_textures"):
			required_pending_textures = src_code.pending_textures
		string = string.replace("$%s(%s)" % [ input, uv ], src_code.string)
	return { string=string, globals=required_globals, defs=required_defs, code=required_code, textures=required_textures, pending_textures=required_pending_textures, new_pass_required=new_pass_required }

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

func replace_variables(string : String, variables : Dictionary) -> String:
	while true:
		var old_string = string
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
	var genname = "o"+str(get_instance_id())
	var required_globals = [ get_parent().get_globals() ]
	var required_defs = ""
	var required_code = ""
	var required_textures = {}
	var required_pending_textures = []
	# Named parameters from parent graph are specified first so they don't
	# hide locals
	var variables = get_parent().get_named_parameters()
	variables["name"] = genname
	if uv != "":
		var genname_uv = genname+"_"+str(context.get_variant(self, uv))
		variables["name_uv"] = genname_uv
	if seed_locked:
		variables["seed"] = "seed_"+genname
	else:
		variables["seed"] = "(seed_"+genname+"+_seed_variation_)"
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
				elif parameters[p.name] is String:
					value_string = "("+replace_rnd(parameters[p.name], rnd_offset)+")"
				else:
					print("Error in float parameter "+p.name)
					value_string = "0.0"
				rnd_offset += 17
			elif p.type == "size":
				value_string = "%.9f" % pow(2, value)
			elif p.type == "enum":
				if value < 0 or value >= p.values.size():
					value = 0
				value_string = p.values[value].value
			elif p.type == "color":
				value_string = "vec4(p_%s_%s_r, p_%s_%s_g, p_%s_%s_b, p_%s_%s_a)" % [ genname, p.name, genname, p.name, genname, p.name, genname, p.name ]
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
	if shader_model.has("inputs") and typeof(shader_model.inputs) == TYPE_ARRAY:
		for i in range(shader_model.inputs.size()):
			var input = shader_model.inputs[i]
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
	if shader_model.has("inputs") and typeof(shader_model.inputs) == TYPE_ARRAY:
		var cont = true
		while cont:
			var changed = false
			var new_pass_required = false
			for i in range(shader_model.inputs.size()):
				var input = shader_model.inputs[i]
				var source = get_source(i)
				if input.has("function") and input.function:
					string = replace_input_with_function_call(string, input.name)
					string = replace_input_with_function_call(string, input.name, "", ".variation")
				else:
					var result = replace_input(string, context, input.name, input.type, source, input.default)
					assert(! (result is GDScriptFunctionState))
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
					for t in result.pending_textures:
						if required_pending_textures.find(t) == -1:
							required_pending_textures.push_back(t)
			cont = changed and new_pass_required
			string = replace_variables(string, variables)
	return { string=string, globals=required_globals, defs=required_defs, code=required_code, textures=required_textures, pending_textures=required_pending_textures }

func generate_parameter_declarations(rv : Dictionary):
	var genname = "o"+str(get_instance_id())
	if has_randomness():
		rv.defs += "uniform float seed_%s = %.9f;\n" % [ genname, get_seed() ]
	for p in shader_model_preprocessed.parameters:
		if p.type == "float" and parameters[p.name] is float:
			rv.defs += "uniform float p_%s_%s = %.9f;\n" % [ genname, p.name, parameters[p.name] ]
		elif p.type == "color":
			rv.defs += "uniform float p_%s_%s_r = %.9f;\n" % [ genname, p.name, parameters[p.name].r ]
			rv.defs += "uniform float p_%s_%s_g = %.9f;\n" % [ genname, p.name, parameters[p.name].g ]
			rv.defs += "uniform float p_%s_%s_b = %.9f;\n" % [ genname, p.name, parameters[p.name].b ]
			rv.defs += "uniform float p_%s_%s_a = %.9f;\n" % [ genname, p.name, parameters[p.name].a ]
		elif p.type == "gradient":
			var g = parameters[p.name]
			if !(g is MMGradient):
				g = MMGradient.new()
				g.deserialize(parameters[p.name])
			var params = g.get_shader_params(genname+"_"+p.name)
			for sp in params.keys():
				rv.defs += "uniform float %s = %.9f;\n" % [ sp, params[sp] ]
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
	if shader_model.has("inputs"):
		for i in range(shader_model.inputs.size()):
			var input = shader_model.inputs[i]
			if input.has("function") and input.function:
				var source = get_source(i)
				var string = "$%s(%s)" % [ input.name, mm_io_types.types[input.type].params ]
				var local_context = MMGenContext.new(context)
				var result = replace_input(string, local_context, input.name, input.type, source, input.default)
				assert(! (result is GDScriptFunctionState))
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
				# Add global definitions
				for d in result.globals:
					if rv.globals.find(d) == -1:
						rv.globals.push_back(d)
				# Add generated definitions
				rv.defs += result.defs
				# Add textures
				for t in result.textures.keys():
					rv.textures[t] = result.textures[t]
				for t in result.pending_textures:
					if rv.pending_textures.find(t) == -1:
						rv.pending_textures.push_back(t)
				rv.defs += "%s %s_input_%s(%s, float _seed_variation_) {\n" % [ mm_io_types.types[input.type].type, genname, input.name, mm_io_types.types[input.type].paramdefs ]
				rv.defs += "%s\n" % result.code
				rv.defs += "return %s;\n}\n" % result.string
	return rv

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var rv = { globals=[], defs="", code="", textures={}, pending_textures=[] }
	if shader_model_preprocessed != null and shader_model_preprocessed.has("outputs") and shader_model_preprocessed.outputs.size() > output_index:
		var output = shader_model_preprocessed.outputs[output_index]
		if !context.has_variant(self):
			# Generate parameter declarations
			rv = generate_parameter_declarations(rv)
			# Generate functions for inputs
			rv = generate_input_declarations(rv, context)
			if shader_model_preprocessed.has("instance"):
				var subst_output = subst(shader_model_preprocessed.instance, context, "")
				assert(! (subst_output is GDScriptFunctionState))
				while subst_output is GDScriptFunctionState:
					subst_output = yield(subst_output, "completed")
				rv.defs += subst_output.string
				# process textures
				for t in subst_output.textures.keys():
					rv.textures[t] = subst_output.textures[t]
				for t in subst_output.pending_textures:
					if rv.pending_textures.find(t) == -1:
						rv.pending_textures.push_back(t)
		# Add inline code
		if shader_model_preprocessed.has("code"):
			var variant_index = context.get_variant(self, uv)
			if variant_index == -1:
				variant_index = context.get_variant(self, uv)
				var subst_code = subst(shader_model_preprocessed.code, context, uv)
				assert(! (subst_code is GDScriptFunctionState))
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
				# process textures
				for t in subst_code.textures.keys():
					rv.textures[t] = subst_code.textures[t]
				for t in subst_code.pending_textures:
					if rv.pending_textures.find(t) == -1:
						rv.pending_textures.push_back(t)
		# Add output_code
		var variant_string = uv+","+str(output_index)
		var variant_index = context.get_variant(self, variant_string)
		if variant_index == -1:
			variant_index = context.get_variant(self, variant_string)
			for f in mm_io_types.types.keys():
				if output.has(f):
					var subst_output = subst(output[f], context, uv)
					assert(! (subst_output is GDScriptFunctionState))
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
					rv.code += "%s %s_%d_%d_%s = %s;\n" % [ mm_io_types.types[f].type, genname, output_index, variant_index, f, subst_output.string ]
					# Textures
					for t in subst_output.textures.keys():
						rv.textures[t] = subst_output.textures[t]
					for t in subst_output.pending_textures:
						if rv.pending_textures.find(t) == -1:
							rv.pending_textures.push_back(t)
		for f in mm_io_types.types.keys():
			if output.has(f):
				rv[f] = "%s_%d_%d_%s" % [ genname, output_index, variant_index, f ]
		rv.type = output.type
		if shader_model.has("includes"):
			for i in shader_model.includes:
				var g = mm_loader.get_predefined_global(i)
				if g != "" and rv.globals.find(g) == -1:
					rv.globals.push_back(g)
		if shader_model.has("global") and rv.globals.find(shader_model.global) == -1:
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
		var edit_window = load("res://material_maker/windows/node_editor/node_editor.tscn").instance()
		node.get_parent().add_child(edit_window)
		edit_window.set_model_data(shader_model)
		edit_window.connect("node_changed", node, "update_generator")
		edit_window.connect("popup_hide", edit_window, "queue_free")
		edit_window.popup_centered()
