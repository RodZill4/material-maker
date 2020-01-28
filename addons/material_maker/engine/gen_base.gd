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

const PORT_TYPE_NAMES : Array = [ "f", "rgb", "rgba", "sdf2d", "sdf3d" ]

const PORT_TYPES : Dictionary = {
	f     = { label="Greyscale", type="float", paramdefs="vec2 uv", params="uv", slot_type=0, color=Color(0.5, 0.5, 0.5) },
	rgb   = { label="Color", type="vec3", paramdefs="vec2 uv", params="uv", slot_type=0, color=Color(0.5, 0.5, 1.0) },
	rgba  = { label="RGBA", type="vec4", paramdefs="vec2 uv", params="uv", slot_type=0, color=Color(0.0, 0.5, 0.0, 0.5) },
	sdf2d = { label="SDF2D", type="float", paramdefs="vec2 uv", params="uv", slot_type=1, color=Color(1.0, 0.5, 0.0) },
	sdf3d = { label="SDF3D", type="float", paramdefs="vec3 p", params="p", slot_type=2, color=Color(1.0, 0.0, 0.0) },
	any = { slot_type=42, color=Color(1.0, 1.0, 1.0) }
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

func get_parameter(n : String):
	return parameters[n]

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

func generate_preview_shader(src_code) -> String:
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
	if src_code.has("rgba"):
		shader_code += "\nvoid fragment() {\n"
		shader_code += "vec2 uv = UV;\n"
		shader_code += src_code.code
		shader_code += "COLOR = "+src_code.rgba+";\n"
		shader_code += "}\n"
	elif src_code.has("sdf2d"):
		shader_code += "\nvoid fragment() {\n"
		shader_code += "vec2 uv = UV;\n"
		shader_code += src_code.code
		shader_code += "float d = "+src_code.sdf2d+";\n"
		shader_code += "vec3 col = vec3(cos(d*min(256, preview_size)));\n"
		shader_code += "col *= clamp(1.0-d*d, 0.0, 1.0);\n"
		shader_code += "col *= vec3(1.0, vec2(step(-0.015, d)));\n"
		shader_code += "col *= vec3(vec2(step(d, 0.015)), 1.0);\n"
		shader_code += "COLOR = vec4(col, 1.0);\n"
		shader_code += "}\n"
	elif src_code.has("sdf3d"):
		shader_code += "\nfloat calcdist(vec3 uv) {\n"
		shader_code += src_code.code
		shader_code += "return min("+src_code.sdf3d+", uv.z);\n"
		shader_code += "}\n"
		shader_code += "float raymarch(vec3 ro, vec3 rd) {\n"
		shader_code += "float d=0.0;\n"
		shader_code += "for (int i = 0; i < 50; i++) {\n"
		shader_code += "vec3 p = ro + rd*d;\n"
		shader_code += "float dstep = calcdist(p);\n"
		shader_code += "d += dstep;\n"
		shader_code += "if (dstep < 0.0001) break;\n"
		shader_code += "}\n"
		shader_code += "return d;\n"
		shader_code += "}\n"
		shader_code += "vec3 normal(vec3 p) {\n"
		shader_code += "	float d = calcdist(p);\n"
		shader_code += "    float e = .0001;\n"
		shader_code += "    vec3 n = d - vec3(calcdist(p-vec3(e, 0.0, 0.0)), calcdist(p-vec3(0.0, e, 0.0)), calcdist(p-vec3(0.0, 0.0, e)));\n"
		shader_code += "    return normalize(n);\n"
		shader_code += "}\n"
		shader_code += "\nvoid fragment() {\n"
		shader_code += "vec2 uv = UV-vec2(0.5);\n"
		shader_code += "vec3 p = vec3(uv, 2.0-raymarch(vec3(uv, 2.0), vec3(0.0, 0.0, -1.0)));\n"
		shader_code += "vec3 n = normal(p);\n"
		shader_code += "vec3 l = vec3(5.0, 5.0, 10.0);\n"
		shader_code += "vec3 ld = normalize(l-p);\n"
		shader_code += "float o = step(p.z, 0.001);\n"
		shader_code += "float shadow = 1.0-0.75*step(raymarch(l, -ld), length(l-p)-0.01);\n"
		shader_code += "float light = 0.3+0.7*dot(n, ld)*shadow;\n"
		shader_code += "COLOR = vec4(vec3(0.8+0.2*o, 0.8+0.2*o, 1.0)*light, 1.0);\n"
		shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

func render(output_index : int, size : int, preview : bool = false) -> Object:
	var context : MMGenContext = MMGenContext.new()
	var source = get_shader_code("uv", output_index, context)
	while source is GDScriptFunctionState:
		source = yield(source, "completed")
	if source.empty():
		source = { defs="", code="", textures={}, rgba="vec4(0.0)" }
	var shader : String
	if preview:
		var outputs = get_output_defs()
		if outputs.size() > output_index:
			var output = outputs[output_index]
			print(output)
		shader = generate_preview_shader(source)
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
