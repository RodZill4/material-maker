extends Window

@export var genmask_material : ShaderMaterial

var idmap_filename : String = ""
var idmap : ImageTexture
var mask : MMTexture
var current_view_mode : int = 0

@onready var mesh_instance : MeshInstance3D = $VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/MeshPivot/MeshInstance3D
@onready var camera_pivot : Node3D = $VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/CameraPivot
@onready var camera : Camera3D = $VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/CameraPivot/Camera3D
@onready var viewport_container : SubViewportContainer = $VBoxContainer/HBoxContainer/SubViewportContainer
@onready var viewport : SubViewport = $VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport
@onready var texture_rect : TextureRect = $VBoxContainer/HBoxContainer/SubViewportContainer/TextureRect


const CAMERA_DISTANCE_MIN = 0.5
const CAMERA_DISTANCE_MAX = 150.0
const CAMERA_FOV_MIN = 10
const CAMERA_FOV_MAX = 90


signal return_status(status)


func set_mesh(mesh : Mesh):
	var material = mesh_instance.get_surface_override_material(0)
	mesh_instance.mesh = mesh
	mesh_instance.set_surface_override_material(0, material)
	# Center the mesh and move the camera to the whole object is visible
	var aabb : AABB = mesh_instance.get_aabb()
	mesh_instance.transform.origin = -aabb.position-0.5*aabb.size
	var d : float = aabb.size.length()
	camera.transform.origin.z = 0.8*d

func _on_IdMapFile_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.png;PNG image file")
	var files = await dialog.select_files()
	if files.size() == 1:
		set_idmap(files[0])

func set_idmap(ifn : String):
	idmap_filename = ifn
	var image : Image = Image.new()
	image.load(idmap_filename)
	idmap.set_image(image)
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/IdMapFile.text = idmap_filename.get_file()

func set_view_mode(index):
	var check_buttons : Array = [
									$VBoxContainer/HBoxContainer/VBoxContainer/ShowIdMap,
									$VBoxContainer/HBoxContainer/VBoxContainer/ShowMask,
									$VBoxContainer/HBoxContainer/VBoxContainer/ShowMix
								]
	check_buttons[index].button_pressed = true
	_on_Show_item_selected(index)

func _on_Show_item_selected(index : int):
	var material : ShaderMaterial = mesh_instance.get_surface_override_material(0)
	current_view_mode = index
	var mask_texture : Texture2D = await mask.get_texture()
	material.set_shader_parameter("tex", idmap)
	material.set_shader_parameter("mask", mask_texture)
	material.set_shader_parameter("mode", current_view_mode)

func _on_Reset_pressed():
	var image : Image = Image.new()
	image.create(16, 16, 0, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1))
	var mask_texture : Texture2D = await mask.get_texture()
	mask_texture.set_image(image)
	mask.set_texture(mask_texture)

func update_mask_from_mouse_position(mouse_position : Vector2):
	var texture : ViewportTexture = viewport.get_texture()
	var showing_mask : bool = ( current_view_mode != 0 )
	if showing_mask:
		# Hide viewport while we capture the position
		var material : ShaderMaterial = mesh_instance.get_surface_override_material(0)
		var hide_texture : ImageTexture = ImageTexture.new()
		hide_texture.set_image(viewport.get_texture().get_image())
		texture_rect.texture = hide_texture
		texture_rect.visible = true
		material.set_shader_parameter("tex", idmap)
		material.set_shader_parameter("mode", 0)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
	var image : Image = texture.get_image()
	mouse_position.y = mouse_position.y
	var position_color : Color = image.get_pixelv(mouse_position)
	if showing_mask:
		_on_Show_item_selected(current_view_mode)
		texture_rect.visible = false
	genmask_material.set_shader_parameter("idmap", idmap)
	genmask_material.set_shader_parameter("color", position_color)
	var renderer = await mm_renderer.request(self)
	if renderer == null:
		return
	renderer = await renderer.render_material(self, genmask_material, idmap.get_size().x)
	var mask_texture : Texture2D = await mask.get_texture()
	renderer.copy_to_texture(mask_texture)
	mask.set_texture(mask_texture)
	renderer.release(self)

func zoom(amount : float):
	camera.position.z = clamp(camera.position.z*amount, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)

func _on_ViewportContainer_gui_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			mesh_instance.rotation.y += 0.01*event.relative.x
			camera_pivot.rotation.x -= 0.01*event.relative.y
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if event.is_command_or_control_pressed():
				camera.fov = clamp(camera.fov + 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
			else:
				zoom(1.0 / (1.01 if event.shift_pressed else 1.1))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.is_command_or_control_pressed():
				camera.fov = clamp(camera.fov - 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
			else:
				zoom(1.01 if event.shift_pressed else 1.1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and idmap_filename != "":
			update_mask_from_mouse_position(viewport_container.get_local_mouse_position())

func _on_OK_pressed():
	var mesh = mesh_instance.mesh
	emit_signal("return_status", { idmap_filename=idmap_filename, mask=mask })

func _on_NewPainterWindow_popup_hide():
	await get_tree().process_frame
	emit_signal("return_status", { idmap_filename=idmap_filename, mask=mask })

func ask(parameters : Dictionary) -> Dictionary:
	set_mesh(parameters.mesh)
	# Create idmap texture
	idmap = ImageTexture.new()
	if parameters.has("idmap_filename") and parameters.idmap_filename != null and parameters.idmap_filename != "":
		set_idmap(parameters.idmap_filename)
	else:
		var image : Image = Image.new()
		image.create(16, 16, 0, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0))
		idmap.set_image(image)
	# Get mask texture
	assert(parameters.has("mask"))
	mask = parameters.mask
	var view_mode = 0
	if mm_globals.config.has_section_key("select_mask_dialog", "view_mode"):
		view_mode = mm_globals.config.get_value("select_mask_dialog", "view_mode")
	if mm_globals.config.has_section_key("select_mask_dialog", "rx"):
		mesh_instance.rotation.y = mm_globals.config.get_value("select_mask_dialog", "rx")
	if mm_globals.config.has_section_key("select_mask_dialog", "ry"):
		camera_pivot.rotation.x = mm_globals.config.get_value("select_mask_dialog", "ry")
	set_view_mode(view_mode)
	popup_centered()
	var result = await self.return_status
	mm_globals.config.set_value("select_mask_dialog", "view_mode", current_view_mode)
	mm_globals.config.set_value("select_mask_dialog", "rx", mesh_instance.rotation.y)
	mm_globals.config.set_value("select_mask_dialog", "ry", camera_pivot.rotation.x)
	queue_free()
	return result

func _on_size_changed():
	$VBoxContainer.size = size

func _on_v_box_container_minimum_size_changed():
	min_size = $VBoxContainer.get_combined_minimum_size()
