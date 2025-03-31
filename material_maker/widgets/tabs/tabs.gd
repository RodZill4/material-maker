extends Panel

var current_tab : int = -1 :
	get:
		return current_tab
	set(new_value):
		if new_value < 0 or new_value >= $TabBar.get_tab_count():
			return
		var node
		if current_tab >= 0 && current_tab < $TabBar.get_tab_count():
			node = get_child(current_tab)
			node.visible = false
		current_tab = new_value
		node = get_child(current_tab)
		node.visible = true
		node.anchor_left = 0
		node.anchor_right = 0
		node.anchor_top = 0
		node.anchor_bottom = 0
		node.position = Vector2(0, $TabBar.size.y)
		node.size = size - node.position - Vector2(6, 6)
		$TabBar.current_tab = current_tab
		emit_signal("tab_changed", current_tab)

signal tab_changed(tab : int)
signal no_more_tabs

func add_tab(control, legible_unique_name = false) -> void:
	add_child(control, legible_unique_name)
	assert(! control is TabBar)
	move_child(control, $TabBar.get_tab_count())
	$TabBar.add_tab(control.name)
	control.visible = false
	_on_Projects_resized()

func set_current_tab(t : int):
	current_tab = t
	mm_globals.main_window.update_menus()

func close_tab(tab = null) -> void:
	if tab == null:
		tab = $TabBar.get_current_tab()
	var result = await check_save_tab(tab)
	if result:
		do_close_tab(tab)
	mm_globals.main_window.update_menus()

func get_tab_count() -> int:
	return $TabBar.get_tab_count()

func get_tab(i : int) -> Control:
	return $TabBar.get_child(i) as Control

func check_save_tabs() -> bool:
	for i in range($TabBar.get_tab_count()):
		var result = await check_save_tab(i)
		if !result:
			return false
	return true

func check_save_tab(tab) -> bool:
	var tab_control = get_child(tab)
	if tab_control.need_save and mm_globals.get_config("confirm_close_project"):
		var dialog = preload("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instantiate()
		var save_path = tab_control.save_path
		if save_path == null:
			save_path = "[unnamed]"
		else:
			save_path = save_path.get_file()
		if save_path == "":
			save_path = "file"
		dialog.dialog_text = "Save "+save_path+" before closing?"
		#dialog.dialog_autowrap = true
		dialog.get_ok_button().text = "Save and close"
		dialog.add_button("Discard changes", true, "discard")
		dialog.add_cancel_button("Cancel")
		get_parent().add_child(dialog)
		var result = await dialog.ask()
		match result:
			"ok":
				var status = await mm_globals.main_window.save_project(tab_control)
				if !status:
					return false
			"cancel":
				return false
			_:
				if tab_control.has_method("remove_crash_recovery_file"):
					tab_control.remove_crash_recovery_file()
	return true

func do_close_custom_action(_action : String, _tab : int, dialog : AcceptDialog) -> void:
	dialog.queue_free()


func do_close_tab(tab = null) -> void:
	get_child(tab).queue_free()
	$TabBar.remove_tab(tab)
	var control = get_child(tab)
	remove_child(control)
	control.free()
	current_tab = -1
	if $TabBar.get_tab_count() == 0:
		emit_signal("no_more_tabs")
	else:
		current_tab = 0

func move_active_tab_to(idx_to) -> void:
	$TabBar.move_tab(current_tab, idx_to)
	move_child(get_child(current_tab), idx_to)
	current_tab = idx_to

func set_tab_title(index, title) -> void:
	$TabBar.set_tab_title(index, title)

func get_current_tab_control() -> Node:
	if current_tab >= 0 and current_tab < $TabBar.get_tab_count():
		return get_child(current_tab)
	return null

func _on_Tabs_tab_changed(tab) -> void:
	current_tab = tab

func _on_Projects_resized() -> void:
	$TabBar.anchor_left = 0
	$TabBar.anchor_right = 0
	$TabBar.anchor_top = 0
	$TabBar.anchor_bottom = 0
	$TabBar.size.x = size.x
	if current_tab >= 0:
		var node = get_child(current_tab)
		node.position = Vector2(0, $TabBar.size.y)
		node.size = size - node.position - Vector2(6, 6)

func _on_CrashRecoveryTimer_timeout():
	for i in range($TabBar.get_tab_count()):
		var tab_control = get_child(i)
		if tab_control.has_method("crash_recovery_save"):
			tab_control.crash_recovery_save()

func _input(event: InputEvent) -> void:
	# Navigate between tabs using keyboard shortcuts.
	if event.is_action_pressed("ui_previous_tab"):
		current_tab = wrapi(current_tab - 1, 0, $TabBar.get_tab_count())
	elif event.is_action_pressed("ui_next_tab"):
		current_tab = wrapi(current_tab + 1, 0, $TabBar.get_tab_count())

func _gui_input(event: InputEvent) -> void:
	# Navigate between tabs by hovering tabs then using the mouse wheel.
	# Only take into account the mouse wheel scrolling on the tabs themselves,
	# not their content.
	var rect := get_global_rect()
	# Roughly matches the height of the tabs bar itself (with some additional tolerance for better usability).
	rect.size.y = 30
	if event is InputEventMouseButton and event.pressed and rect.has_point(get_global_mouse_position()):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_tab = wrapi(current_tab - 1, 0, $TabBar.get_tab_count())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_tab = wrapi(current_tab + 1, 0, $TabBar.get_tab_count())
