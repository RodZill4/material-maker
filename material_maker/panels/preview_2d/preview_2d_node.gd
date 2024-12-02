extends "res://material_maker/panels/preview_2d/preview_2d.gd"

func _ready() -> void:
	update_export_menu()

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			mm_globals.popup_menu($ContextMenu, self)
