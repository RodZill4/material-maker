extends Button

signal on_show_popup()

var mm_icon := "":
	set(val):
		mm_icon = val
		if val:
			_notification(NOTIFICATION_THEME_CHANGED)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		if mm_icon:
			icon = get_theme_icon(mm_icon, "MM_Icons")


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		on_show_popup.emit()
