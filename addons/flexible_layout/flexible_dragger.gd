extends Control


var dragging : bool = false
var flex_split
var dragger_index : int
var vertical : bool

func _init():
	set_meta("flexlayout", true)

func _draw():
	draw_rect(Rect2(Vector2(0, 0), size), Color(1, 1, 0))

func set_split(s, i : int, v : bool):
	flex_split = s
	dragger_index = i
	vertical = v

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion:
		if dragging:
			if vertical:
				position.y += event.position.y-5
				flex_split.drag(dragger_index, position.y)
			else:
				position.x += event.position.x-5
				flex_split.drag(dragger_index, position.x)
