tool
extends MMGenBase
class_name MMGenReroute

var port_type: String = "any"


func get_type() -> String:
	return "reroute"


func set_port_type(t: String) -> void:
	port_type = t


func get_type_name() -> String:
	return "Reroute"


func get_input_defs() -> Array:
	return [{name = "in", type = port_type}]


func get_output_defs(_show_hidden: bool = false) -> Array:
	return [{type = port_type}]


func get_parameter_defs() -> Array:
	return []


func _get_shader_code(uv: String, output_index: int, context: MMGenContext) -> Dictionary:
	var source = get_source(0)
	if source != null:
		var rv = source.generator._get_shader_code(uv, source.output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return {globals = [], defs = "", code = "", textures = {}, type = "f", f = "0.0"}


func _serialize(data: Dictionary) -> Dictionary:
	return data
