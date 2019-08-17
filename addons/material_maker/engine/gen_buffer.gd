tool
extends MMGenBase
class_name MMGenBuffer

func _ready():
	if !parameters.has("size"):
		parameters.size = 4

func get_type():
	return "buffer"

func get_type_name():
	return "Buffer"

func get_parameter_defs():
	return [ { name="size", type="size", first=4, last=11, default=4 } ]

func get_input_defs():
	return [ ]

func get_output_defs():
	return [ ]
