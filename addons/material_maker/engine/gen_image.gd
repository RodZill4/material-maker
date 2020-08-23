tool
extends MMGenTexture
class_name MMGenImage

var timer : Timer

"""
Texture generator from image
"""

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5
	timer.start()
	timer.connect("timeout", self, "_on_timeout")

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

func _on_timeout():
	set_parameter("image", get_parameter("image"))
	
