tool
extends MMGenTexture
class_name MMGenComment

"""
Comments to put in the graph
"""

var text : String = ""
var size : Vector2 = Vector2(300, 200)
var title : String = "Comment"

var color = null

func _ready() -> void:
	if !parameters.has("size"):
		parameters.size = 4
	if color == null:
		color = Color.white if "light" in mm_globals.main_window.theme.resource_path else Color.black

func get_type() -> String:
	return "comment"

func get_type_name() -> String:
	return "Comment"

func get_parameter_defs() -> Array:
	return []

func get_input_defs() -> Array:
	return []

func get_output_defs(_show_hidden : bool = false) -> Array:
	return []

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "comment"
	data.title = title
	data.color = MMType.serialize_value(color)
	data.text = text
	data.size = { x=size.x, y=size.y }
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("text"):
		text = data.text
	if data.has("size"):
		size = Vector2(data.size.x, data.size.y)
	if data.has("title"):
		title = data.title
	if data.has("color"):
		color = MMType.deserialize_value(data.color)
