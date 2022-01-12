extends "res://material_maker/panels/preview_2d/preview_2d.gd"


func _ready() -> void:
	update_export_menu()


func _on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			$ContextMenu.popup(Rect2(get_global_mouse_position(), $ContextMenu.get_minimum_size()))
