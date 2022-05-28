extends WindowDialog

signal return_status(status)

var mesh_filename    = null
var project_filename = null

onready var mesh_instance : MeshInstance = $VBoxContainer/Main/ViewportContainer/Viewport/MeshPivot/MeshInstance
onready var button_ok : Button = $VBoxContainer/Buttons/OK
onready var camera : Camera = $VBoxContainer/Main/ViewportContainer/Viewport/CameraPivot/Camera
onready var viewport_container : ViewportContainer = $VBoxContainer/Main/ViewportContainer
onready var viewport : Viewport = $VBoxContainer/Main/ViewportContainer/Viewport
onready var error_label : Label = $VBoxContainer/Main/ViewportContainer/Error

func _on_ViewportContainer_resized():
	viewport.size = $VBoxContainer/Main/ViewportContainer.rect_size

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
	var mesh : ArrayMesh = $ObjLoader.load_obj_file(mesh_filename)
	if mesh != null:
		mesh_instance.mesh = mesh
		$VBoxContainer/Main/VBoxContainer/GridContainer/ModelFile.text = mesh_filename.get_file()
		button_ok.disabled = false
		# Initialise project file name
		set_project(mesh_filename.get_basename()+".mmpp")
		# Center the mesh and move the camera to the whole object is visible
		var aabb : AABB = mesh_instance.get_aabb()
		mesh_instance.transform.origin = -aabb.position-0.5*aabb.size
		var d : float = aabb.size.length()
		camera.transform.origin.z = 0.8*d
		var errors : PoolStringArray = PoolStringArray()
		if mesh.get_surface_count() > 1:
			errors.append("Mesh has several surfaces")
		if mesh.surface_get_format(0) & ArrayMesh.ARRAY_FORMAT_TEX_UV == 0:
			errors.append("Mesh does not have UVs")
		error_label.text = errors.join("\n")
	else:
		button_ok.disabled = true

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
	$VBoxContainer/Main/VBoxContainer/GridContainer/ProjectFile.text = project_filename.get_file()

func _on_OK_pressed():
	var mesh = mesh_instance.mesh
	emit_signal("return_status", { mesh=mesh, mesh_filename=mesh_filename, project_filename=project_filename, size=pow(2, $VBoxContainer/Main/VBoxContainer/GridContainer/Resolution.size_value) })

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
