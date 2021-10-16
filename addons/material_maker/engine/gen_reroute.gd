tool
extends MMGenBase
class_name MMGenReroute

func get_type() -> String:
	return "reroute"

func get_type_name() -> String:
	return "Reroute"

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func get_output_defs() -> Array:
	return [ { type="rgba" } ]

func get_parameter_defs() -> Array:
	return []

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var source = get_source(0)
	if source != null:
		var rv = source.generator._get_shader_code(uv, source.output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return { globals=[], defs="", code="", textures={}, type="f", f="0.0" }
