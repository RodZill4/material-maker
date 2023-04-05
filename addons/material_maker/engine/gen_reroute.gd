@tool
extends MMGenBase
class_name MMGenReroute

var port_type : String = "any"

func get_type() -> String:
	return "reroute"

func set_port_type(t : String) -> void:
	port_type = t

func get_type_name() -> String:
	return "Reroute"

func get_input_defs() -> Array:
	return [ { name="in", type=port_type } ]

func get_output_defs(_show_hidden : bool = false) -> Array:
	return [ { type=port_type } ]

func get_parameter_defs() -> Array:
	return []

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	var source = get_source(0)
	if source != null:
		return source.generator._get_shader_code(uv, source.output_index, context)
	return get_default_generated_shader()

func _serialize(data: Dictionary) -> Dictionary:
	return data
