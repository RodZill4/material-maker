class_name GradientEditCursor
extends Control

# The color value
var color: Color
# The color to display (usualy same as "color", except when dropping in a color)
var display_color: Color

# Updated by the GradientEdit
var cursor_index: int:
	set(val):
		cursor_index = val

# Reference to the GradientEdit
var gradient_edit: Control = null

# Depends on the height of the GradientEdit
var width: float = 10

enum Modes {IDLE, SLIDING, PREVIEW}
var mode := Modes.IDLE

var slide_start_point := 0.0


func _ready() -> void:
	width = get_parent().size.y / 2.0
	size = Vector2(width, get_parent().size.y)
	position = Vector2(position.x, 0)
	
	mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _draw() -> void:
	var HEIGHT := size.y
	var WIDTH := size.y/2.0
	
	# Define the HOUSE shape
	var polygon := PackedVector2Array([Vector2(0, HEIGHT*0.75), Vector2(WIDTH*0.5, HEIGHT*0.5), Vector2(WIDTH, HEIGHT*0.75), Vector2(WIDTH, HEIGHT), Vector2(0, HEIGHT), Vector2(0, HEIGHT*0.75)])
	draw_colored_polygon(polygon, display_color)
	
	var outline_color := Color.BLACK if (display_color.v > 0.5 and display_color.s < 0.6) else Color.WHITE
	draw_polyline(polygon, outline_color)
	draw_dashed_line(Vector2(WIDTH/2, 0), Vector2(WIDTH/2, HEIGHT*0.5), outline_color)
	
	# Draw the TRIANGLE (house roof) shape
	if gradient_edit.active_cursor == cursor_index:
		var active_polygon := PackedVector2Array([Vector2(0, HEIGHT*0.75), Vector2(WIDTH*0.5, HEIGHT*0.5), Vector2(WIDTH, HEIGHT*0.75), Vector2(0, HEIGHT*0.75)])
		draw_colored_polygon(active_polygon, outline_color)


func _gui_input(ev: InputEvent) -> void:
	if mode == Modes.IDLE:
		if ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				gradient_edit.active_cursor = cursor_index
				
				# Handle double click -> Color Select
				if ev.double_click:
					gradient_edit.select_color(self)
					position.x = slide_start_point
					accept_event()
				
				# Begin sliding
				elif ev.pressed:
					mode = Modes.SLIDING
					slide_start_point = position.x
					gradient_edit.mode = gradient_edit.Modes.SLIDING

			# Handle Right-Click -> Delete
			elif ev.button_index == MOUSE_BUTTON_RIGHT and gradient_edit.get_cursor_count() > 2:
				var parent = get_parent()
				parent.remove_child(self)
				queue_free()
				gradient_edit.active_cursor = cursor_index
				gradient_edit.update_from_value(false)
	
	# Handle sliding
	if mode == Modes.SLIDING:
		# While sliding
		if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			position.x += get_local_mouse_position().x
			if ev.is_command_or_control_pressed():
				position.x = round(get_cursor_offset() * 20.0) * 0.05 * get_parent().size.x
			position.x = min(max(0, position.x), get_parent().size.x) - width/2.0
			gradient_edit.update_from_value()
			gradient_edit.active_cursor = cursor_index

		# Sliding End
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
			mode = Modes.IDLE
			gradient_edit.mode = gradient_edit.Modes.IDLE
			gradient_edit.update_from_value(false)
			accept_event()


func _input(ev:InputEvent) -> void:
	if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		return
	
	if mode == Modes.IDLE:
		# Handle Ctrl+C and Ctrl+V to copy and paste the color
		if ev is InputEventKey and ev.is_command_or_control_pressed():
			if ev.keycode == KEY_V:
				if DisplayServer.clipboard_get().is_valid_html_color():
					set_cursor_color(Color(DisplayServer.clipboard_get()))
				accept_event()
			if ev.keycode == KEY_C:
				DisplayServer.clipboard_set(color.to_html())
				accept_event()


func set_cursor_offset(v:float, notify:=false, merge_undos:=false) -> void:
	position.x = clamp(v, 0, 1) * get_parent().size.x - width/2.0
	if notify:
		gradient_edit.update_from_value(merge_undos)
		gradient_edit.active_cursor = cursor_index


func get_cursor_offset() -> float:
	return (position.x + width/2.0) / get_parent().size.x


func set_cursor_color(c:Color, update_value:=true) -> void:
	color = c
	
	display_color = c
	display_color.a = 1
	
	if update_value:
		gradient_edit.update_from_value(false)
		gradient_edit.active_cursor = cursor_index
	queue_redraw()


#region DRAG AND DROP

func _can_drop_data(_position, data) -> bool:
	return typeof(data) == TYPE_COLOR and mode != Modes.PREVIEW


func _drop_data(_position, data) -> void:
	set_cursor_color(data)
	if gradient_edit.preview_cursor:
		gradient_edit.preview_cursor.queue_free()
		gradient_edit.preview_cursor = null

#endregion


#region DROP PREVIEW

func _on_mouse_entered() -> void:
	if get_viewport().gui_is_dragging():
		if _can_drop_data(Vector2(), get_viewport().gui_get_drag_data()):
			display_color = get_viewport().gui_get_drag_data()
			if gradient_edit.preview_cursor:
				gradient_edit.preview_cursor.hide()
			queue_redraw()


func _on_mouse_exited() -> void:
	display_color = color
	if gradient_edit.preview_cursor:
		gradient_edit.preview_cursor.show()
	queue_redraw()

#endregion
