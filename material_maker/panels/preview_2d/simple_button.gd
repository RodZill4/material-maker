extends Button

@export var icon_name := ""

func _ready() -> void:
	icon = get_theme_icon(icon_name, "MM_Icons")
