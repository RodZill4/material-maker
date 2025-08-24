extends Control

var moving : bool
var click_pos : Vector2i

var title_bar_font = preload("res://material_maker/theme/font_rubik/Rubik-416.ttf")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if moving:
			if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
				var window : Window = get_parent().get_window()
				if window:
					window.position = (
							DisplayServer.mouse_get_position() - click_pos)
			else:
				moving = false
	
	if event is InputEventMouseButton:
		if get_rect().has_point(event.position):
			var window : Window = get_parent().get_window()
			if window:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.is_pressed():
						click_pos = DisplayServer.mouse_get_position() - window.position
						moving = true
					else:
						moving = false
				if (event.button_index == MOUSE_BUTTON_LEFT
						and event.double_click
						and event.is_pressed()):
					if DisplayServer.window_maximize_on_title_dbl_click():
						if window.mode == Window.MODE_WINDOWED:
							window.mode = Window.MODE_MAXIMIZED
						elif window.mode == Window.MODE_MAXIMIZED:
							window.mode = Window.MODE_WINDOWED
					elif DisplayServer.window_minimize_on_title_dbl_click():
						window.mode = Window.MODE_MINIMIZED
					moving = false


func _on_title_bar_label_ready() -> void:
	var tween = get_tree().create_tween()
	modulate = Color.TRANSPARENT
	tween.tween_property(
			self,"modulate", Color.LIGHT_GRAY, 0.5).set_trans(Tween.TRANS_CUBIC).set_delay(0.15)
	
	var version = ProjectSettings.get_setting("application/config/actual_release")
	var app_name = ProjectSettings.get_setting("application/config/name")
	var title_bar_label_text = "%s v%s" % [ app_name, version ]
	
	$TitleBarLabel.add_theme_font_override("font", title_bar_font)
	$TitleBarLabel.add_theme_font_size_override("font_size", 14)
	$TitleBarLabel.text = title_bar_label_text
