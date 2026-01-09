@tool
extends MMGenBase
class_name MMGenComment


# Comments to put in the graph


var text : String = ""
var size : Vector2 = Vector2(350, 200)
var title : String = "Comment"
var autoshrink : bool = false

var attached : PackedStringArray

var color = null

func _ready() -> void:
	if color == null:
		color = Color.WHITE if "light" in mm_globals.main_window.theme.resource_path else Color.BLACK

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

func _serialize(data : Dictionary) -> Dictionary:
	data.type = "comment"
	data.title = title
	data.color = MMType.serialize_value(color)
	data.text = text
	data.size = { x=size.x, y=size.y }
	data.autoshrink = MMType.serialize_value(autoshrink)
	data.attached = attached
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
	if data.has("autoshrink"):
		autoshrink = MMType.deserialize_value(data.autoshrink)
	if data.has("attached"):
		attached = data.attached
