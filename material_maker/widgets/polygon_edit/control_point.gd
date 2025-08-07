extends Control

var circle : bool = false
var is_moving : bool = false
var has_moved : bool = false
var selectable : bool = false
var is_selected : bool = false
var hovered : bool = false
var editor : Control = null

static var control_size : float = 4

signal moved(index)
signal selected(index, control_pressed, shift_pressed)
signal removed(index)

func _draw():
	var current_theme : Theme = mm_globals.main_window.theme
	var moving_color : Color = current_theme.get_color("icon_pressed_color", "Button")
	var color : Color = Color(1.0, 0.0, 0.0) if is_selected else current_theme.get_color("font_color", "Label")
	if circle:
		draw_circle(Vector2(control_size, control_size), control_size+1, color)
		draw_arc(Vector2(control_size, control_size), control_size+1, 0, TAU, 8, color.inverted())
	else:
		draw_rect(Rect2(Vector2(0, 0), custom_minimum_size), moving_color if is_moving else color)
		draw_rect(Rect2(Vector2(0, 0), custom_minimum_size), color.inverted(), false)
		if is_moving or hovered:
			draw_rect(Rect2(-custom_minimum_size*0.5, custom_minimum_size*2.0), current_theme.get_color("font_color", "Label"), false, 1.0)
			draw_rect(Rect2(-custom_minimum_size*0.5-Vector2(1.0,1.0),
					custom_minimum_size*2.0+Vector2(2.0,2.0)), current_theme.get_color("font_color", "Label").inverted(), false, 1.0)

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
				queue_redraw()
				if selectable:
					selected.emit(get_index(), event.is_command_or_control_pressed(), event.shift_pressed)
			else:
				is_moving = false
				moved.emit(get_index())
				queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			removed.emit(get_index())
	elif is_moving and event is InputEventMouseMotion:
		var new_pos : Vector2 = position + event.relative
		if event.is_command_or_control_pressed():
			var value : Vector2
			var parent = get_parent().owner
			if parent.name == "Preview2D":
				new_pos = position + event.position
				value = parent.pos_to_value(new_pos, true, false)
				var snap : float = 0.0
				var preview2D = get_parent().owner
				var grid = preview2D.get_node("Guides")
				if grid != null and grid.visible:
					snap = grid.grid_size
				if snap > 0.0:
					value.x = round((value.x-0.5)*snap)/snap+0.5
					value.y = round((value.y-0.5)*snap)/snap+0.5
				new_pos = parent.value_to_pos(value, true, false) - size*0.5
			elif parent.name == "PolygonDialog":
				if get_parent().axes_density > 1.0:
					new_pos = position + event.position
					var snap : float = 1.0 / (get_parent().axes_density - 1.0)
					value = get_parent().reverse_transform_point(new_pos)
					value = snapped(value, Vector2(snap, snap))
					new_pos = get_parent().transform_point(value) - size*0.5
		position = new_pos
		has_moved = true
		moved.emit(get_index())


func _on_mouse_entered() -> void:
	hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()
