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

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	print("Getting shader code from ios")
	if mask != 2:
		var source = get_source(output_index)
		if source != null:
			return source.generator._get_shader_code(uv, source.output_index, context)
	return { defs="", code="", textures={} }

func _serialize(data):
	data.type = "buffer"
	return data
