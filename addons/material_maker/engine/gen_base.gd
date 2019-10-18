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
	
	func _init(g : MMGenBase, i : int):
		generator = g
		input_index = i
	
	func to_str():
		return generator.name+".in("+str(input_index)+")"

class OutputPort:
	var generator : MMGenBase = null
	var output_index : int = 0
	
	func _init(g : MMGenBase, o : int):
		generator = g
		output_index = o
	
	func to_str():
		return generator.name+".out("+str(output_index)+")"

var position : Vector2 = Vector2(0, 0)
var model = null
var parameters = {}

func _ready():
	init_parameters()

func can_be_deleted() -> bool:
	return true

func init_parameters():
	for p in get_parameter_defs():
		if !parameters.has(p.name):
			if p.has("default"):
				parameters[p.name] = MMType.deserialize_value(p.default)
				if p.type == "size":
					parameters[p.name] -= p.first
			else:
				print("No default value for parameter "+p.name)

func set_position(p):
	position = p

func get_type():
	return "generic"

func get_type_name():
	return "Unnamed"

func get_parameter_defs():
	return []

func set_parameter(n : String, v):
	parameters[n] = v
	source_changed(0)
	emit_signal("parameter_changed", n, v)

func notify_output_change(output_index : int):
	var targets = get_targets(output_index)
	for target in targets:
		target.generator.source_changed(target.input_index)

func source_changed(__):
	emit_signal("parameter_changed", "__input_changed__", 0)
	for i in range(get_output_defs().size()):
		notify_output_change(i)

func get_input_defs():
	return []

func get_output_defs():
	return []

func get_source(input_index : int):
	return get_parent().get_port_source(name, input_index)
	
func get_targets(output_index : int):
	return get_parent().get_port_targets(name, output_index)

# get the list of outputs that depend on the input whose index is passed as parameter
func follow_input(input_index : int) -> Array:
	var rv = []
	for i in range(get_output_defs().size()):
		rv.push_back(OutputPort.new(self, i))
	return rv

func get_input_shader(input_index : int):
	var source = get_source(input_index)
	if source != null:
		return source.get_shader()

func get_shader(output_index : int, context):
	return get_shader_code("UV", output_index, context);

func render(output_index : int, renderer : MMGenRenderer, size : int):
	var context : MMGenContext = MMGenContext.new(renderer)
	var source = get_shader_code("UV", output_index, context)
	while source is GDScriptFunctionState:
		source = yield(source, "completed")
	if source == null:
		source = { defs="", code="", textures={}, rgba="vec4(0.0)" }
	var shader : String = renderer.generate_shader(source)
	var result = renderer.render_shader(shader, source.textures, size)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result

func get_shader_code(uv : String, output_index : int, context : MMGenContext):
	var rv = _get_shader_code(uv, output_index, context)
	while rv is GDScriptFunctionState:
		rv = yield(rv, "completed")
	if rv != null:
		if !rv.has("f"):
			if rv.has("rgb"):
				rv.f = "(dot("+rv.rgb+", vec3(1.0))/3.0)"
			elif rv.has("rgba"):
				rv.f = "(dot("+rv.rgba+".rgb, vec3(1.0))/3.0)"
			else:
				rv.f = "0.0"
		if !rv.has("rgb"):
			if rv.has("rgba"):
				rv.rgb = rv.rgba+".rgb"
			else:
				rv.rgb = "vec3("+rv.f+")"
		if !rv.has("rgba"):
			rv.rgba = "vec4("+rv.rgb+", 1.0)"
	return rv

func _get_shader_code(__, __, __):
	return null

func _serialize(data):
	print("cannot save "+name)
	return data

func serialize():
	var rv = { name=name, type=get_type(), parameters={}, node_position={ x=position.x, y=position.y } }
	for p in parameters.keys():
		rv.parameters[p] = MMType.serialize_value(parameters[p])
	if model != null:
		rv.type = model
	else:
		rv = _serialize(rv)
	return rv
