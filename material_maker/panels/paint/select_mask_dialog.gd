extends WindowDialog

export var genmask_material : ShaderMaterial

var idmap_filename : String = ""
var idmap : ImageTexture
var mask : ImageTexture
var current_view_mode : int = 0

onready var mesh_instance : MeshInstance = $VBoxContainer/HBoxContainer/ViewportContainer/Viewport/MeshPivot/MeshInstance
onready var camera_pivot : Spatial = $VBoxContainer/HBoxContainer/ViewportContainer/Viewport/CameraPivot
onready var camera : Camera = $VBoxContainer/HBoxContainer/ViewportContainer/Viewport/CameraPivot/Camera
onready var viewport_container : ViewportContainer = $VBoxContainer/HBoxContainer/ViewportContainer
onready var viewport : Viewport = $VBoxContainer/HBoxContainer/ViewportContainer/Viewport
onready var texture_rect : TextureRect = $VBoxContainer/HBoxContainer/ViewportContainer/TextureRect


const CAMERA_DISTANCE_MIN = 0.5
const CAMERA_DISTANCE_MAX = 150.0
const CAMERA_FOV_MIN = 10
const CAMERA_FOV_MAX = 90


signal return_status(status)


func _ready():
	pass

func _on_ViewportContainer_resized():
	viewport.size = viewport_container.rect_size

func set_mesh(mesh : Mesh):
	var material = mesh_instance.get_surface_material(0)
	mesh_instance.mesh = mesh
	mesh_instance.set_surface_material(0, material)
	# Center the mesh and move the camera to the whole object is visible
	var aabb : AABB = mesh_instance.get_aabb()
	mesh_instance.transform.origin = -aabb.position-0.5*aabb.size
	var d : float = aabb.size.length()
	camera.transform.origin.z = 0.8*d

func _on_IdMapFile_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.png;PNG image file")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		set_idmap(files[0])

func set_idmap(ifn : String):
	idmap_filename = ifn
	var image : Image = Image.new()
	image.load(idmap_filename)
	idmap.create_from_image(image)
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/IdMapFile.text = idmap_filename.get_file()

func set_view_mode(index):
	var check_buttons : Array = [
									$VBoxContainer/HBoxContainer/VBoxContainer/ShowIdMap,
									$VBoxContainer/HBoxContainer/VBoxContainer/ShowMask,
									$VBoxContainer/HBoxContainer/VBoxContainer/ShowMix
								]
	check_buttons[index].pressed = true
	_on_Show_item_selected(index)

func _on_Show_item_selected(index):
	current_view_mode = index
	match current_view_mode:
		0:
			mesh_instance.get_surface_material(0).set_shader_param("tex", idmap)
			mesh_instance.get_surface_material(0).set_shader_param("mask", null)
		1:
			mesh_instance.get_surface_material(0).set_shader_param("tex", mask)
			mesh_instance.get_surface_material(0).set_shader_param("mask", null)
		2:
			mesh_instance.get_surface_material(0).set_shader_param("tex", idmap)
			mesh_instance.get_surface_material(0).set_shader_param("mask", mask)

func _on_Reset_pressed():
	var image : Image = Image.new()
	image.create(16, 16, 0, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1))
	mask.create_from_image(image)

func update_mask_from_mouse_position(mouse_position : Vector2):
	var texture : ViewportTexture = viewport.get_texture()
	var showing_mask : bool = ( current_view_mode != 0 )
	if showing_mask:
		# Hide viewport while we capture the position
		var hide_texture : ImageTexture = ImageTexture.new()
		hide_texture.create_from_image(viewport.get_texture().get_data())
		texture_rect.texture = hide_texture
		texture_rect.visible = true
		mesh_instance.get_surface_material(0).set_shader_param("tex", idmap)
		mesh_instance.get_surface_material(0).set_shader_param("mask", null)
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	var image : Image = texture.get_data()
	image.lock()
	mouse_position.y = viewport.size.y-mouse_position.y
	var position_color : Color = image.get_pixelv(mouse_position)
	image.unlock()
	if showing_mask:
		_on_Show_item_selected(current_view_mode)
		texture_rect.visible = false
	genmask_material.set_shader_param("idmap", idmap)
	genmask_material.set_shader_param("color", position_color)
	var renderer = mm_renderer.request(self)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	if renderer == null:
		return
	renderer = renderer.render_material(self, genmask_material, idmap.get_size().x)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer.copy_to_texture(mask)
	renderer.release(self)

func zoom(amount : float):
	camera.translation.z = clamp(camera.translation.z*amount, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)

func _on_ViewportContainer_gui_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == BUTTON_MASK_MIDDLE:
			mesh_instance.rotation.y += 0.01*event.relative.x
			camera_pivot.rotation.x -= 0.01*event.relative.y
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if event.command:
				camera.fov = clamp(camera.fov + 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
			else:
				zoom(1.0 / (1.01 if event.shift else 1.1))
		elif event.button_index == BUTTON_WHEEL_DOWN:
			if event.command:
				camera.fov = clamp(camera.fov - 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
			else:
				zoom(1.01 if event.shift else 1.1)
		elif event.pressed and event.button_index == BUTTON_LEFT and idmap_filename != "":
			update_mask_from_mouse_position(viewport_container.get_local_mouse_position())

func _on_OK_pressed():
	var mesh = mesh_instance.mesh
	emit_signal("return_status", { idmap_filename=idmap_filename, mask=mask })

func _on_NewPainterWindow_popup_hide():
	yield(get_tree(), "idle_frame")
	emit_signal("return_status", { idmap_filename=idmap_filename, mask=mask })

func ask(parameters : Dictionary) -> String:
	var config_cache = get_node("/root/MainWindow").config_cache
	set_mesh(parameters.mesh)
	# Create idmap texture
	idmap = ImageTexture.new()
	if parameters.has("idmap_filename") and parameters.idmap_filename != null and parameters.idmap_filename != "":
		set_idmap(parameters.idmap_filename)
	else:
		var image : Image = Image.new()
		image.create(16, 16, 0, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0))
		idmap.create_from_image(image)
	# Get mask texture
	assert(parameters.has("mask"))
	mask = parameters.mask
	var view_mode = 0
	if config_cache.has_section_key("select_mask_dialog", "view_mode"):
		view_mode = config_cache.get_value("select_mask_dialog", "view_mode")
	if config_cache.has_section_key("select_mask_dialog", "rx"):
		mesh_instance.rotation.y = config_cache.get_value("select_mask_dialog", "rx")
	if config_cache.has_section_key("select_mask_dialog", "ry"):
		camera_pivot.rotation.x = config_cache.get_value("select_mask_dialog", "ry")
	set_view_mode(view_mode)
	popup_centered()
	_on_ViewportContainer_resized()
	var result = yield(self, "return_status")
	config_cache.set_value("select_mask_dialog", "view_mode", current_view_mode)
	config_cache.set_value("select_mask_dialog", "rx", mesh_instance.rotation.y)
	config_cache.set_value("select_mask_dialog", "ry", camera_pivot.rotation.x)
	queue_free()
	return result

func _on_VBoxContainer_minimum_size_changed():
	rect_size = $VBoxContainer.rect_size+Vector2(4, 4)
