extends Control


var dragging : bool = false
var flex_split : WeakRef
var dragger_index : int
var vertical : bool
var half_grip_size : int

var touch_dragger : TouchDragger

func _init():
	set_meta("flexlayout", true)

func _ready() -> void:
	if mm_globals.get_config("touch_optimization"):
		touch_dragger = TouchDragger.new()
		touch_dragger.name = "TouchDragger"
		add_child(touch_dragger)
		mouse_entered.disconnect($TextureRect.show)
		mouse_exited.disconnect($TextureRect.hide)

func set_split(s, i : int, v : bool):
	flex_split = weakref(s)
	half_grip_size = flex_split.get_ref().grip_size * 0.5
	dragger_index = i
	vertical = v
	if vertical:
		mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		$TextureRect.texture = get_theme_icon("grabber", "VSplitContainer")
	else:
		mouse_default_cursor_shape = Control.CURSOR_HSPLIT
		$TextureRect.texture = get_theme_icon("grabber", "HSplitContainer")

	if mm_globals.get_config("touch_optimization"):
		touch_dragger.setup()
		mouse_filter = Control.MOUSE_FILTER_IGNORE

var drag_limits : Vector2i
var drag_position : int

func _on_gui_input(event : InputEvent, is_touch_dragger_input : bool = false):
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
			accept_event()
			if vertical:
				drag_position = position.y+event.position.y - half_grip_size

				if is_touch_dragger_input:
					drag_position -= touch_dragger.get_drag_offset()

				var new_position_y = clampi(drag_position, drag_limits.x, drag_limits.y)
				if position.y != new_position_y:
					position.y = new_position_y
					flex_split.get_ref().drag(dragger_index, position.y)

					if is_touch_dragger_input:
						touch_dragger.update_position(new_position_y)
			else:
				drag_position = position.x+event.position.x - half_grip_size

				if is_touch_dragger_input:
					drag_position -= touch_dragger.get_drag_offset()

				var new_position_x = clampi(drag_position, drag_limits.x, drag_limits.y)
				if position.x != new_position_x:
					position.x = new_position_x
					flex_split.get_ref().drag(dragger_index, position.x)

					if is_touch_dragger_input:
						touch_dragger.update_position(new_position_x)
