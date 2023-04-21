extends ColorRect

func _ready():
	var current_theme : Theme = mm_globals.main_window.theme
	color = current_theme.get_stylebox("panel", "Panel").bg_color
	color.a = 0.80
	_on_resized()

func _on_resized():
	pass
	#material.set_shader_param("widget_size", rect_size)
