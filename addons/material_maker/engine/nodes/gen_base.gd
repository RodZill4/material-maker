@tool
extends Node
class_name MMGenBase


# Base class for texture generators, that defines their API


class InputPort:
	extends RefCounted
	var generator : MMGenBase = null
	var input_index : int = 0

	func _init(g : MMGenBase, i : int) -> void:
		generator = g
		input_index = i

	func to_str() -> String:
		return str(generator.name)+".in("+str(input_index)+")"

class OutputPort:
	extends RefCounted
	var generator : MMGenBase = null
	var output_index : int = 0

	func _init(g : MMGenBase, o : int) -> void:
		generator = g
		output_index = o

	func to_str() -> String:
		return str(generator.name)+".out("+str(output_index)+")"

class ShaderUniform:
	extends RefCounted
	var name : String
	var type : String
	var size : int
	var value
	
	func _init(n : String, t : String, v, s : int = 0) -> void:
		name = n
		type = t
		size = s
		value = v
	
	func to_str(keyword : String = "uniform", initialize_vectors : bool = false, texture_hints : bool = false) -> String:
		var str_value_assign : String = ""
		match type:
			"int":
				if value is int:
					str_value_assign = " = %d" % value
				elif value is PackedInt32Array and initialize_vectors:
					str_value_assign = " = int[]( "
					var first : bool = true
					for v in value:
						if first:
							first = false
						else:
							str_value_assign += ", "
						str_value_assign += "%d" % v
					str_value_assign += " )"
			"float":
				if value is float:
					str_value_assign = " = %.9f" % value
				elif value is PackedFloat32Array and initialize_vectors:
					str_value_assign = " = float[]( "
					var first : bool = true
					for v in value:
						if first:
							first = false
						else:
							str_value_assign += ", "
						str_value_assign += "%.9f" % v
					str_value_assign += " )"
			"vec2":
				if value is PackedFloat32Array and initialize_vectors:
					str_value_assign = " = vec2[]( "
					var first : bool = true
					for i in range(0, value.size(), 2):
						if first:
							first = false
						else:
							str_value_assign += ", "
						str_value_assign +="vec2(%.9f, %.9f)" % [ value[i], value[i+1] ]
					str_value_assign += " )"
				elif value is PackedVector2Array and initialize_vectors:
					str_value_assign = " = vec2[]( "
					var first : bool = true
					for v in value:
						if first:
							first = false
						else:
							str_value_assign += ", "
						str_value_assign +="vec2(%.9f, %.9f)" % [ v.x, v.y ]
					str_value_assign += " )"
			"vec4":
				if value is Color:
					str_value_assign = " = vec4(%.9f, %.9f, %.9f, %.9f)" % [ value.r, value.g, value.b, value.a ]
				elif value is PackedFloat32Array and initialize_vectors:
					str_value_assign = " = vec4[]( "
					var first : bool = true
					for i in range(0, value.size(), 4):
						if first:
							first = false
						else:
							str_value_assign += ", "
						str_value_assign +="vec4(%.9f, %.9f, %.9f, %.9f)" % [ value[i], value[i+1], value[i+2], value[i+3] ]
					str_value_assign += " )"
				elif value is PackedColorArray and initialize_vectors:
					str_value_assign = " = vec4[]( "
					var first : bool = true
					for v in value:
						if first:
							first = false
						else:
							str_value_assign += ", "
						str_value_assign +="vec4(%.9f, %.9f, %.9f, %.9f)" % [ v.r, v.g, v.b, v.a ]
					str_value_assign += " )"
			"sampler2D":
				if texture_hints:
					str_value_assign = " : repeat_enable"
		var size_string : String = ""
		if size > 0:
			size_string = "[%d]" % size
		return "%s %s %s%s%s;\n" % [ keyword, type, name, size_string, str_value_assign ]

class GlobalDefs:
	var code : String
	var source : String

	func _init(c, s):
		code = c
		source = s

class ShaderCode:
	extends RefCounted
	var globals : Array[GlobalDefs] = []
	var uniforms : Array[ShaderUniform] = []
	var defs : String = ""
	var code : String = ""
	var textures : Dictionary = {}
	var output_type : String = ""
	var output_values : Dictionary = {}
	var alias : ShaderCode = null
	
	func add_global(new_global : String, source: String, index : int = -1) -> void:
		for eg in globals:
			if new_global == eg.code:
				return
		if index == -1:
			globals.append(GlobalDefs.new(new_global, source))
		else:
			globals.insert(index, GlobalDefs.new(new_global, source))
	
	func add_globals(new_globals : Array[GlobalDefs]) -> void:
		for g in new_globals:
			add_global(g.code, g.source)
	
	func get_globals_string(code : String = "") -> String:
		var rv : String = ""
		if true:
			var reverse_globals : Array[GlobalDefs] = globals.duplicate()
			reverse_globals.reverse()
			for g in reverse_globals:
				var added_declaration : bool = false
				var reverse_declarations = MMGenBase.split_glsl(g.code)
				reverse_declarations.reverse()
				for d in reverse_declarations:
					var declaration_name : String = MMGenBase.get_glsl_declaration_name(d)
					if code == "" or declaration_name == "" or code.find(declaration_name) != -1 or rv.find(declaration_name) != -1:
						rv = "\n// '" + declaration_name + "'\n" + d + "\n" + rv
						added_declaration = true
				if added_declaration:
					rv = ("// #globals: %s\n" % g.source) + rv
		else:
			for g in globals:
				rv += g.code
				rv += "\n"
		return rv
	
	func add_uniform(n : String, t : String, v, s : int = 0) -> void:
		for u in uniforms:
			if n == u.name:
				return
		uniforms.append(ShaderUniform.new(n, t, v, s))

	func add_uniforms(uniform_list : Array[ShaderUniform]) -> void:
		for u in uniform_list:
			add_uniform(u.name, u.type, u.value, u.size)

	func uniforms_as_strings(keyword : String = "uniform", initialize_vectors : bool = false, texture_hints : bool = false) -> String:
		var rv : String = ""
		for u in uniforms:
			rv += u.to_str(keyword, initialize_vectors, texture_hints)
		return rv

var position : Vector2 = Vector2(0, 0)
var model = null
var orig_name = null
var parameters = {}

var seed_locked : bool = false
var seed_value : float = 0

var rendering_time : int = 0

var preview : int = -1
var minimized : bool = false


const MAX_SEED : int = 4294967296

const BUFFERS_ALL     : int = 0
const BUFFERS_PAUSED  : int = 1
const BUFFERS_RUNNING : int = 2



signal parameter_changed(n, v)
signal rendering_time_updated(t)


func _ready() -> void:
	init_parameters()

static func get_default_generated_shader() -> ShaderCode:
	var rv : ShaderCode = ShaderCode.new()
	rv.output_type = "rgba"
	rv.output_values.f = "0.0"
	rv.output_values.rgb = "vec3(0.0)"
	rv.output_values.rgba = "vec4(0.0, 0.0, 0.0, 0.0)"
	return rv

func _post_load() -> void:
	pass

func get_hier_name() -> String:
	if not get_parent() is MMGenBase:
		return ""
	var rv = name
	var node = self
	while true:
		node = node.get_parent()
		if not node.get_parent() is MMGenBase:
			break
		rv = node.name+"/"+rv
	return rv

func accept_float_expressions() -> bool:
	return true

func can_be_deleted() -> bool:
	return true

func toggle_editable() -> bool:
	return false

func is_template() -> bool:
	return model != null

func get_template_name():
	return model

func is_editable() -> bool:
	return false

func get_description() -> String:
	return ""

func has_randomness() -> bool:
	return false

func set_seed(s : float) -> bool:
	if !has_randomness() or is_seed_locked():
		return false
	seed_value = s
	mm_deps.dependencies_update({ "seed_o"+str(get_instance_id()): get_seed() })
	return true

func reroll_seed():
	set_seed(randf())

func get_seed_from_position(p) -> int:
	return ((int(p.x) * 0x1f1f1f1f) ^ int(p.y)) % 65536

func get_seed() -> float:
	var s : float = seed_value
	if !seed_locked and get_parent().get("transmits_seed") != null and get_parent().transmits_seed:
		s += get_parent().get_seed()
	return s

func toggle_lock_seed() -> bool:
	seed_locked = !seed_locked
	return seed_locked

func is_seed_locked() -> bool:
	return seed_locked

func get_buffers(flags : int = BUFFERS_ALL) -> Array:
	return []

func init_parameters() -> void:
	for p in get_parameter_defs():
		if !parameters.has(p.name):
			if p.has("default"):
				parameters[p.name] = MMType.deserialize_value(p.default)
				if p.type == "size":
					parameters[p.name] -= p.first
			else:
				print("No default value for parameter "+p.name)

func set_position(p) -> void:
	position = p

func get_type() -> String:
	return "generic"

func get_type_name() -> String:
	return "Unnamed"

func get_parameter_defs() -> Array:
	return []

func get_parameter_def(param_name : String) -> Dictionary:
	var parameter_defs = get_parameter_defs()
	for p in parameter_defs:
		if p.name == param_name:
			return p
	return {}

func get_parameter(n : String):
	if parameters.has(n):
		return parameters[n]
	else:
		var parameter_def = get_parameter_def(n)
		return parameter_def.default

func calculate_float_parameter(n : String) -> Dictionary:
	var return_value : Dictionary = {}
	var value = get_parameter(n)
	if value is float:
		return_value.value = value
	elif value is String:
		var parent : Node = get_parent()
		if parent.has_method("get_named_parameters"):
			return_value.used_named_parameters = []
			var named_parameters : Dictionary = get_parent().get_named_parameters()
			for np in named_parameters.keys():
				if value.find("$"+np) != -1:
					return_value.used_named_parameters.push_back(named_parameters[np].id)
					value = value.replace("$"+np, str(named_parameters[np].value))
		var expression : Expression = Expression.new()
		var error = expression.parse(value, [])
		if error == OK:
			return_value.value = expression.execute()
	return return_value

class CustomGradientSorter:
	static func compare(a, b) -> bool:
		return a.pos < b.pos

func set_parameter(n : String, v) -> void:
	var old_value = parameters[n] if parameters.has(n) else null
	if typeof(old_value) == typeof(v) and old_value == v:
		return
	parameters[n] = v
	emit_signal("parameter_changed", n, v)
	if is_inside_tree():
		var parameter_def : Dictionary = get_parameter_def(n)
		if parameter_def.has("type"):
			if parameter_def.type == "float" and v is float and old_value is float:
				var parameter_name = "p_o"+str(get_instance_id())+"_"+n
				mm_deps.dependencies_update({ parameter_name:v })
				return
			elif parameter_def.type == "color":
				mm_deps.dependency_update("p_o"+str(get_instance_id())+"_"+n, v)
				return
			elif parameter_def.type == "gradient":
				if old_value is MMGradient and v is MMGradient and old_value != null:
					if old_value.interpolation == v.interpolation and old_value.points.size() == v.points.size():
						# Only values changed, no need to regenerate the shader
						mm_deps.dependencies_update(v.get_parameter_values("o%d_%s" % [ get_instance_id(), n ]))
						return
			elif parameter_def.type == "polyline" or parameter_def.type == "polygon":
				if old_value is Dictionary:
					old_value = MMType.deserialize_value(old_value)
				if v is Dictionary:
					v = MMType.deserialize_value(v)
				if old_value is MMPolygon and v is MMPolygon and old_value != null:
					if old_value.points.size() == v.points.size():
						# Only values changed, no need to regenerate the shader
						mm_deps.dependencies_update(v.get_parameter_values("o%d_%s" % [ get_instance_id(), n ]))
						return
			elif parameter_def.type == "curve":
				if old_value is MMCurve and v is MMCurve and old_value != null:
					var parameter_changes = {}
					for i in range(v.points.size()):
						for f in [ "x", "y" ]:
							if i >= old_value.points.size() or v.points[i].p[f] != old_value.points[i].p[f]:
								var parameter_name = "p_o%d_%s_%d_%s" % [ get_instance_id(), n, i, f ]
								parameter_changes[parameter_name] = v.points[i].p[f]
						for f in [ "ls", "rs" ]:
							if i >= old_value.points.size() or v.points[i][f] != old_value.points[i][f]:
								var parameter_name = "p_o%d_%s_%d_%s" % [ get_instance_id(), n, i, f ]
								parameter_changes[parameter_name] = v.points[i][f]
					mm_deps.dependencies_update(parameter_changes)
					if old_value.points.size() == v.points.size():
						return
			elif parameter_def.type == "splines":
				if old_value is Dictionary:
					old_value = MMType.deserialize_value(old_value)
				if v is Dictionary:
					v = MMType.deserialize_value(v)
				if old_value is MMSplines and v is MMSplines and old_value != null:
					if old_value.splines.size() == v.splines.size():
						# Only values changed, no need to regenerate the shader
						mm_deps.dependencies_update(v.get_parameter_values("o%d_%s" % [ get_instance_id(), n ]))
						return
			elif parameter_def.type == "pixels":
				if v is Dictionary:
					v = MMType.deserialize_value(v)
				if old_value is Dictionary:
					old_value = MMType.deserialize_value(old_value)
				if old_value is MMPixels and v is MMPixels and old_value != null:
					if old_value.size == v.size and old_value.bpp == v.bpp:
						mm_deps.dependencies_update(v.get_parameter_values("o%d_%s" % [ get_instance_id(), n ]))
						return
			elif parameter_def.type == "lattice":
				if old_value is Dictionary:
					old_value = MMType.deserialize_value(old_value)
				if v is Dictionary:
					v = MMType.deserialize_value(v)
				if old_value is MMLattice and v is MMLattice and old_value != null:
					if old_value.size == v.size:
						# Only values changed, no need to regenerate the shader
						mm_deps.dependencies_update(v.get_parameter_values("o%d_%s" % [ get_instance_id(), n ]))
						return
		all_sources_changed()

func notify_output_change(output_index : int) -> void:
	var targets = get_targets(output_index)
	for target in targets:
		target.generator.source_changed(target.input_index)
	emit_signal("parameter_changed", "__output_changed__", output_index)

func source_changed(input_index : int) -> void:
	emit_signal("parameter_changed", "__input_changed__", input_index)
	for o in follow_input(input_index):
		notify_output_change(o.output_index)

func all_sources_changed() -> void:
	for input_index in get_input_defs().size():
		emit_signal("parameter_changed", "__input_changed__", input_index)
	for i in range(get_output_defs().size()):
		notify_output_change(i)

func get_input_defs() -> Array:
	return []

func get_output_defs(_show_hidden : bool = false) -> Array:
	return []

func get_source(input_index : int) -> OutputPort:
	var parent : MMGenGraph = get_parent()
	if parent == null:
		return null
	return parent.get_port_source(name, input_index)

func get_targets(output_index : int) -> Array:
	var parent = get_parent()
	if parent != null and parent.has_method("get_port_targets"):
		return parent.get_port_targets(name, output_index)
	return []

# get the list of outputs that depend on the input whose index is passed as parameter
func follow_input(_input_index : int) -> Array:
	var rv = []
	for i in range(get_output_defs().size()):
		rv.push_back(OutputPort.new(self, i))
	return rv

func get_input_shader(input_index : int) -> ShaderCode:
	var source = get_source(input_index)
	if source != null:
		return source.get_shader()
	return ShaderCode.new()

func get_shader(output_index : int, context) -> ShaderCode:
	return get_shader_code("UV", output_index, context)

static func remove_constant_declarations(s : String, constants : Array[String] = [ "PI", "TAU" ]) -> String:
	for c in [ "PI", "TAU" ]:
		var regex : RegEx = RegEx.create_from_string("const\\s+float\\s+%s\\s*=.*?;" % c)
		while true:
			var result : RegExMatch = regex.search(s)
			if result == null:
				break
			s = s.replace(result.strings[0], "")
	return s

static func generate_preview_shader(src_code : ShaderCode, type, main_fct = "void fragment() { COLOR = preview_2d(UV); }") -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled, unshaded;\n"
	code += "uniform float preview_size = 64;\n"
	code += "uniform sampler2D mesh_inv_uv_tex;\n"
	code += "uniform vec3 mesh_aabb_position;\n"
	code += "uniform vec3 mesh_aabb_size;\n"
	code += mm_renderer.common_shader
	code += "\n"
	code += src_code.uniforms_as_strings("uniform", false, true)
	var shader_code = src_code.defs
	if src_code.output_type != "":
		var preview_code : String = mm_io_types.types[type].preview
		preview_code = preview_code.replace("$(code)", src_code.code)
		preview_code = preview_code.replace("$(value)", src_code.output_values[type])
		shader_code += preview_code
	#print("GENERATED SHADER:\n"+shader_code)
	code += "\n"
	code += src_code.get_globals_string(shader_code+main_fct)
	code += "\n"
	code += shader_code
	code += main_fct
	code = remove_constant_declarations(code)
	return code

func generate_output_shader(output_index : int, preview : bool = false):
	var context : MMGenContext = MMGenContext.new()
	var source : ShaderCode = get_shader_code("uv", output_index, context)
	if source.output_type == "":
		source = get_default_generated_shader()
	var shader : String
	var output_type = "rgba"
	var outputs = get_output_defs(true)
	if outputs.size() > output_index:
		output_type = outputs[output_index].type
	if preview:
		shader = generate_preview_shader(source, output_type)
	else:
		shader = mm_renderer.generate_shader(source)
	return { shader=shader, output_type=output_type }

func render(object: Object, output_index : int, size : int, preview : bool = false) -> Object:
	print("This function is deprecated!")
	var output_shader : Dictionary = generate_output_shader(output_index, preview)
	var shader : String = output_shader.shader
	var output_type : String = output_shader.output_type
	var renderer = await mm_renderer.request(object)
	renderer = await renderer.render_shader(object, shader, size, output_type != "rgba")
	return renderer

func render_output_to_texture(output_index : int, size : Vector2i) -> MMTexture:
	var context : MMGenContext = MMGenContext.new()
	var source : ShaderCode = get_shader_code("uv", output_index, context)
	if source.output_type == "f":
		source.output_type = "rgba"
	if not source.output_values.has("rgba"):
		var preview_code : String = mm_io_types.types[source.output_type].preview
		preview_code = preview_code.replace("uniform", "const")
		preview_code = preview_code.replace("const sampler2D", "uniform sampler2D")
		preview_code = preview_code.replace("preview_size", "64")
		preview_code = preview_code.replace("$(code)", source.code)
		preview_code = preview_code.replace("$(value)", source.output_values[source.output_type])
		source.defs += preview_code
		source.code = ""
		source.output_values.rgba = "preview_2d(uv)"
		source.output_type = "rgba"
	var compute_shader : MMComputeShader = MMComputeShader.new()
	var shader_status : bool = await compute_shader.set_shader_from_shadercode(source, false)
	var texture : MMTexture = MMTexture.new()
	if shader_status:
		var status = await compute_shader.render_ext([texture], size)
	return texture

func render_output(output_index : int, size : Vector2i) -> Image:
	var texture : MMTexture = await render_output_to_texture(output_index, size)
	return (await texture.get_texture()).get_image()

func get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	var rv = _get_shader_code(uv, output_index, context)
	for v in mm_renderer.get_global_parameters():
		var variable_name : String = "mm_global_"+v
		var found : bool = false
		if rv.code.find(variable_name) != -1:
			found = true
		for g in rv.globals:
			if g.code.find(variable_name) != -1:
				found = true
				break
		if found:
			var declaration : String = mm_renderer.get_global_parameter_declaration(v)+";\n"
			rv.add_global(declaration, "global_parameters_declaration", 0)
	if mm_io_types.types.has(rv.output_type):
		if mm_io_types.types[rv.output_type].has("convert"):
			for c in mm_io_types.types[rv.output_type].convert:
				if ! rv.output_values.has(c.type):
					var expr = c.expr.replace("$(value)", rv.output_values[rv.output_type])
					rv.output_values[c.type] = expr
	else:
		print("Missing type for node ")
		print(rv)
	return rv

func get_output_attributes(output_index : int) -> Dictionary:
	return {}

func _get_shader_code(_uv, _output_index, _context) -> ShaderCode:
	return ShaderCode.new()

# Shader generation utility functions

static func find_matching_parenthesis(string : String, i : int, op : String = '(', cp : String = ')') -> int:
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

static var re_line_comment : RegEx = RegEx.create_from_string("//.*")

static func remove_comments(s : String) -> String:
	var cont : bool = true
	while cont:
		cont = false
		var comment_begin : int = s.find("/*")
		if comment_begin != -1:
			var comment_end : int = s.find("*/", comment_begin)
			if comment_end != -1:
				s = s.erase(comment_begin, comment_end-comment_begin+2)
				cont = true
	s = re_line_comment.sub(s, "", true)
	return s

static func split_glsl(s : String) -> Array[String]:
	s = remove_comments(s)
	var a : Array[String] = []
	s = s.strip_edges()
	while s != "":
		var next_semicolon = s.find(";")
		var next_bracket = s.find("{")
		if next_semicolon != -1 and (next_bracket == -1 or next_semicolon < next_bracket):
			a.append(s.left(next_semicolon+1))
			s = s.right(-next_semicolon-1)
		elif next_bracket != -1:
			var closing_bracket = find_matching_parenthesis(s, next_bracket, '{', '}')
			var d : String = s.left(closing_bracket+1)
			s = s.right(-closing_bracket-1)
			s = s.strip_edges()
			if s.length() > 0 and s[0] == ";":
				d += ";"
				s = s.trim_prefix(";")
			a.append(d)
		else:
			print("Error: "+s)
			break
		s = s.strip_edges()
	return a

static func get_glsl_declaration_name(s : String) -> String:
	var words = s.split(" ", false)
	if words.size() > 2 and (words[0] == "const" or words[0] == "uniform" or words[0] == "varying"):
		var d : String = words[2]
		var bracket_pos = d.find("[")
		if bracket_pos >= 0:
			d = d.substr(0, bracket_pos)
		return d
	var split : PackedStringArray = s.split(" ")
	if split.size() > 1:
		split = split[1].split("(")
		if split.size() > 1:
			return split[0]
	return ""

func _serialize(data: Dictionary) -> Dictionary:
	print("cannot save "+str(name))
	return data

func _serialize_data(data: Dictionary) -> Dictionary:
	return data

func serialize() -> Dictionary:
	var rv = { name=name, type=get_type(), parameters={}, node_position={ x=position.x, y=position.y } }
	for p in get_parameter_defs():
		if parameters.has(p.name):
			rv.parameters[p.name] = MMType.serialize_value(parameters[p.name])
		elif p.has("default"):
			rv.parameters[p.name] = p.default
	if seed_value >= 0.0 and seed_value <= 1.0:
		rv.seed_int = int(round(seed_value*MAX_SEED))
	else:
		rv.seed = seed_value
	if seed_locked:
		rv.seed_locked = seed_locked
	if preview >= 0:
		rv.preview = preview
	if minimized:
		rv.minimized = minimized
	if model != null:
		rv.type = model
	else:
		rv = _serialize(rv)
	rv = _serialize_data(rv)
	return rv

func _deserialize(_data : Dictionary) -> void:
	pass

func deserialize(data : Dictionary) -> void:
	await _deserialize(data)
	if data.has("name"):
		name = data.name
	if data.has("node_position"):
		position.x = data.node_position.x
		position.y = data.node_position.y
	if data.has("parameters"):
		for p in data.parameters.keys():
			set_parameter(p, MMType.deserialize_value(data.parameters[p]))
	else:
		for p in get_parameter_defs():
			if data.has(p.name) and p.name != "type":
				set_parameter(p.name, MMType.deserialize_value(data[p.name]))
	seed_locked = false
	if data.has("seed_locked") and data.seed_locked is bool:
		seed_locked = data.seed_locked
	if data.has("seed_int"):
		seed_value = float(data.seed_int)/MAX_SEED
	elif data.has("seed"):
		seed_value = data.seed
	elif data.has("seed_value"):
		seed_locked = true
		seed_value = data.seed_value
	else:
		seed_locked = false
		seed_value = get_seed_from_position(position)
	preview = data.preview if data.has("preview") else -1
	minimized = data.has("minimized") and data.minimized
	_post_load()
