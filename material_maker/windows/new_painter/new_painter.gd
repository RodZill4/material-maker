extends Window


@export var mesh_material : Material

var mesh_filename    = null
var project_filename = null

@onready var mesh_instance : MeshInstance3D = $VBoxContainer/Main/SubViewportContainer/SubViewport/MeshPivot/MeshInstance3D
@onready var button_ok : Button = $VBoxContainer/Buttons/OK
@onready var camera : Camera3D = $VBoxContainer/Main/SubViewportContainer/SubViewport/CameraPivot/Camera3D
@onready var viewport_container : SubViewportContainer = $VBoxContainer/Main/SubViewportContainer
@onready var viewport : SubViewport = $VBoxContainer/Main/SubViewportContainer/SubViewport
@onready var error_label : Label = $VBoxContainer/Main/SubViewportContainer/Error


signal return_status(status : Dictionary)


func _ready():
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = Vector2(500, 300) * content_scale_factor
	if mesh_material:
		mesh_instance.set_surface_override_material(0, mesh_material)

func _on_ViewportContainer_resized():
	viewport.size = viewport_container.size

func _on_ModelFile_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.glb,*.gltf;GLTF file")
	dialog.add_filter("*.obj;Wavefront OBJ file")
	dialog.add_filter("*.fbx;FBX file")
	var files = await dialog.select_files()
	if files.size() == 1:
		set_mesh(files[0])
	await get_tree().process_frame
	grab_focus()

func set_mesh(file_name : String) -> void:
	if file_name == mesh_filename:
		return
	mesh_filename = file_name
	var mesh : ArrayMesh = MMMeshLoader.load_mesh(mesh_filename)
	if mesh != null:
		mesh_instance.mesh = mesh
		$VBoxContainer/Main/VBoxContainer/GridContainer/ModelFile.text = mesh_filename.get_file()
		button_ok.disabled = false
		# Initialise project file name
		set_project(mesh_filename.get_basename()+".mmpp")
		# Apply the mesh material
		if mesh_material:
			mesh_instance.set_surface_override_material(0, mesh_material)
		# Center the mesh and move the camera to the whole object is visible
		var aabb : AABB = mesh_instance.get_aabb()
		mesh_instance.transform.origin = -aabb.position-0.5*aabb.size
		var d : float = aabb.size.length()
		camera.transform.origin.z = 0.5*d+0.5
		camera.near = 0.01
		camera.far = d
		# Show errors if any
		var errors : PackedStringArray = PackedStringArray()
		if mesh.get_surface_count() > 1:
			errors.append("Mesh has several surfaces")
		if mesh.surface_get_format(0) & ArrayMesh.ARRAY_FORMAT_TEX_UV == 0:
			errors.append("Mesh does not have UVs")
		error_label.text = "\n".join(errors)
	else:
		button_ok.disabled = true

func _on_ProjectFile_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mmpp;Material Maker paint project file")
	#if mm_globals.config.has_section_key("path", "material"):
	#	dialog.current_dir = mm_globals.config.get_value("path", "material")
	var files = await dialog.select_files()
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
	emit_signal("return_status", {})

func _on_NewPainterWindow_popup_hide():
	await get_tree().process_frame
	emit_signal("return_status", {})

func ask(obj_file_name = null) -> Dictionary:
	mm_globals.main_window.add_dialog(self)
	if obj_file_name != null:
		set_mesh(obj_file_name)
	hide()
	popup_centered()
	_on_ViewportContainer_resized()
	var result = await self.return_status
	queue_free()
	return result
