extends Button

@export var mm_icon := ""
@export var theme_type := "MM_Icons"

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		icon = get_theme_icon(mm_icon, theme_type)
