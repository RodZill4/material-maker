@tool
extends MMGenBase
class_name MMGenDebug


# Can be used to get generated shader


func get_type() -> String:
	return "debug"

func get_type_name() -> String:
	return "Debug"

func get_description() -> String:
	return "\n".join(["Debug",
			"Shows generated shader of an input and code " +
			"which can be copied and used directly in Shadertoy"])

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func _serialize(data: Dictionary) -> Dictionary:
	return data
