extends TextureButton

signal on_show_popup()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		on_show_popup.emit()
