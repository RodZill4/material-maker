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
		color = Color.WHITE if mm_globals.is_theme_light() else Color.BLACK

func get_type() -> String:
	return "comment"

func get_type_name() -> String:
	return "Comment"

func _serialize(data : Dictionary) -> Dictionary:
	data.type = "comment"
	data.title = title
	data.color = MMType.serialize_value(color)
	data.text = text
	data.size = { x=size.x, y=size.y }
	data.autoshrink = autoshrink
	data.attached = attached
	data.erase("parameters")
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
		autoshrink = data.autoshrink
	if data.has("attached"):
		attached = data.attached
