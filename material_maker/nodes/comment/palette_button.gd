extends ColorRect

signal pressed(color)


func _ready() -> void:
	connect("gui_input", self, "_on_gui_input")


func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("pressed", color)
