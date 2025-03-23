extends PanelContainer

# Emitted whenever the gradient changed
signal updated(value, merge_undos:bool)
# Emitted whenever the active cursor index changed
signal active_cursor_changed()
# Emitted once a new value was loaded
signal value_was_set

enum Modes {IDLE, SLIDING, SELECTING_COLOR}
var mode := Modes.IDLE

var value: MMGradient = null:
	set(v):
		value = v
		# If the size is 0, don't load.
		# In these cases, there is a resize on one of the next frames
		# which will then trigger the correct loading.
		if %Gradient.size.x != 0:
			set_value(v)

# Index of the active cursor
var active_cursor := 0:
	set(value):
		value = wrap(value, 0, %Gradient.get_child_count())
		active_cursor = value
		active_cursor_changed.emit()

		for i in %Gradient.get_children():
			i.queue_redraw()

# Reference of the preview cursor (when dropping in a color)
var preview_cursor: GradientEditCursor = null
# Reference to the popup
var popup : Control = null

var hovered : bool = false


func _ready() -> void:
	%Gradient.material = %Gradient.material.duplicate(true)

	update_visuals()


func set_value(v: MMGradient) -> void:
	for c in %Gradient.get_children():
		c.queue_free()
		c.get_parent().remove_child(c)

	if value == null:
		return

	for p in value.points:
		add_cursor(p.v, p.c)

	sort_cursors()

	update_shader()
	value_was_set.emit()


func set_interpolation(interpolation_type:int) -> void:
	value.interpolation = interpolation_type
	update_shader()
	updated.emit(value, false)


func update_from_value(merge_undos := true) -> void:
	value.clear()

	for c in %Gradient.get_children():
		value.add_point(c.get_cursor_offset(), c.color)

	update_shader()

	if is_instance_valid(popup):
		popup.set_gradient(value, active_cursor)

	sort_cursors()

	updated.emit(value, merge_undos)


func _gui_input(ev:InputEvent) -> void:
	if mode == Modes.IDLE:
		# Handle Adding new cursors by double-clicking
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.double_click:
			var offset := position_to_offset(get_local_mouse_position())
			var cursor = add_cursor(offset, get_gradient_color(offset))
			sort_cursors()
			active_cursor = cursor.cursor_index
			update_from_value(false)

	if preview_cursor:
		preview_cursor.set_cursor_offset(position_to_offset(get_local_mouse_position()))


func select_color(cursor:GradientEditCursor) -> void:
	active_cursor = cursor.cursor_index
	mode = Modes.SELECTING_COLOR

	var color_picker_popup := preload("res://material_maker/widgets/color_picker_popup/color_picker_popup.tscn").instantiate()
	add_child(color_picker_popup)

	var color_picker := color_picker_popup.get_node("ColorPicker")
	color_picker.color = cursor.color
	color_picker.color_changed.connect(cursor.set_cursor_color)
	
	var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	color_picker_popup.content_scale_factor = content_scale_factor
	color_picker_popup.min_size = color_picker_popup.get_contents_minimum_size() * content_scale_factor

	var _scale := get_global_transform().get_scale()
	
	color_picker_popup.position.x = (global_position.x + size.x*_scale.x) * content_scale_factor
	color_picker_popup.position.y = global_position.y * content_scale_factor
	color_picker_popup.position += get_window().position

	color_picker_popup.popup_hide.connect(color_picker_popup.queue_free)
	color_picker_popup.popup_hide.connect(set.bind("mode", Modes.IDLE))

	color_picker_popup.popup()


#region HELPERS
func position_to_offset(pos:Vector2) -> float:
	var gradient_start_position = %Gradient.global_position.x - global_position.x
	var gradient_end_position = gradient_start_position + (%Gradient.size.x)
	var offset = clamp(remap(pos.x, gradient_start_position, gradient_end_position, 0.0, 1.0), 0, 1)
	return offset


func get_cursor_count() -> int:
	return %Gradient.get_child_count()


func get_cursor(idx:int) -> GradientEditCursor:
	for cursor in %Gradient.get_children():
		if cursor.cursor_index == idx:
			return cursor
	return %Gradient.get_child(0)


func get_active_cursor() -> GradientEditCursor:
	return get_cursor(active_cursor)

func sort_cursors() -> void:
	var cursors := %Gradient.get_children()
	cursors.sort_custom(
		func(a,b): return a.position.x < b.position.x
	)
	for i in range(len(cursors)):
		cursors[i].cursor_index = i


func get_gradient_color(offset:float) -> Color:
	return value.get_color(offset)


func get_gradient_from_data(data:Variant) -> Variant:
	if typeof(data) == TYPE_ARRAY:
		return data
	elif typeof(data) == TYPE_DICTIONARY:
		if data.has("parameters") and data.parameters.has("gradient"):
			return data.parameters.gradient
		if data.has("type") and data.type == "Gradient":
			return data
	return null

#endregion

func add_cursor(offset, color) -> GradientEditCursor:
	var cursor = preload("res://material_maker/widgets/gradient_editor/gradient_edit_cursor.tscn").instantiate()
	%Gradient.add_child(cursor)
	cursor.gradient_edit = self
	cursor.set_cursor_offset(offset)
	cursor.set_cursor_color(color, false)
	return cursor

#region SHADER

func update_shader() -> void:
	if value == null:
		return
	var shader_code := ""
	shader_code = "shader_type canvas_item;\n"
	shader_code += value.get_shader_params("")
	shader_code += """
uniform vec2 size = vec2(25.0, 25.0);
uniform vec3 background_color_1 = vec3(0.4);
uniform vec3 background_color_2 = vec3(0.6);
	"""
	shader_code += value.get_shader("")
	shader_code += """void fragment() {
	vec2 uv = UV*size;
	float checkerboard = mod(floor(uv.x*0.2)+floor(uv.y*0.2), 2.0);
	vec4 gradient = _gradient_fct(UV.x);
	vec3 gradient_with_checkerboard = mix(mix(background_color_1, background_color_2, checkerboard).rgb, gradient.rgb, gradient.a);
	if (UV.y < 0.75){
		COLOR.rgb = gradient_with_checkerboard;
	} else {
		COLOR.rgb = gradient.rgb;
	}
	}"""
	var shader : Shader = Shader.new()
	shader.code = shader_code
	%Gradient.material.shader = shader
	update_shader_parameters()


func update_shader_parameters(node: Node = null) -> void:
	if node == null:
		node = %Gradient
	var parameter_values: Dictionary = value.get_parameter_values("")
	node.material.set_shader_parameter("size", node.size)
	for n in parameter_values.keys():
		node.material.set_shader_parameter(n, parameter_values[n])

#endregion


func _on_gradient_resized() -> void:
	if value != null:
		value = value


func _on_popup_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		popup = load("res://material_maker/widgets/gradient_editor/gradient_popup.tscn").instantiate()
		add_child(popup)

		popup.updated.connect(
			func(val, merge_undos):
				value = val
				updated.emit(value, merge_undos)
				)
		popup.about_to_close.connect(%PopupButton.call_deferred.bind("set_pressed_no_signal", false))
		popup.active_cursor_changed.connect(func(val): active_cursor = val)

		popup.set_gradient(value, active_cursor)

		update_popup_position()
		set_notify_transform(true)

	else:
		if is_instance_valid(popup):
			popup.close()
		set_notify_transform(false)


func update_popup_position() -> void:
	if is_instance_valid(popup):
		var popup_size := Vector2i(550, 40)
		var _scale := get_global_transform().get_scale()
		popup.position.x = global_position.x + size.x/2.0 * _scale.x - popup_size.x / 2.0
		popup.position.y = global_position.y + size.y * _scale.y
		popup.size = popup_size


#region DRAG AND DROP

func _get_drag_data(_position : Vector2) -> Variant:
	if mode != Modes.IDLE:
		return
	var data = MMType.serialize_value(value)
	var preview = ColorRect.new()
	preview.size = Vector2(64, 24)
	preview.material = %Gradient.material.duplicate(true)
	update_shader_parameters(preview)
	set_drag_preview(preview)
	return data


func _can_drop_data(_position : Vector2, data:Variant) -> bool:
	return get_gradient_from_data(data) != null or typeof(data) == TYPE_COLOR


func _drop_data(pos: Vector2, data: Variant) -> void:
	if typeof(data) == TYPE_COLOR:
		var offset = position_to_offset(pos)
		var new_cursor = add_cursor(offset, data)
		sort_cursors()
		active_cursor = new_cursor.cursor_index
		update_from_value(false)
	else:
		var gradient = get_gradient_from_data(data)
		if gradient != null:
			value = MMType.deserialize_value(gradient)
			updated.emit(value, false)

	if preview_cursor:
		preview_cursor.queue_free()
		preview_cursor = null


# Handle Ctrl+C and Ctrl+V to copy and paste the gradient
func _input(ev:InputEvent) -> void:
	if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		return

	if mode == Modes.IDLE:
		if ev is InputEventKey and ev.is_command_or_control_pressed():
			if not ev.pressed:
				return
			if ev.keycode == KEY_V:
				var val = ""
				if DisplayServer.clipboard_get().is_valid_html_color():
					val = Color.from_string(DisplayServer.clipboard_get(), Color.WHITE)
				else:
					val = str_to_var(DisplayServer.clipboard_get())

				_drop_data(get_local_mouse_position(), val)
				accept_event()

			if ev.keycode == KEY_C:
				DisplayServer.clipboard_set(var_to_str(MMType.serialize_value(value)))
				accept_event()
#endregion


#region VISUALS

# Used on the GradientEdit that's part of the popup
func remove_popup_button() -> void:
	%PopupButton.queue_free()


func update_visuals() -> void:
	if has_node("%PopupButton"):
		%PopupButton.icon = get_theme_icon("dropdown", "MM_Icons")
	var is_hovered := Rect2(Vector2(), size).has_point(get_local_mouse_position())
	if is_hovered != hovered:
		hovered = is_hovered
		if hovered:
			add_theme_stylebox_override("panel", get_theme_stylebox("hover"))
		else:
			add_theme_stylebox_override("panel", get_theme_stylebox("normal"))


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if get_meta("doing_theme_change", false):
		return

	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			update_popup_position()
		NOTIFICATION_THEME_CHANGED:
			set_meta("doing_theme_change", true)
			update_visuals()
			await get_tree().process_frame
			set_meta("doing_theme_change", false)


func _draw() -> void:
	var is_focused := get_viewport().gui_get_focus_owner() == self
	if is_focused:
		draw_style_box(get_theme_stylebox("focus"), Rect2(Vector2(), size))


func _on_mouse_entered() -> void:
	update_visuals()
	if get_viewport().gui_is_dragging() and _can_drop_data(Vector2(), get_viewport().gui_get_drag_data()):
		var data = get_viewport().gui_get_drag_data()
		if typeof(data) == TYPE_COLOR:
			preview_cursor = add_cursor(position_to_offset(get_local_mouse_position()), data)
			preview_cursor.mode = preview_cursor.Modes.PREVIEW
			preview_cursor.get_parent().move_child(preview_cursor, 0)


func _on_mouse_exited() -> void:
	update_visuals()
	if preview_cursor:
		preview_cursor.queue_free()
		preview_cursor = null
#endregion
