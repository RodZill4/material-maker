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

var drag_limits : Vector2i
var drag_position : int

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if vertical:
				drag_position = position.y
			else:
				drag_position = position.x
			drag_limits = flex_split.get_ref().start_flexlayout_drag(dragger_index, drag_position)
	elif event is InputEventMouseMotion:
		if dragging:
			if vertical:
				drag_position = position.y+event.position.y-5
				var new_position_y = clampi(drag_position, drag_limits.x, drag_limits.y)
				if position.y != new_position_y:
					position.y = new_position_y
					flex_split.get_ref().drag(dragger_index, position.y)
			else:
				drag_position = position.x+event.position.x-5
				var new_position_x = clampi(drag_position, drag_limits.x, drag_limits.y)
				if position.x != new_position_x:
					position.x = new_position_x
					flex_split.get_ref().drag(dragger_index, position.x)
