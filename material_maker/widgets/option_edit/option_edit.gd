extends OptionButton


func _ready() -> void:
	get_popup().theme_type_variation = "MM_NodeOptionEditPopup"
	get_popup().about_to_popup.connect(_on_about_to_popup)
	get_popup().transparent_bg = true


func _gui_input(event: InputEvent) -> void:
	if event.is_command_or_control_pressed() and event is InputEventMouseButton and event.pressed:
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				selected = wrap(selected+1, 0, item_count)
			else:
				selected = wrap(selected-1, 0, item_count)

			item_selected.emit(selected)
			accept_event()


func _on_about_to_popup() -> void:
	# This would look better I think, 
	# but doesn't make sense until gui_embed_subwindows is turned back on.
	#get_popup().min_size.x = size.x
	pass
