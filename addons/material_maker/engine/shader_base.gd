extends RefCounted
class_name MMShaderBase


func _init():
	pass

func set_shader(shader : String) -> bool:
	return false

func get_parameters() -> Dictionary:
	return {}

func set_parameter(name : String, value) -> bool:
	return false
