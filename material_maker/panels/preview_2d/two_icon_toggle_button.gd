extends Button

@export var icon_normal_name := ""
@export var icon_pressed_name := ""

func _ready() -> void:
	toggled.connect(_on_toggled)
	_on_toggled(button_pressed)


func _on_toggled(toggled:= false):
	if button_pressed:
		icon = get_theme_icon(icon_pressed_name, "MM_Icons")
	else:
		icon = get_theme_icon(icon_normal_name, "MM_Icons")
