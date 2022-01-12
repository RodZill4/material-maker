extends WindowDialog

var config: ConfigFile

signal config_changed


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()


func edit_preferences(c: ConfigFile) -> void:
	config = c
	update_controls(self)
	popup_centered()


func update_controls(p: Node) -> void:
	for c in p.get_children():
		if c.has_method("init_from_config"):
			c.init_from_config(config)
		update_controls(c)


func update_config(p: Node) -> void:
	for c in p.get_children():
		if c.has_method("update_config"):
			c.update_config(config)
		update_config(c)


func _on_Apply_pressed():
	update_config(self)
	emit_signal("config_changed")


func _on_OK_pressed():
	update_config(self)
	emit_signal("config_changed")
	queue_free()


func _on_Cancel_pressed():
	queue_free()


func _on_VBoxContainer_minimum_size_changed():
	rect_size = $VBoxContainer.rect_size + Vector2(4, 4)


func _on_InstallLanguage_pressed():
	var dialog = load("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.po,*.translation,*.csv;Translation file")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		var locale = load("res://material_maker/locale/locale.gd").new()
		locale.install_translation(files[0])
		$VBoxContainer/TabContainer/General/HBoxContainer/Language.init_from_locales()
		$VBoxContainer/TabContainer/General/HBoxContainer/Language.init_from_config(config)
