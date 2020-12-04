extends Control

export var distance : float

var moving = false

const OFFSET = -Vector2(0, 0)

func _ready():
	pass # Replace with function body.

func _draw():
	draw_circle(Vector2(3.0, 3.0), 3.0, Color(1.0, 1.0, 1.0))

func _on_ControlPoint_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				print("slope point moving")
				moving = true
			else:
				moving = false
	elif moving and event is InputEventMouseMotion:
		var vector = get_global_mouse_position()-get_parent().get_global_rect().position+OFFSET
		vector *= sign(vector.x)
		rect_position = distance*vector.normalized()-OFFSET
		get_parent().update_tangents()
