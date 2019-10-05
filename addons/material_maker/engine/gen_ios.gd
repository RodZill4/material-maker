tool
extends MMGenBase
class_name MMGenIOs

"""
IOs just forward their inputs to their outputs and are used to specify graph interfaces
"""

var ports : Array = []

func get_type():
	return "ios"

func get_type_name():
	match name:
		"gen_inputs": return "Inputs"
		"gen_outputs": return "Outputs"
		_: return "IOs"

func get_io_defs():
	var rv : Array = []
	for p in ports:
		rv.push_back({ name=p.name, type="rgba" })
	return rv

func get_input_defs():
	return [] if name == "gen_inputs" else get_io_defs()

func get_output_defs():
	return [] if name == "gen_outputs" else get_io_defs()

func source_changed(input_index : int):
	if name == "gen_outputs":
		get_parent().notify_output_change(input_index)
	else:
		notify_output_change(input_index)

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	var source = get_source(output_index)
	if source != null:
		var rv = source.generator._get_shader_code(uv, source.output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return { defs="", code="", textures={} }

func _serialize(data):
	data.type = "ios"
	data.ports = ports
	return data
