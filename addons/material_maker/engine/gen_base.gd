tool
extends Node
class_name MMGenBase

"""
Base class for texture generators, that defines their API
"""

signal parameter_changed

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

const PORT_TYPES : Dictionary = {
	rgba  = { type="vec4", paramdefs="vec2 uv", params="uv" },
	rgb   = { type="vec3", paramdefs="vec2 uv", params="uv" },
	f     = { type="float", paramdefs="vec2 uv", params="uv" },
	sdf2d = { type="float", paramdefs="vec2 uv", params="uv" },
	sdf3d = { type="float", paramdefs="vec3 p", params="p" }
}

func _ready() -> void:
	init_parameters()

func _post_load() -> void:
	pass

func can_be_deleted() -> bool:
	return true

func toggle_editable() -> bool:
	return false

func is_editable() -> bool:
	return false


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
	if has_randomness() and !is_seed_locked():
		source_changed(0)

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

func set_parameter(n : String, v) -> void:
	parameters[n] = v
	source_changed(0)
	emit_signal("parameter_changed", n, v)

func notify_output_change(output_index : int) -> void:
	var targets = get_targets(output_index)
	for target in targets:
		target.generator.source_changed(target.input_index)

func source_changed(__) -> void:
	emit_signal("parameter_changed", "__input_changed__", 0)
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
	if parent != null:
		return get_parent().get_port_targets(name, output_index)
	return []

# get the list of outputs that depend on the input whose index is passed as parameter
func follow_input(input_index : int) -> Array:
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

func render(output_index : int, size : int, preview : bool = false) -> Object:
	var context : MMGenContext = MMGenContext.new()
	var source = get_shader_code("uv", output_index, context)
	while source is GDScriptFunctionState:
		source = yield(source, "completed")
	if source.empty():
		source = { defs="", code="", textures={}, rgba="vec4(0.0)" }
	var shader : String
	if preview:
		shader = mm_renderer.generate_preview_shader(source)
	else:
		shader = mm_renderer.generate_shader(source)
	var result = mm_renderer.render_shader(shader, source.textures, size)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result

func get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var rv = _get_shader_code(uv, output_index, context)
	while rv is GDScriptFunctionState:
		rv = yield(rv, "completed")
	if !rv.empty():
		if !rv.has("f"):
			if rv.has("rgb"):
				rv.f = "(dot("+rv.rgb+", vec3(1.0))/3.0)"
			elif rv.has("rgba"):
				rv.f = "(dot("+rv.rgba+".rgb, vec3(1.0))/3.0)"
		if !rv.has("rgb"):
			if rv.has("rgba"):
				rv.rgb = rv.rgba+".rgb"
			elif rv.has("f"):
				rv.rgb = "vec3("+rv.f+")"
		if !rv.has("rgba"):
			if rv.has("rgb"):
				rv.rgba = "vec4("+rv.rgb+", 1.0)"
	return rv

func _get_shader_code(__, __, __) -> Dictionary:
	return {}


func _serialize(data: Dictionary) -> Dictionary:
	print("cannot save "+name)
	return data

func serialize() -> Dictionary:
	var rv = { name=name, type=get_type(), parameters={}, node_position={ x=position.x, y=position.y } }
	for p in parameters.keys():
		rv.parameters[p] = MMType.serialize_value(parameters[p])
	if seed_locked:
		rv.seed_value = seed_value
	if model != null:
		rv.type = model
	else:
		rv = _serialize(rv)
	return rv

func _deserialize(data : Dictionary) -> void:
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
	_post_load()
