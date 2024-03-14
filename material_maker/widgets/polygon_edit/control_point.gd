extends Control

var circle : bool = false
var is_moving : bool = false
var has_moved : bool = false
var selectable : bool = false
var is_selected : bool = false
var editor : Control = null

static var control_size : float = 4

signal moved(index)
signal selected(index, control_pressed, shift_pressed)
signal removed(index)

func _draw():
	var current_theme : Theme = mm_globals.main_window.theme
	var color : Color = Color(1.0, 0.0, 0.0) if is_selected else current_theme.get_color("font_color", "Label")
	if circle:
		draw_circle(Vector2(control_size, control_size), control_size+1, color)
		draw_arc(Vector2(control_size, control_size), control_size+1, 0, TAU, 8, color.inverted())
	else:
		draw_rect(Rect2(Vector2(0, 0), custom_minimum_size), color)
		draw_rect(Rect2(Vector2(0, 0), custom_minimum_size), color.inverted(), false)

func initialize(p : Vector2, e : Control = null) -> void:
	editor = e if e != null else get_parent()
	position = editor.transform_point(p)-Vector2(control_size, control_size)
	custom_minimum_size = Vector2(2*control_size+1, 2*control_size+1)
	size = custom_minimum_size

func select(s : bool = true):
	if selectable:
		is_selected = s
		queue_redraw()

func getpos() -> Vector2:
	return position+Vector2(control_size, control_size)

func setpos(p : Vector2) -> void:
	position = p-Vector2(control_size, control_size)

func _on_ControlPoint_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_moving = true
				has_moved = false
				if selectable:
					selected.emit(get_index(), event.is_command_or_control_pressed(), event.shift_pressed)
			else:
				is_moving = false
				moved.emit(get_index())
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			removed.emit(get_index())
	elif is_moving and event is InputEventMouseMotion:
		position += event.relative
		has_moved = true
		moved.emit(get_index())
