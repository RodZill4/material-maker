tool
extends MMGenTexture
class_name MMGenImage

"""
Texture generator from image
"""

func get_type():
	return "image"

func get_type_name():
	return "Image"

func get_parameter_defs():
	return [ { name="image", type="path" } ]

func set_parameter(n : String, v):
	.set_parameter(n, v)
	if n == "image":
		texture.load(v)
