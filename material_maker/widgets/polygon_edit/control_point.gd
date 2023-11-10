extends Control

var moving : bool = false

const OFFSET : Vector2 = Vector2(3, 3)

signal moved(index)
signal removed(index)

func _draw():
	var current_theme : Theme = mm_globals.main_window.theme
	var color : Color = current_theme.get_color("font_color", "Label")
	draw_rect(Rect2(0, 0, 7, 7), color)

func initialize(p : Vector2) -> void:
	position = get_parent().transform_point(p)-OFFSET

func _on_ControlPoint_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				moving = true
			else:
				moving = false
				get_parent().update_controls()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			emit_signal("removed", get_index())
	elif moving and event is InputEventMouseMotion:
		position += event.relative
		emit_signal("moved", get_index())
