extends HBoxContainer

func connect_buttons(object, edit_fct, load_fct, save_fct) -> void:
	$Edit.connect("pressed", Callable(object, edit_fct))
	$Load.connect("pressed", Callable(object, load_fct))
	$Save.connect("pressed", Callable(object, save_fct))

func _on_ready() -> void:
	$Edit.add_theme_color_override("icon_normal_color", Color.WHITE)
	$Load.add_theme_color_override("icon_normal_color", Color.WHITE)
	$Save.add_theme_color_override("icon_normal_color", Color.WHITE)
