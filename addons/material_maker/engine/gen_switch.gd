tool
extends MMGenBase
class_name MMGenSwitch

"""
Texture generator switch
"""

func get_type():
	return "switch"

func get_type_name():
	return "Switch"

func get_parameter_defs():
	return [ { name="outputs", label="Outputs", type="float", min=1, max=5, step=1, default=2 },
			 { name="choices", label="Choices", type="float", min=2, max=5, step=1, default=2 },
			 { name="source", label="Source", type="float", min=0, max=1, step=1, default=0 } ]

func get_input_defs():
	var rv : Array = []
	for c in range(parameters.choices):
		for o in range(parameters.outputs):
			rv.push_back({ name=PoolByteArray([64+o]).get_string_from_ascii()+str(c), type="rgba" })
	return rv
	
func get_output_defs():
	var rv : Array = []
	for o in range(parameters.outputs):
		rv.push_back({ name=PoolByteArray([64+o]).get_string_from_ascii(), type="rgba" })
	return rv

func source_changed(input_index : int):
	notify_output_change(input_index % parameters.outputs)

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	var source = get_source(output_index+parameters.source*parameters.outputs)
	if source != null:
		var rv = source.generator._get_shader_code(uv, source.output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return { defs="", code="", textures={} }
