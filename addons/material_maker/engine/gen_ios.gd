tool
extends MMGenBase
class_name MMGenIOs

"""
IOs just forward their inputs to their outputs and are used to specify graph interfaces
"""

var mask : int = 3
var ports : Array = []

func _ready():
	if !parameters.has("size"):
		parameters.size = 4

func get_type():
	return "buffer"

func get_type_name():
	match mask:
		1: return "Inputs"
		2: return "Output"
		_: return "IOs"
	return "Buffer"

func get_input_defs():
	var rv : Array = []
	if mask != 2:
		for p in ports:
			rv.push_back({ name=p.name, type="rgba" })
	return rv
	
func get_output_defs():
	var rv : Array = []
	if mask != 2:
		for p in ports:
			rv.push_back({ name=p.name, type="rgba" })
	return rv

func source_changed(input_index : int):
	if name == "gen_outputs":
		get_parent().notify_output_change(input_index)
	else:
		notify_output_change(input_index)

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	if mask != 2:
		var source = get_source(output_index)
		if source != null:
			var rv = source.generator._get_shader_code(uv, source.output_index, context)
			while rv is GDScriptFunctionState:
				rv = yield(rv, "completed")
			return rv
	return { defs="", code="", textures={} }

func _serialize(data):
	data.type = "ios"
	data.mask = mask
	data.ports = ports
	return data
