extends ViewportContainer

const CAMERA_DISTANCE_MIN = 1.0
const CAMERA_DISTANCE_MAX = 10.0

export var ui_path : String = "UI/Preview3DUI"

onready var objects = $MaterialPreview/Preview3d/Objects
onready var current_object = objects.get_child(0)

onready var environments = $MaterialPreview/Preview3d/Environments
onready var current_environment = environments.get_child(0)

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
	{ menu="Environment", submenu="environment_list", description="Select" }
]

var _mouse_start_position := Vector2.ZERO


func _ready() -> void:
	ui = get_node(ui_path)
	get_node("/root/MainWindow").create_menus(MENU, self, ui)
	$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	_on_Environment_item_selected(0)

func create_menu_model_list(menu : PopupMenu) -> void:
	menu.clear()
	for i in objects.get_child_count():
		var o = objects.get_child(i)
		menu.add_item(o.name, i)
	if !menu.is_connected("id_pressed", self, "_on_Model_item_selected"):
		menu.connect("id_pressed", self, "_on_Model_item_selected")

func create_menu_environment_list(menu : PopupMenu) -> void:
	menu.clear()
	for i in environments.get_child_count():
		var e = environments.get_child(i)
		menu.add_item(e.name, i)
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
		object.set_surface_material(0, SpatialMaterial.new())
		select_object(id)

func select_object(id) -> void:
	current_object.visible = false
	current_object = objects.get_child(id)
	current_object.visible = true
	emit_signal("need_update", [ self ])

func _on_Environment_item_selected(id) -> void:
	current_environment.visible = false
	current_environment = environments.get_child(id)
	$MaterialPreview/Preview3d/CameraPivot/Camera.set_environment(current_environment.environment)
	current_environment.visible = true

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
				var mask := Input.get_mouse_button_mask()
				var lpressed := mask & BUTTON_MASK_LEFT
				var rpressed := mask & BUTTON_MASK_RIGHT
				if event.pressed and ((lpressed and not rpressed) or (not lpressed and rpressed)): # xor
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
		if event.shift:
			if event.button_mask & BUTTON_MASK_LEFT:
				objects.rotate(camera_basis.x.normalized(), motion.y)
				objects.rotate(camera_basis.y.normalized(), motion.x)
			elif event.button_mask & BUTTON_MASK_RIGHT:
				objects.rotate(camera_basis.z.normalized(), motion.x)
		else:
			if event.button_mask & BUTTON_MASK_LEFT:
				camera_stand.rotate(camera_basis.x.normalized(), -motion.y)
				camera_stand.rotate(camera_basis.y.normalized(), -motion.x)
			elif event.button_mask & BUTTON_MASK_RIGHT:
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
	var mesh_normal_mapper = load("res://material_maker/panels/preview_3d/map_renderer.tscn").instance()
	add_child(mesh_normal_mapper)
	var id = objects.get_child_count()-1
	var object : MeshInstance = objects.get_child(id)
	var result = mesh_normal_mapper.gen(object.mesh, map, file_name, size)
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
