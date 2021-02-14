extends ViewportContainer

const CAMERA_DISTANCE_MIN = 1.0
const CAMERA_DISTANCE_MAX = 10.0

export var ui_path : String = "UI/Preview3DUI"

onready var objects = $MaterialPreview/Preview3d/Objects
onready var current_object = objects.get_child(0)

onready var camera_stand = $MaterialPreview/Preview3d/CameraPivot
onready var camera = $MaterialPreview/Preview3d/CameraPivot/Camera

var ui

signal need_update(me)

const MENU = [
	{ menu="Model", submenu="model_list", description="Select" },
	{ menu="Model", command="configure_model", description="Configure" },
	{ menu="Model", command="rotate_model", description="Rotate", toggle=true },
	{ menu="Model/Generate map", submenu="generate_mesh_normal_map", description="Mesh normal" },
	{ menu="Model/Generate map", submenu="generate_inverse_uv_map", description="Inverse UV" },
	{ menu="Model/Generate map", submenu="generate_curvature_map", description="Curvature" },
	{ menu="Model/Generate map", submenu="generate_ao_map", description="Ambient Occlusion" },
	{ menu="Model/Generate map", submenu="generate_thickness_map", description="Thickness" },
	{ menu="Environment", submenu="environment_list", description="Select" }
]


var _mouse_start_position := Vector2.ZERO


func _ready() -> void:
	ui = get_node(ui_path)
	get_node("/root/MainWindow").create_menus(MENU, self, ui)
	$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	_on_Environment_item_selected(0)

	# Required for supersampling to work.
	$MaterialPreview.get_texture().flags = Texture.FLAG_FILTER

	$MaterialPreview.connect("size_changed", self, "_on_material_preview_size_changed")

func create_menu_model_list(menu : PopupMenu) -> void:
	menu.clear()
	for i in objects.get_child_count():
		var o = objects.get_child(i)
		var thumbnail := load("res://material_maker/panels/preview_3d/thumbnails/meshes/%s.png" % o.name)
		if thumbnail:
			menu.add_icon_item(thumbnail, "", i)
		else:
			menu.add_item(o.name, i)
	if !menu.is_connected("id_pressed", self, "_on_Model_item_selected"):
		menu.connect("id_pressed", self, "_on_Model_item_selected")

func create_menu_environment_list(menu : PopupMenu) -> void:
	get_node("/root/MainWindow/EnvironmentManager").create_environment_menu(menu)
	if !menu.is_connected("id_pressed", self, "_on_Environment_item_selected"):
		menu.connect("id_pressed", self, "_on_Environment_item_selected")

func _on_Model_item_selected(id) -> void:
	if id == objects.get_child_count()-1:
		var dialog = FileDialog.new()
		add_child(dialog)
		dialog.rect_min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.mode = FileDialog.MODE_OPEN_FILE
		dialog.add_filter("*.obj;OBJ model File")
		if get_node("/root/MainWindow").config_cache.has_section_key("path", "mesh"):
			dialog.current_dir = get_node("/root/MainWindow").config_cache.get_value("path", "mesh")
		dialog.connect("file_selected", self, "do_load_custom_mesh")
		dialog.connect("popup_hide", dialog, "queue_free")
		dialog.popup_centered()
	else:
		select_object(id)

func do_load_custom_mesh(file_path) -> void:
	get_node("/root/MainWindow").config_cache.set_value("path", "mesh", file_path.get_base_dir())
	var id = objects.get_child_count()-1
	var mesh = $ObjLoader.load_obj_file(file_path)
	if mesh != null:
		var object : MeshInstance = objects.get_child(id)
		object.mesh = mesh
		object.update_material()
		select_object(id)

func select_object(id) -> void:
	current_object.visible = false
	current_object = objects.get_child(id)
	current_object.visible = true
	emit_signal("need_update", [ self ])

func _on_Environment_item_selected(id) -> void:
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	var environment = $MaterialPreview/Preview3d/CameraPivot/Camera.environment
	var sun = $MaterialPreview/Preview3d/Sun
	environment_manager.apply_environment(id, environment, sun)

func _on_material_preview_size_changed() -> void:
	# Apply supersampling to the new viewport size.
	$MaterialPreview.size = rect_size * get_node("/root/MainWindow").preview_rendering_scale_factor

func configure_model() -> void:
	var popup = preload("res://material_maker/panels/preview_3d/mesh_config_popup.tscn").instance()
	add_child(popup)
	popup.configure_mesh(current_object)

func rotate_model(button_pressed = null) -> bool:
	var object_rotate = $MaterialPreview/Preview3d/ObjectRotate
	if button_pressed is bool:
		if button_pressed:
			object_rotate.play("rotate")
		else:
			object_rotate.stop(false)
	return object_rotate.is_playing()

func get_materials() -> Array:
	if current_object != null and current_object.get_surface_material(0) != null:
		return [ current_object.get_surface_material(0) ]
	return []

func on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT or event.button_index == BUTTON_MIDDLE:
			# Don't stop rotating the preview on mouse wheel usage (zoom change).
			$MaterialPreview/Preview3d/ObjectRotate.stop(false)

		match event.button_index:
			BUTTON_WHEEL_UP:
				camera.translation.z = clamp(
					camera.translation.z / (1.01 if event.shift else 1.1),
					CAMERA_DISTANCE_MIN,
					CAMERA_DISTANCE_MAX
				)
			BUTTON_WHEEL_DOWN:
				camera.translation.z = clamp(
					camera.translation.z * (1.01 if event.shift else 1.1),
					CAMERA_DISTANCE_MIN,
					CAMERA_DISTANCE_MAX
				)
			BUTTON_LEFT, BUTTON_RIGHT:
				var mask : int = Input.get_mouse_button_mask()
				var lpressed : bool = (mask & BUTTON_MASK_LEFT) != 0
				var rpressed : bool = (mask & BUTTON_MASK_RIGHT) != 0
				if event.pressed and lpressed != rpressed: # xor
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					_mouse_start_position = event.global_position
				elif not lpressed and not rpressed:
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # allow and hide cursor warp
					Input.warp_mouse_position(_mouse_start_position)
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseMotion:
		var motion = 0.01*event.relative
		if abs(motion.y) > abs(motion.x):
			motion.x = 0
		else:
			motion.y = 0
		var camera_basis = camera.global_transform.basis
		var objects_rotation : int = -1 if event.control else 1 if event.shift else 0
		if event.button_mask & BUTTON_MASK_LEFT:
			objects.rotate(camera_basis.x.normalized(), objects_rotation * motion.y)
			objects.rotate(camera_basis.y.normalized(), objects_rotation * motion.x)
			if objects_rotation != 1:
				camera_stand.rotate(camera_basis.x.normalized(), -motion.y)
				camera_stand.rotate(camera_basis.y.normalized(), -motion.x)
		elif event.button_mask & BUTTON_MASK_RIGHT:
			objects.rotate(camera_basis.z.normalized(), objects_rotation * motion.x)
			if objects_rotation != 1:
				camera_stand.rotate(camera_basis.z.normalized(), -motion.x)


func generate_map(generate_function : String, size : int) -> void:
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image File")
	dialog.add_filter("*.exr;EXR image File")
	if get_node("/root/MainWindow").config_cache.has_section_key("path", "maps"):
		dialog.current_dir = get_node("/MainWindow").config_cache.get_value("path", "maps")
	dialog.connect("file_selected", self, generate_function, [ size ])
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func do_generate_map(file_name : String, map : String, size : int) -> void:
	var mesh_normal_mapper = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instance()
	add_child(mesh_normal_mapper)
	var id = objects.get_child_count()-1
	var object : MeshInstance = objects.get_child(id)
	var result = mesh_normal_mapper.gen(object.mesh, map, "save_to_file", [ file_name ], size)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	mesh_normal_mapper.queue_free()
	OS.clipboard = "{\"name\":\"image\",\"parameters\":{\"image\":\"%s\"},\"type\":\"image\"}" % file_name

func create_menu_map(menu : PopupMenu, function : String) -> void:
	menu.clear()
	for i in range(5):
		menu.add_item(str(256 << i)+"x"+str(256 << i), i)
	if !menu.is_connected("id_pressed", self, function):
		menu.connect("id_pressed", self, function)

func create_menu_generate_mesh_normal_map(menu) -> void:
	create_menu_map(menu, "generate_mesh_normal_map")

func generate_mesh_normal_map(i : int) -> void:
	generate_map("do_generate_mesh_normal_map", 256 << i)

func do_generate_mesh_normal_map(file_name : String, size : int) -> void:
	do_generate_map(file_name, "mesh_normal", size)

func create_menu_generate_inverse_uv_map(menu) -> void:
	create_menu_map(menu, "generate_inverse_uv_map")

func generate_inverse_uv_map(i : int) -> void:
	generate_map("do_generate_inverse_uv_map", 256 << i)

func do_generate_inverse_uv_map(file_name : String, size : int) -> void:
	do_generate_map(file_name, "inv_uv", size)

func create_menu_generate_curvature_map(menu) -> void:
	create_menu_map(menu, "generate_curvature_map")

func generate_curvature_map(i : int) -> void:
	generate_map("do_generate_curvature_map", 256 << i)

func do_generate_curvature_map(file_name : String, size : int) -> void:
	do_generate_map(file_name, "curvature", size)

func create_menu_generate_thickness_map(menu) -> void:
	create_menu_map(menu, "generate_thickness_map")

func generate_thickness_map(i : int) -> void:
	generate_map("do_generate_thickness_map", 256 << i)

func do_generate_thickness_map(file_name : String, size : int) -> void:
	do_generate_map(file_name, "thickness", size)

func create_menu_generate_ao_map(menu) -> void:
	create_menu_map(menu, "generate_ao_map")

func generate_ao_map(i : int) -> void:
	generate_map("do_generate_ao_map", 256 << i)

func do_generate_ao_map(file_name : String, size : int) -> void:
	do_generate_map(file_name, "ao", size)
