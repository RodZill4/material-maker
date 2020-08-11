extends HBoxContainer

export var target : NodePath = ".."
var target_node

func _ready() -> void:
	target_node = get_node(target)
