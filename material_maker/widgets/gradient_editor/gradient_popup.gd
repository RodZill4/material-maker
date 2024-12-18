extends Control

signal updated(value, merge_undos)
signal about_to_close()
signal active_cursor_changed(index:int)


func _ready() -> void:
	%GradientEdit.remove_popup_button()
	%Pin.icon = get_theme_icon("pin_unpinned", "MM_Icons")
	%Previous.icon = get_theme_icon("arrow_left", "MM_Icons")
	%Next.icon = get_theme_icon("arrow_right", "MM_Icons")


func set_gradient(value:MMGradient, cursor_index := 0) -> void:
	%GradientEdit.value = value

	# Usually the gradient isn't instantly loaded,
	# because the nodes size isn't yet correct, so we wait until the Cursors are loaded
	await %GradientEdit.value_was_set
	%Interpolation.selected = value.interpolation
	%GradientEdit.active_cursor = cursor_index


# Handle closing the popup
func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(get_global_mouse_position()):
			if not %Pin.button_pressed:
				close()
				accept_event()


func close() -> void:
	about_to_close.emit()
	queue_free()


func _on_gradient_edit_updated(value: Variant, merge_undos: bool) -> void:
	# Propagate changes to the parent GradientEdit
	updated.emit(value, merge_undos)

	# Update values of the active cursor
	_on_gradient_edit_active_cursor_changed()


func _on_gradient_edit_active_cursor_changed() -> void:
	active_cursor_changed.emit(%GradientEdit.active_cursor)

	var active_cursor = %GradientEdit.get_active_cursor()
	%Offset.set_value(snappedf(active_cursor.get_cursor_offset(), 0.001))
	%ColorRect.color = active_cursor.color
	%ColorRect.color.a = 1


func _on_interpolation_item_selected(index: int) -> void:
	%GradientEdit.set_interpolation(index)


func _on_offset_value_changed_undo(value: Variant, merge_undo: Variant) -> void:
	%GradientEdit.get_active_cursor().set_cursor_offset(value, merge_undo)


func _on_color_button_pressed() -> void:
	%GradientEdit.select_color(%GradientEdit.get_active_cursor())


func _on_previous_pressed() -> void:
	%GradientEdit.active_cursor -= 1


func _on_next_pressed() -> void:
	%GradientEdit.active_cursor += 1
