extends VBoxContainer

func update_up_down_buttons() -> void:
	for c in get_children():
		if ! (c is Button):
			c.update_up_down_button()
