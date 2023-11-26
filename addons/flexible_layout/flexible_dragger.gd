extends Control


var dragging : bool = false
var flex_split : WeakRef
var dragger_index : int
var vertical : bool

func _init():
	set_meta("flexlayout", true)

func set_split(s, i : int, v : bool):
	flex_split = weakref(s)
	dragger_index = i
	vertical = v
	if vertical:
		mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		$TextureRect.texture = get_theme_icon("grabber", "VSplitContainer")
	else:
		mouse_default_cursor_shape = Control.CURSOR_HSPLIT
		$TextureRect.texture = get_theme_icon("grabber", "HSplitContainer")

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion:
		if dragging:
			if vertical:
				position.y += event.position.y-5
				flex_split.get_ref().drag(dragger_index, position.y)
			else:
				position.x += event.position.x-5
				flex_split.get_ref().drag(dragger_index, position.x)
