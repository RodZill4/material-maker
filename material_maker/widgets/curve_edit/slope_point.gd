extends Control

export var distance : float

var moving = false

const OFFSET = -Vector2(0, 0)

func _ready():
	pass # Replace with function body.

func _draw():
	var current_theme : Theme = mm_globals.get_main_window().theme
	var color : Color = current_theme.get_color("font_color", "Label")
	draw_circle(Vector2(3.0, 3.0), 3.0, color)

func _on_ControlPoint_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if event.doubleclick:
					var parent = get_parent()
					var vector : Vector2
					if get_index() == 0:
						vector = parent.rect_position-parent.get_parent().get_child(parent.get_index()-1).rect_position
					else:
						vector = parent.get_parent().get_child(parent.get_index()+1).rect_position-parent.rect_position
					vector = distance*vector.normalized()
					rect_position = vector-OFFSET
					if event.control:
						get_parent().get_child(1-get_index()).rect_position = -vector-OFFSET
					get_parent().update_tangents()
				else:
					moving = true
			else:
				moving = false
	elif moving and event is InputEventMouseMotion:
		var vector = get_global_mouse_position()-get_parent().get_global_rect().position+OFFSET
		vector *= sign(vector.x)
		vector = distance*vector.normalized()
		rect_position = vector-OFFSET
		if event.control:
			get_parent().get_child(1-get_index()).rect_position = -vector-OFFSET
		get_parent().update_tangents()
