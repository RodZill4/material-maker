extends ViewportContainer

export var ui_path : String = "UI/Preview3DUI"

onready var objects_pivot = $MaterialPreview/Preview3d/ObjectsPivot
onready var objects = $MaterialPreview/Preview3d/ObjectsPivot/Objects
onready var current_object = objects.get_child(0)

onready var camera_stand = $MaterialPreview/Preview3d/CameraPivot
onready var camera = $MaterialPreview/Preview3d/CameraPivot/Camera
onready var sun = $MaterialPreview/Preview3d/Sun

var ui
var navigation_style: NavigationStyle3D
var initial_camera_stand_transform: Transform

signal need_update(me)

const MENU = [
	{ menu="Model/Select", submenu="model_list" },
	{ menu="Model/Configure", command="configure_model" },
	{ menu="Model/Rotate/Off", command="set_rotate_model_speed", command_parameter=0 },
	{ menu="Model/Rotate/Slow", command="set_rotate_model_speed", command_parameter=0.01 },
	{ menu="Model/Rotate/Medium", command="set_rotate_model_speed", command_parameter=0.05 },
	{ menu="Model/Rotate/Fast", command="set_rotate_model_speed", command_parameter=0.1 },
	{ menu="Model/Generate map/Mesh normal", submenu="generate_mesh_normal_map" },
	{ menu="Model/Generate map/Inverse UV", submenu="generate_inverse_uv_map" },
	{ menu="Model/Generate map/Curvature", submenu="generate_curvature_map" },
	{ menu="Model/Generate map/Ambient Occlusion", submenu="generate_ao_map" },
	{ menu="Model/Generate map/Thickness", submenu="generate_thickness_map" },
	{ menu="Environment/Select", submenu="environment_list" },
	{ menu="Environment/Navigation Styles", submenu="navigation_styles_list" },
]

const NAVIGATION_STYLES: Dictionary = {
	"Default": DefaultNavigationStyle3D,
	"Turntable": TurntableNavigationStyle3D,
}


func _ready() -> void:
	ui = get_node(ui_path)
	mm_globals.menu_manager.create_menus(MENU, self, ui)
	$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	_on_Environment_item_selected(0)

	# Required for supersampling to work.
	$MaterialPreview.get_texture().flags = Texture.FLAG_FILTER

	$MaterialPreview.connect("size_changed", self, "_on_material_preview_size_changed")

	navigation_style = NAVIGATION_STYLES["Default"].new(self)
	initial_camera_stand_transform = camera_stand.get_global_transform()

	# Delay setting the sun shadow by one frame. Otherwise, the large 3D preview
	# attempts to read the setting before the configuration file is loaded.
	yield(get_tree(), "idle_frame")
	sun.shadow_enabled = mm_globals.get_config("ui_3d_preview_sun_shadow")

func _process(delta: float) -> void:
	navigation_style.handle_process(delta)

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


func create_menu_navigation_styles_list(menu : PopupMenu) -> void:
	menu.clear()
	var labels = NAVIGATION_STYLES.keys()
	for i in labels.size():
		menu.add_item(labels[i], i)
	if !menu.is_connected("id_pressed", self, "_on_NavigationStyles_item_selected"):
		menu.connect("id_pressed", self, "_on_NavigationStyles_item_selected")

func _on_Model_item_selected(id) -> void:
	if id == objects.get_child_count()-1:
		var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
		add_child(dialog)
		dialog.rect_min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.mode = FileDialog.MODE_OPEN_FILE
		dialog.add_filter("*.obj;OBJ model File")
		if mm_globals.config.has_section_key("path", "mesh"):
			dialog.current_dir = mm_globals.config.get_value("path", "mesh")
		var files = dialog.select_files()
		while files is GDScriptFunctionState:
			files = yield(files, "completed")
		if files.size() == 1:
			do_load_custom_mesh(files[0])
	else:
		select_object(id)

func do_load_custom_mesh(file_path) -> void:
	mm_globals.config.set_value("path", "mesh", file_path.get_base_dir())
	var id = objects.get_child_count()-1
	var mesh = $ObjLoader.load_obj_file(file_path)
	if mesh != null:
		var object : MeshInstance = objects.get_child(id)
		object.mesh = mesh
		select_object(id)

func select_object(id) -> void:
	current_object.visible = false
	current_object = objects.get_child(id)
	current_object.visible = true
	emit_signal("need_update", [ self ])
	var aabb : AABB = current_object.get_aabb()
	current_object.transform.origin = -(aabb.position+0.5*aabb.size)

func _on_Environment_item_selected(id) -> void:
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	var environment = $MaterialPreview/Preview3d/CameraPivot/Camera.environment
	environment_manager.apply_environment(id, environment, sun)

func _on_NavigationStyles_item_selected(id) -> void:
	camera_stand.set_global_transform(initial_camera_stand_transform)
	navigation_style = NAVIGATION_STYLES.values()[id].new(self)

func _on_material_preview_size_changed() -> void:
	# Apply supersampling to the new viewport size.
	$MaterialPreview.size = rect_size * mm_globals.main_window.preview_rendering_scale_factor

func configure_model() -> void:
	var popup = preload("res://material_maker/panels/preview_3d/mesh_config_popup.tscn").instance()
	add_child(popup)
	popup.configure_mesh(current_object)

func set_rotate_model_speed(speed: float) -> void:
	var object_rotate = $MaterialPreview/Preview3d/ObjectRotate
	object_rotate.playback_speed = speed
	if speed == 0:
		object_rotate.stop(false)
	else:
		object_rotate.play("rotate")

func get_materials() -> Array:
	if current_object != null and current_object.get_surface_material(0) != null:
		return [ current_object.get_surface_material(0) ]
	return []

func on_float_parameters_changed(parameter_changes : Dictionary) -> bool:
	var return_value : bool = false
	var preview_material = current_object.get_surface_material(0)
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list(preview_material.shader.get_rid()):
			if p.name == n:
				return_value = true
				preview_material.set_shader_param(n, parameter_changes[n])
				break
	return return_value

func on_gui_input(event) -> void:
	navigation_style.handle_input(event)

func on_right_click():
	pass

func generate_map(generate_function : String, size : int) -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image File")
	dialog.add_filter("*.exr;EXR image File")
	if mm_globals.config.has_section_key("path", "maps"):
		dialog.current_dir = get_node("/MainWindow").mm_globals.config.get_value("path", "maps")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		call(generate_function, files[0], size)

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
