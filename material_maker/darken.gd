extends ColorRect

func _ready():
	var current_theme : Theme = mm_globals.main_window.theme
	color = current_theme.get_stylebox("panel", "Panel").bg_color
	modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.8, 0.5).set_trans(Tween.TRANS_CUBIC)
	_on_resized()

func _on_resized():
	pass
	#material.set_shader_parameter("widget_size", size)
