tool
extends Node
class_name MMGenBase

"""
Base class for texture generators, that defines their API
"""

signal parameter_changed(n, v)
signal rendering_time(t)

const DEFAULT_GENERATED_SHADER : Dictionary = { defs="", code="", textures={}, type="f", f="0.0" }

class InputPort:
	var generator : MMGenBase = null
	var input_index : int = 0

	func _init(g : MMGenBase, i : int) -> void:
		generator = g
		input_index = i

	func to_str() -> String:
		return generator.name+".in("+str(input_index)+")"

class OutputPort:
	var generator : MMGenBase = null
	var output_index : int = 0

	func _init(g : MMGenBase, o : int) -> void:
		generator = g
		output_index = o

	func to_str() -> String:
		return generator.name+".out("+str(output_index)+")"

var position : Vector2 = Vector2(0, 0)
var model = null
var parameters = {}

var seed_locked : bool = false
var seed_value : int = 0

var preview : int = -1
var minimized : bool = false

func _ready() -> void:
	init_parameters()

func _post_load() -> void:
	pass

func get_hier_name() -> String:
	if get_parent().is_class("MMGenBase"):
		return get_parent().get_hier_name()+"/"+name
	return name

func accept_float_expressions() -> bool:
	return true

func can_be_deleted() -> bool:
	return true

func toggle_editable() -> bool:
	return false

func is_template() -> bool:
	return model != null

func get_template_name() -> bool:
	return model

func is_editable() -> bool:
	return false

func get_description() -> String:
	return ""

func has_randomness() -> bool:
	return false

func get_seed() -> int:
	if !seed_locked:
		var s : int = ((int(position.x) * 0x1f1f1f1f) ^ int(position.y)) % 65536
		if get_parent().get("transmits_seed") != null and get_parent().transmits_seed:
			s += get_parent().get_seed()
		return s
	else:
		return seed_value

func toggle_lock_seed() -> bool:
	if !seed_locked:
		seed_value = get_seed()
	seed_locked = !seed_locked
	return seed_locked

func is_seed_locked() -> bool:
	return seed_locked

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
	if has_randomness() and !is_seed_locked() and is_inside_tree():
		get_tree().call_group("preview", "on_float_parameters_changed", { "seed_o"+str(get_instance_id()): get_seed() })

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
		return get_parameter_def(n).default

class CustomGradientSorter:
	static func compare(a, b) -> bool:
		return a.pos < b.pos

func set_parameter(n : String, v) -> void:
	var old_value = parameters[n] if parameters.has(n) else null
	parameters[n] = v
	emit_signal("parameter_changed", n, v)
	if is_inside_tree():
		var parameter_def : Dictionary = get_parameter_def(n)
		if parameter_def.has("type"):
			if parameter_def.type == "float" and v is float and old_value is float:
				var parameter_name = "p_o"+str(get_instance_id())+"_"+n
				get_tree().call_group("preview", "on_float_parameters_changed", { parameter_name:v })
				return
			elif parameter_def.type == "color":
				var parameter_changes = {}
				for f in [ "r", "g", "b", "a" ]:
					var parameter_name = "p_o"+str(get_instance_id())+"_"+n+"_"+f
					parameter_changes[parameter_name] = v[f]
				get_tree().call_group("preview", "on_float_parameters_changed", parameter_changes)
				return
			elif parameter_def.type == "gradient":
				if old_value is MMGradient and v is MMGradient and old_value != null and v.interpolation == old_value.interpolation and v.points.size() == old_value.points.size():
					old_value.sort()
					v.sort()
					var parameter_changes = {}
					for i in range(old_value.points.size()):
						if v.points[i].v != old_value.points[i].v:
							var parameter_name = "p_o%s_%s_%d_pos" % [ str(get_instance_id()), n, i ]
							parameter_changes[parameter_name] = v.points[i].v
						for f in [ "r", "g", "b", "a" ]:
							if v.points[i].c[f] != old_value.points[i].c[f]:
								var parameter_name = "p_o%s_%s_%d_%s" % [ str(get_instance_id()), n, i, f ]
								parameter_changes[parameter_name] = v.points[i].c[f]
					get_tree().call_group("preview", "on_float_parameters_changed", parameter_changes)
					return
		all_sources_changed()

func notify_output_change(output_index : int) -> void:
	var targets = get_targets(output_index)
	for target in targets:
		target.generator.source_changed(target.input_index)
	emit_signal("parameter_changed", "__output_changed__", output_index)

func source_changed(input_index : int) -> void:
	emit_signal("parameter_changed", "__input_changed__", input_index)
	for i in range(get_output_defs().size()):
		notify_output_change(i)

func all_sources_changed() -> void:
	for input_index in get_input_defs().size():
		emit_signal("parameter_changed", "__input_changed__", input_index)
	for i in range(get_output_defs().size()):
		notify_output_change(i)

func get_input_defs() -> Array:
	return []

func get_output_defs() -> Array:
	return []

func get_source(input_index : int) -> OutputPort:
	return get_parent().get_port_source(name, input_index)

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

func get_input_shader(input_index : int) -> Dictionary:
	var source = get_source(input_index)
	if source != null:
		return source.get_shader()
	return {}

func get_shader(output_index : int, context) -> Dictionary:
	return get_shader_code("UV", output_index, context)

static func generate_preview_shader(src_code, type, main_fct = "void fragment() { COLOR = preview_2d(UV); }") -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
	code += "uniform float preview_size = 64;\n"
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	code += file.get_as_text()
	code += "\n"
	if src_code.has("textures"):
		for t in src_code.textures.keys():
			code += "uniform sampler2D "+t+";\n"
	if src_code.has("globals"):
		for g in src_code.globals:
			code += g
	var shader_code = src_code.defs
	if src_code.has(type):
		var preview_code : String = mm_io_types.types[type].preview
		preview_code = preview_code.replace("$(code)", src_code.code)
		preview_code = preview_code.replace("$(value)", src_code[type])
		shader_code += preview_code
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	code += main_fct
	return code

func render(object: Object, output_index : int, size : int, preview : bool = false) -> Object:
	var context : MMGenContext = MMGenContext.new()
	var source = get_shader_code("uv", output_index, context)
	while source is GDScriptFunctionState:
		source = yield(source, "completed")
	if source.empty():
		source = DEFAULT_GENERATED_SHADER
	var shader : String
	if preview:
		var output_type = "rgba"
		var outputs = get_output_defs()
		if outputs.size() > output_index:
			output_type = outputs[output_index].type
		shader = generate_preview_shader(source, output_type)
	else:
		shader = mm_renderer.generate_shader(source)
	var renderer = mm_renderer.request(object)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer = renderer.render_shader(object, shader, source.textures, size)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	return renderer

func get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var rv = _get_shader_code(uv, output_index, context)
	while rv is GDScriptFunctionState:
		rv = yield(rv, "completed")
	if rv.has("type") and mm_io_types.types.has(rv.type):
		if mm_io_types.types[rv.type].has("convert"):
			for c in mm_io_types.types[rv.type].convert:
				if !rv.has(c.type):
					var expr = c.expr.replace("$(value)", rv[rv.type])
					rv[c.type] = expr
	else:
		print("Missing type for node ")
		print(rv)
	return rv

func _get_shader_code(_uv, _output_index, _context) -> Dictionary:
	return {}


func _serialize(data: Dictionary) -> Dictionary:
	print("cannot save "+name)
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
	if seed_locked:
		rv.seed_value = seed_value
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
	_deserialize(data)
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
	if data.has("seed_value"):
		seed_locked = true
		seed_value = data.seed_value
	else:
		seed_locked = false
	preview = data.preview if data.has("preview") else -1
	minimized = data.has("minimized") and data.minimized
	_post_load()


static func define_shader_float_parameters(code : String, material : ShaderMaterial) -> void:
	var regex = RegEx.new()
	regex.compile("uniform\\s+(\\w+)\\s+([\\w_\\d]+)\\s*=\\s*([^;]+);")
	for p in regex.search_all(code):
		material.set_shader_param(p.strings[2], float(p.strings[3]))
