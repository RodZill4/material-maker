@tool
extends MMGenTexture
class_name MMGenCommentLine


# Comments to put in the graph


var text : String = "Enter something.."

func _ready() -> void:
	pass

func get_type() -> String:
	return "comment_line"

func get_type_name() -> String:
	return "Comment Line"

func get_parameter_defs() -> Array:
	return []

func get_input_defs() -> Array:
	return []

func get_output_defs(_show_hidden : bool = false) -> Array:
	return []

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "comment_line"
	data.text = text
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("text"):
		text = data.text
