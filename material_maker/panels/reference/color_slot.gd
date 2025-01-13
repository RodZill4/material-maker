extends Button


func _ready() -> void:
	button_group.pressed.connect(func(_x): $ColorRect.queue_redraw())
	toggled.connect(func(_x): $ColorRect.queue_redraw())


func set_slot_color(c) -> void:
	$ColorRect.color = c


func _get_drag_data(_position):
	var preview = ColorRect.new()
	preview.color = $ColorRect.color
	preview.custom_minimum_size = Vector2(32, 32)
	set_drag_preview(preview)
	return $ColorRect.color


func _on_color_rect_draw() -> void:
	if button_pressed:
		var picker_icon := get_theme_icon("color_picker", "MM_Icons")
		printt(get_rect().size, picker_icon.get_size())
		$ColorRect.draw_texture(picker_icon, ($ColorRect.get_rect().size-picker_icon.get_size())/2.0)
