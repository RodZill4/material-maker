extends WindowDialog

signal return_status(status)

func _ready():
	pass

func _on_ViewportContainer_resized():
	$VBoxContainer/HBoxContainer/ViewportContainer/Viewport.size = $VBoxContainer/HBoxContainer/ViewportContainer.rect_size

func _on_ModelFile_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.obj;Wavefront OBJ file")
	#if config_cache.has_section_key("path", "material"):
	#	dialog.current_dir = config_cache.get_value("path", "material")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		var mesh : Mesh = $ObjLoader.load_obj_file(files[0])
		if mesh != null:
			$VBoxContainer/HBoxContainer/ViewportContainer/Viewport/MeshInstance.mesh = mesh
			$VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/ModelFile.text = files[0].get_file()

func _on_OK_pressed():
	var mesh = $VBoxContainer/HBoxContainer/ViewportContainer/Viewport/MeshInstance.mesh
	emit_signal("return_status", { mesh=mesh })

func _on_Cancel_pressed():
	emit_signal("return_status", null)

func _on_NewPainterWindow_popup_hide():
	yield(get_tree(), "idle_frame")
	emit_signal("return_status", null)

func ask() -> String:
	popup_centered()
	_on_ViewportContainer_resized()
	var result = yield(self, "return_status")
	queue_free()
	return result
