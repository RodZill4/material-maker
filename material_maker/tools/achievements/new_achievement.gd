extends Achievement

func _on_Achievement_gui_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		get_parent().get_parent().show_achievements()
