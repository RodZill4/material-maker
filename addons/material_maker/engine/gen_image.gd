tool
extends MMGenTexture
class_name MMGenImage

"""
Texture generator from image
"""

func get_type() -> String:
	return "image"

func get_type_name() -> String:
	return "Image"

func get_parameter_defs() -> Array:
	return [ { name="image", type="path" } ]

func set_parameter(n : String, v) -> void:
	.set_parameter(n, v)
	if n == "image":
		texture.load(v)
