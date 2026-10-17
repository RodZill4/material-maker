extends ColorRect

func _ready():
	_set_color_from_theme()
	_on_resized()

func _on_resized():
	pass
	#material.set_shader_parameter("widget_size", size)

func _set_color_from_theme() -> void:
	var current_theme : Theme = mm_globals.main_window.theme
	color = current_theme.get_stylebox("panel", "Panel").bg_color
	color.a = 0.80

func _notification(what : int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_set_color_from_theme()
