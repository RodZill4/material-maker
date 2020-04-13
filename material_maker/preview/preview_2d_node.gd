extends "res://material_maker/preview/preview_2d.gd"

func _ready():
	$ContextMenu.add_submenu_item("Export", "Export")

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			$ContextMenu.popup(Rect2(get_global_mouse_position(), $ContextMenu.get_minimum_size()))
