extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().connect("informing", self, "_on_informing")
	
func _on_informing(new_text : String) -> void:
	text = new_text
