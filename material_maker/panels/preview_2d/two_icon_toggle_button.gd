extends Button

@export var mm_icon_normal := ""
@export var mm_icon_pressed := ""

func _ready() -> void:
	toggled.connect(_on_toggled)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_on_toggled(button_pressed)


func _on_toggled(toggled:= false):
	if button_pressed:
		icon = get_theme_icon(mm_icon_pressed, "MM_Icons")
	else:
		icon = get_theme_icon(mm_icon_normal, "MM_Icons")
		
