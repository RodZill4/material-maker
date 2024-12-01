extends HBoxContainer

@export var target : NodePath = ".."
var target_node

func _ready() -> void:
	target_node = get_node(target)

	$Model.icon = get_theme_icon("model", "MM_Icons")
	$Environment.icon = get_theme_icon("environment", "MM_Icons")
