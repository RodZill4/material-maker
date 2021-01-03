extends Panel

var current_tab = -1 setget set_current_tab

signal tab_changed
signal no_more_tabs

func add_child(control, legible_unique_name = false) -> void:
	.add_child(control, legible_unique_name)
	if !(control is Tabs):
		$Tabs.add_tab(control.name)
		move_child(control, $Tabs.get_tab_count()-1)

func close_tab(tab = null) -> void:
	if tab == null:
		tab = $Tabs.get_current_tab()
	var result = check_save_tab(tab)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	if result:
		do_close_tab(tab)

func get_tab_count() -> int:
	return $Tabs.get_tab_count()

func get_tab(i : int) -> Control:
	return $Tabs.get_child(i) as Control

func check_save_tabs() -> bool:
	for i in range($Tabs.get_tab_count()):
		var result = check_save_tab(i)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		if !result:
			return false
	return true

func check_save_tab(tab) -> bool:
	var tab_control = get_child(tab)
	var main_window = get_node("/root/MainWindow")
	if tab_control.need_save and main_window.get_config("confirm_close_project"):
		var dialog = preload("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instance()
		var save_path = tab_control.save_path
		if save_path == null:
			save_path = "[unnamed]"
		else:
			save_path = save_path.get_file()
		dialog.dialog_text = "Save "+save_path+" before closing?"
		#dialog.dialog_autowrap = true
		dialog.get_ok().text = "Save and close"
		dialog.add_button("Discard changes", true, "discard")
		dialog.add_cancel("Cancel")
		get_parent().add_child(dialog)
		var result = dialog.ask()
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		match result:
			"ok":
				var status = main_window.save_material(tab_control)
				while status is GDScriptFunctionState:
					status = yield(status, "completed")
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
	$Tabs.remove_tab(tab)
	var control = get_child(tab)
	remove_child(control)
	control.free()
	current_tab = -1
	if $Tabs.get_tab_count() == 0:
		emit_signal("no_more_tabs")
	else:
		set_current_tab(0)

func move_active_tab_to(idx_to) -> void:
	$Tabs.move_tab(current_tab, idx_to)
	move_child(get_child(current_tab), idx_to)
	set_current_tab(idx_to)

func set_current_tab(t) -> void:
	if t == current_tab or t < 0 or t >= $Tabs.get_tab_count():
		return
	var node
	if current_tab >= 0 && current_tab < $Tabs.get_tab_count():
		node = get_child(current_tab)
		node.visible = false
	current_tab = t
	node = get_child(current_tab)
	node.visible = true
	node.rect_position = Vector2(0, $Tabs.rect_size.y)
	node.rect_size = rect_size - node.rect_position
	$Tabs.current_tab = current_tab
	emit_signal("tab_changed", current_tab)

func set_tab_title(index, title) -> void:
	$Tabs.set_tab_title(index, title)

func get_current_tab_control() -> Node:
	return get_child(current_tab)

func _on_Tabs_tab_changed(tab) -> void:
	set_current_tab(tab)

func _on_Projects_resized() -> void:
	$Tabs.rect_size.x = rect_size.x


func _on_CrashRecoveryTimer_timeout():
	for i in range($Tabs.get_tab_count()):
		var tab_control = get_child(i)
		if tab_control.has_method("crash_recovery_save"):
			tab_control.crash_recovery_save()
