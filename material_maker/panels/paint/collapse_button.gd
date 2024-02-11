extends Button


@export var node : Node


func _on_toggled(toggled_on : bool):
	if node:
		node.visible = toggled_on
