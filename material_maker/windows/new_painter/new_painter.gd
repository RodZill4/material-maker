extends WindowDialog

signal return_status(status)

var mesh_filename    = null
var project_filename = null

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
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		set_mesh(files[0])

func set_mesh(file_name : String) -> void:
	if file_name == mesh_filename:
		return
	mesh_filename = file_name
	var mesh : Mesh = $ObjLoader.load_obj_file(mesh_filename)
	if mesh != null:
		$VBoxContainer/HBoxContainer/ViewportContainer/Viewport/MeshInstance.mesh = mesh
		$VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/ModelFile.text = mesh_filename.get_file()
		$VBoxContainer/HBoxContainer2/OK.disabled = false
		if project_filename == null:
			set_project(mesh_filename.get_basename()+".mmpp")
	else:
		$VBoxContainer/HBoxContainer2/OK.disabled = true

func _on_ProjectFile_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.mmpp;Material Maker paint project file")
	#if config_cache.has_section_key("path", "material"):
	#	dialog.current_dir = config_cache.get_value("path", "material")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		set_project(files[0])

func set_project(file_name : String) -> void:
	if file_name == project_filename:
		return
	project_filename = file_name
	$VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/ProjectFile.text = project_filename.get_file()

func _on_OK_pressed():
	var mesh = $VBoxContainer/HBoxContainer/ViewportContainer/Viewport/MeshInstance.mesh
	emit_signal("return_status", { mesh=mesh, mesh_filename=mesh_filename, project_filename=project_filename, size=pow(2, $VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Resolution.size_value) })

func _on_Cancel_pressed():
	emit_signal("return_status", null)

func _on_NewPainterWindow_popup_hide():
	yield(get_tree(), "idle_frame")
	emit_signal("return_status", null)

func ask(obj_file_name = null) -> String:
	if obj_file_name != null:
		set_mesh(obj_file_name)
	popup_centered()
	_on_ViewportContainer_resized()
	var result = yield(self, "return_status")
	queue_free()
	return result


