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
			 { name="source", label="Source", type="float", min=1, max=2, step=1 } ]

func set_parameter(n : String, v):
	.set_parameter(n, v)
	# Force redraw if outputs or choices is modified