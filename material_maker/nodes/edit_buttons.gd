extends HBoxContainer

func connect_buttons(object, edit_fct, load_fct, save_fct) -> void:
	$Edit.connect("pressed", Callable(object, edit_fct))
	$Load.connect("pressed", Callable(object, load_fct))
	$Save.connect("pressed", Callable(object, save_fct))

func _on_ready() -> void:
	# fix button icon colors (light theme)
	for button in get_children():
		button.add_theme_color_override("icon_normal_color", Color.WHITE)
		button.add_theme_color_override("icon_focus_color", Color("656565"))
		button.add_theme_color_override("icon_pressed_color", Color("656565"))
