class_name MM_OptionEdit
extends OptionButton


func _ready() -> void:
	get_popup().theme_type_variation = "MM_NodeOptionEditPopup"
	get_popup().about_to_popup.connect(_on_about_to_popup)
	get_popup().transparent_bg = true


func _gui_input(event: InputEvent) -> void:
	if event.is_command_or_control_pressed() and event is InputEventMouseButton and event.pressed:
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
			roll(event.button_index == MOUSE_BUTTON_WHEEL_DOWN)
			accept_event()


func roll(roll_up:= false) -> void:
	if roll_up:
		selected = wrap(selected-1, 0, item_count)
	else:
		selected = wrap(selected+1, 0, item_count)
	
	item_selected.emit(selected)


func _on_about_to_popup() -> void:
	# This would look better I think, 
	# but doesn't make sense until gui_embed_subwindows is turned back on.
	#get_popup().min_size.x = size.x
	pass


func _input(event:InputEvent) -> void:
	if is_visible_in_tree() and shortcut and shortcut.matches_event(event) and event.is_pressed():
		roll()
		accept_event()
	
	if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		return
	if event is InputEventKey and event.is_command_or_control_pressed() and event.pressed:
		if event.keycode == KEY_C:
			DisplayServer.clipboard_set(str(selected))
			accept_event()
		if event.keycode == KEY_V:
			var v := DisplayServer.clipboard_get()
			if v.is_valid_int():
				selected = min(max(0, int(v)),item_count-1)
			accept_event()
