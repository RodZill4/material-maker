extends ColorPickerButton

func get_drag_data(_position):
	var preview = ColorRect.new()
	preview.color = color
	preview.rect_min_size = Vector2(32, 32)
	set_drag_preview(preview)
	return color

func can_drop_data(_position, data) -> bool:
	return typeof(data) == TYPE_COLOR

func drop_data(_position, data) -> void:
	color = data
	emit_signal("color_changed", color)
