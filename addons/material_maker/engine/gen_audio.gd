tool
extends MMGenBase
class_name MMGenAudio

"""
Dummy generator to get audio shaders from UI
"""

func get_type() -> String:
	return "audio"

func get_type_name() -> String:
	return "Audio"

func get_input_defs() -> Array:
	return [ { name="in", type="sound" } ]


func _serialize(data: Dictionary) -> Dictionary:
	return data
