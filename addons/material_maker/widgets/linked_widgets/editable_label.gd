tool
extends Label

func _ready():
	pass

func _on_gui_input(ev):
	if ev is InputEventMouseButton and ev.doubleclick and ev.button_index == BUTTON_LEFT:
		var dialog = preload("res://addons/material_maker/widgets/line_dialog.tscn").instance()
		add_child(dialog)
		dialog.set_texts("Remote", "Enter a name this control")
		dialog.connect("ok", self, "set_text", [])
		dialog.popup_centered()
