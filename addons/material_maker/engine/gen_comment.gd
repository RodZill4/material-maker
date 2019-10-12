tool
extends MMGenTexture
class_name MMGenComment

"""
Comments to put in the graph
"""

var text : String = "Double-click to write a comment"
var size : Vector2 = Vector2(0, 0)

func _ready():
	if !parameters.has("size"):
		parameters.size = 4

func get_type():
	return "comment"

func get_type_name():
	return "Comment"

func get_parameter_defs():
	return []

func get_input_defs():
	return []
	
func get_output_defs():
	return []

func _serialize(data):
	data.type = "comment"
	data.text = text
	data.size = { x=size.x, y=size.y }
	return data
