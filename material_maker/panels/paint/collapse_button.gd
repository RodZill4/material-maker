extends Button


@export var node : Node


func _ready():
	if node:
		button_pressed = node.visible

func _on_toggled(toggled_on : bool):
	if node:
		node.visible = toggled_on
