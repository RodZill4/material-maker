extends PanelContainer

var export_settings := {
	"path" : "preview$SUFFIX_last_export_path",
	"resolution" : "preview$SUFFIX_last_export_resolution",
	"extension" : "preview$SUFFIX_last_export_extension",
	"file_name" : "preview$SUFFIX_last_export_file_name",
	#"export_type" : "preview$SUFFIX_last_export_type",
	}

func _ready() -> void:
	for val in export_settings.values():
		val = val.replace("$SUFFIX", owner.config_var_suffix)
	
	owner.generator_changed.connect(update)

func _open() -> void:
	if mm_globals.has_config(export_settings.path):
		%ExportFolder.text = mm_globals.get_config(export_settings.path)
	
	if mm_globals.has_config(export_settings.file_name):
		%ExportFile.text = mm_globals.get_config(export_settings.file_name)
	%ExportFileResultLabel.text = interpret_file_name(%ExportFile.text)
	
	if mm_globals.has_config(export_settings.resolution):
		%Resolution.selected = mm_globals.get_config(export_settings.resolution)
	
	if mm_globals.has_config(export_settings.resolution):
		%Resolution.selected = mm_globals.get_config(export_settings.resolution)
	
	if mm_globals.has_config(export_settings.extension):
		%FileType.selected = mm_globals.get_config(export_settings.extension)
	
	export_notification("")


func update() -> void:
	if not is_visible_in_tree():
		return
	
	var file_result := interpret_file_name(%ExportFile.text)
	%ExportFileResultLabel.text = file_result
	%ExportFileResultLabel.visible = not %ExportFile.text.is_empty() and %ExportFile.text.count("$") != file_result.count("$")


func _on_export_folder_text_changed(new_text: String) -> void:
	mm_globals.set_config(export_settings.path, new_text)


func _on_export_folder_button_pressed() -> void:
	var file_dialog := preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	#file_dialog.add_filter("*.png; PNG image file")
	#file_dialog.add_filter("*.exr; EXR image file")
	
	if %ExportFolder.text:
		file_dialog.current_dir = mm_globals.config.get_value("path", %ExportFolder.text)
	
	var files = await file_dialog.select_files()
	
	if files.size() == 1:
		%ExportFolder.text = files[0]
		_on_export_folder_text_changed(files[0])
		%ExportFolder.tooltip_text = files[0]


func _on_export_file_text_changed(new_text: String) -> void:
	mm_globals.set_config(export_settings.file_name, new_text)
	update()


func _on_file_type_item_selected(index: int) -> void:
	mm_globals.set_config(export_settings.extension, index)
	update()


func _on_resolution_item_selected(index: int) -> void:
	mm_globals.set_config(export_settings.resolution, index)


func _on_image_pressed() -> void:
	var path: String = %ExportFolder.text
	var file_name: String = %ExportFile.text
	
	if path.is_empty():
		var file_dialog := preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		
		if not file_name.is_empty():
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		else:
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.add_filter("*.png; PNG image file")
			file_dialog.add_filter("*.exr; EXR image file")
		
		if mm_globals.config.has_section_key("path", "save_preview"):
			file_dialog.current_dir = mm_globals.config.get_value("path", "save_preview")
	
		var files = await file_dialog.select_files()
		
		if files.size() > 0:
			path = files[0]
	
	
	if file_name:
		file_name = interpret_file_name(file_name, path)
		
		path = path.path_join(file_name)
	
	
	if path:
		owner.export_as_image_file(path, 64 << %Resolution.selected)
		export_notification("Exported to " + path)
		await get_tree().create_timer(0.5).timeout
		update()


func _on_animation_pressed() -> void:
	owner.export_animation()


func _on_taa_render_pressed() -> void:
	owner.export_taa()


func _on_reference_pressed() -> void:
	owner.export_to_reference(%Resolution.selected)
	export_notification("Exported to Reference")


func export_notification(text:String) -> void:
	%ExportNotificationLabel.text = text
	%ExportNotificationLabel.visible = not text.is_empty()


func interpret_file_name(file_name: String, path:="") -> String:
	if path.is_empty():
		path = %ExportFolder.text
	
	if owner.generator:
		file_name = file_name.replace("$node", owner.generator.name)
	else:
		file_name = file_name.replace("$node", "unnamed")
	
	var current_graph: MMGraphEdit = find_parent("MainWindow").get_current_graph_edit()
	if current_graph.save_path:
		file_name = file_name.replace("$project", current_graph.save_path.get_file().trim_suffix("."+current_graph.save_path.get_extension()))
	else:
		file_name = file_name.replace("$project", "unnamed_project")
	
	match %FileType.selected:
		0: file_name += ".png"
		1: file_name += ".exr"
	
	if "$idx" in file_name:
		if path:
			var idx := 1
			while FileAccess.file_exists(path.path_join(file_name).replace("$idx", str(idx).pad_zeros(2))):
				idx += 1
			file_name = file_name.replace("$idx", str(idx).pad_zeros(2))
		else:
			file_name = file_name.replace("$idx", str(1).pad_zeros(2))
	return file_name
