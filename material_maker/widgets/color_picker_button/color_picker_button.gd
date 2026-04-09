extends ColorPickerButton

var previous_color : Color

signal color_changed_undo(c, previous)


func _ready():
	custom_minimum_size = Vector2(24, 24)
	connect("color_changed",Callable(self,"on_color_changed"))
	connect("picker_created",Callable(self,"on_picker_created"))
	connect("popup_closed",Callable(self,"on_popup_closed"))
	get_popup().content_scale_factor = mm_globals.ui_scale_factor()
	get_popup().min_size = get_popup().get_contents_minimum_size() * get_popup().content_scale_factor

func set_color(c):
	color = c

func _get_drag_data(_position):
	var preview = ColorRect.new()
	preview.color = color
	preview.custom_minimum_size = Vector2(32, 32)
	set_drag_preview(preview)
	return color

func _can_drop_data(_position, data) -> bool:
	return typeof(data) == TYPE_COLOR

func _drop_data(_position, data) -> void:
	var old_color : Color = color
	color = data
	emit_signal("color_changed", color)
	emit_signal("color_changed_undo", color, old_color)


func on_color_changed(c):
	emit_signal("color_changed_undo", c, null)


func on_picker_created():
	get_popup().connect("about_to_popup", Callable(self, "on_about_to_show"))
	previous_color = color


func on_about_to_show():
	previous_color = color
	if mm_globals.has_config("color_picker_color_mode"):
		get_picker().color_mode = mm_globals.get_config("color_picker_color_mode")
	if mm_globals.has_config("color_picker_shape"):
		get_picker().picker_shape = mm_globals.get_config("color_picker_shape")


func on_popup_closed():
	emit_signal("color_changed_undo", color, previous_color)
	mm_globals.set_config("color_picker_color_mode", get_picker().color_mode)
	mm_globals.set_config("color_picker_shape", get_picker().picker_shape)

func _input(event:InputEvent) -> void:
	if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		return
	if event is InputEventKey and event.is_command_or_control_pressed() and event.pressed:
		if event.keycode == KEY_C:
			DisplayServer.clipboard_set(color.to_html())
			accept_event()
		if event.keycode == KEY_V:
			var v := DisplayServer.clipboard_get()
			if v.is_valid_html_color():
				color = Color.from_string(v, color)
			accept_event()
