extends SubViewportContainer

@export var ui_path : NodePath = "UI/Preview3DUI"

@onready var objects_pivot = $MaterialPreview/Preview3d/ObjectsPivot
@onready var objects = $MaterialPreview/Preview3d/ObjectsPivot/Objects
@onready var current_object = objects.get_child(0)

@onready var camera_stand = $MaterialPreview/Preview3d/CameraPivot
@onready var camera = $MaterialPreview/Preview3d/CameraPivot/Camera3D
@onready var sun = $MaterialPreview/Preview3d/Sun

var ui
var navigation_style: NavigationStyle3D
var initial_camera_stand_transform: Transform3D

signal need_update(me)

const MENU : Array[Dictionary] = [
	{ menu="Model/Select", submenu="model_list" },
	{ menu="Model/Configure", command="configure_model" },
	{ menu="Model/Rotate/Off", command="set_rotate_model_speed", command_parameter=0 },
	{ menu="Model/Rotate/Slow", command="set_rotate_model_speed", command_parameter=0.01 },
	{ menu="Model/Rotate/Medium", command="set_rotate_model_speed", command_parameter=0.05 },
	{ menu="Model/Rotate/Fast", command="set_rotate_model_speed", command_parameter=0.1 },
	{ menu="Model/Generate map/Position", submenu="generate_position_map" },
	{ menu="Model/Generate map/Normal", submenu="generate_normal_map" },
	{ menu="Model/Generate map/Curvature", submenu="generate_curvature_map" },
	{ menu="Model/Generate map/Ambient Occlusion", submenu="generate_ao_map" },
	{ menu="Model/Generate map/Bent Normals", submenu="generate_bent_normals_map" },
	{ menu="Model/Generate map/Thickness", submenu="generate_thickness_map" },
	{ menu="Environment/Select", submenu="environment_list" },
	{ menu="Environment/Tonemap", submenu="tonemap_list" },
	{ menu="Environment/Navigation", submenu="navigation_styles_list" },
]

var NAVIGATION_STYLES: Dictionary = {
	"Classic": ClassicNavigationStyle3D,
	"Turntable": TurntableNavigationStyle3D,
}


func _enter_tree():
	mm_deps.create_buffer("preview_"+str(get_instance_id()), self)

func _exit_tree():
	mm_deps.delete_buffer("preview_"+str(get_instance_id()))

func _ready() -> void:
	ui = get_node(ui_path)
	update_menu()
	$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	_on_Environment_item_selected(0)
	
	var config_navigation_style = NAVIGATION_STYLES.keys()[mm_globals.get_config("ui_3d_preview_navigation_style")]
	navigation_style = NAVIGATION_STYLES[config_navigation_style].new(self)
	initial_camera_stand_transform = camera_stand.get_global_transform()
	
	# Required for supersampling to work.
	# $MaterialPreview.get_texture().flags = Texture2D.FLAG_FILTER
	# $MaterialPreview.connect("size_changed",Callable(self,"_on_material_preview_size_changed"))
	# Delay setting the sun shadow by one frame. Otherwise, the large 3D preview
	# attempts to read the setting before the configuration file is loaded.
	await get_tree().process_frame
	sun.shadow_enabled = mm_globals.get_config("ui_3d_preview_sun_shadow")

func _process(delta: float) -> void:
	navigation_style.handle_process(delta)

func update_menu():
	mm_globals.menu_manager.create_menus(MENU, self, mm_globals.menu_manager.MenuBarGodot.new(ui))

func create_menu_model_list(menu : MMMenuManager.MenuBase) -> void:
	menu.clear()
	for i in objects.get_child_count():
		var o = objects.get_child(i)
		var thumbnail := load("res://material_maker/panels/preview_3d/thumbnails/meshes/%s.png" % o.name)
		if thumbnail:
			menu.add_icon_item(thumbnail, "", i)
		else:
			menu.add_item(o.name, i)
	menu.connect_id_pressed(self._on_Model_item_selected)

func create_menu_environment_list(menu : MMMenuManager.MenuBase) -> void:
	get_node("/root/MainWindow/EnvironmentManager").create_environment_menu(menu)
	menu.connect_id_pressed(self._on_Environment_item_selected)

const TONEMAPS : Array = [ "Linear", "Reinhard", "Filmic", "ACES" ]

func create_menu_tonemap_list(menu : MMMenuManager.MenuBase) -> void:
	var tonemap_mode : int = mm_globals.get_config("ui_3d_preview_tonemap")
	menu.clear()
	for i in TONEMAPS.size():
		menu.add_radio_check_item(TONEMAPS[i], i)
		if i == tonemap_mode:
			menu.set_item_checked(i, true)
	menu.connect_id_pressed(self._on_Tonemaps_item_selected)

func create_menu_navigation_styles_list(menu : MMMenuManager.MenuBase) -> void:
	var config_navigation_style : int = mm_globals.get_config("ui_3d_preview_navigation_style")
	var labels = NAVIGATION_STYLES.keys()
	menu.clear()
	for i in labels.size():
		menu.add_radio_check_item(labels[i], i)
		if i == config_navigation_style:
			menu.set_item_checked(i, true)
	menu.connect_id_pressed(self._on_NavigationStyles_item_selected)

func _on_Model_item_selected(id) -> void:
	if id == objects.get_child_count()-1:
		var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
		dialog.min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		for f in MMMeshLoader.get_file_dialog_filters():
			dialog.add_filter(f)
		if mm_globals.config.has_section_key("path", "mesh"):
			dialog.current_dir = mm_globals.config.get_value("path", "mesh")
		var files = await dialog.select_files()
		if files.size() == 1:
			do_load_custom_mesh(files[0])
	else:
		select_object(id)

func do_load_custom_mesh(file_path) -> void:
	mm_globals.config.set_value("path", "mesh", file_path.get_base_dir())
	var id = objects.get_child_count()-1
	var mesh : Mesh = null
	mesh = MMMeshLoader.load_mesh(file_path)
	if mesh != null:
		var object : MeshInstance3D = objects.get_child(id)
		object.mesh = mesh
		mm_globals.main_window.set_current_mesh(mesh)
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
	var environment = $MaterialPreview/Preview3d/WorldEnvironment.environment
	environment_manager.apply_environment(id, environment, sun)
	environment.tonemap_mode = mm_globals.get_config("ui_3d_preview_tonemap")

func _on_Tonemaps_item_selected(id) -> void:
	mm_globals.set_config("ui_3d_preview_tonemap", id)
	var environment = $MaterialPreview/Preview3d/WorldEnvironment.environment
	environment.tonemap_mode = id
	update_menu.call_deferred()

func _on_NavigationStyles_item_selected(id) -> void:
	mm_globals.set_config("ui_3d_preview_navigation_style", id)
	camera_stand.set_global_transform(initial_camera_stand_transform)
	navigation_style = NAVIGATION_STYLES.values()[id].new(self)
	update_menu.call_deferred()

func _on_material_preview_size_changed() -> void:
	pass
	# Apply supersampling to the new viewport size.
	#$MaterialPreview.size = size * mm_globals.main_window.preview_rendering_scale_factor

func configure_model() -> void:
	var popup = preload("res://material_maker/panels/preview_3d/mesh_config_popup.tscn").instantiate()
	add_child(popup)
	popup.configure_mesh(current_object)

func set_rotate_model_speed(speed: float) -> void:
	var object_rotate = $MaterialPreview/Preview3d/ObjectRotate
	object_rotate.speed_scale = speed
	if speed == 0:
		object_rotate.stop(false)
	else:
		object_rotate.play("rotate")

func get_materials() -> Array:
	if current_object != null and current_object.get_surface_override_material(0) != null:
		return [ current_object.get_surface_override_material(0) ]
	return []

func on_dep_update_value(_buffer_name, parameter_name, value) -> bool:
	var preview_material = current_object.get_surface_override_material(0)
	preview_material.set_shader_parameter(parameter_name, value)
	return false

func on_gui_input(event) -> void:
	navigation_style.handle_input(event)

func on_right_click():
	pass

func generate_map(generate_function : String, image_size : int) -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image File")
	dialog.add_filter("*.exr;EXR image File")
	if mm_globals.config.has_section_key("path", "maps"):
		dialog.current_dir = get_node("/MainWindow").mm_globals.config.get_value("path", "maps")
	var files = await dialog.select_files()
	if files.size() == 1:
		call(generate_function, files[0], image_size)

func do_generate_map(file_name : String, map : String, image_size : int) -> void:
	var id = objects.get_child_count()-1
	var object : MeshInstance3D = objects.get_child(id)
	var t : MMTexture = MMTexture.new()
	await MMMapGenerator.generate(object.mesh, map, image_size, t)
	t.save_to_file(file_name)
	DisplayServer.clipboard_set("{\"name\":\"image\",\"parameters\":{\"image\":\"%s\"},\"type\":\"image\"}" % file_name)

func create_menu_map(menu : MMMenuManager.MenuBase, function : String) -> void:
	menu.clear()
	for i in range(5):
		menu.add_item(str(256 << i)+"x"+str(256 << i), i)
	menu.connect_id_pressed(Callable(self, function))


func create_menu_generate_position_map(menu : MMMenuManager.MenuBase) -> void:
	create_menu_map(menu, "generate_position_map")

func generate_position_map(i : int) -> void:
	generate_map("do_generate_position_map", 256 << i)

func do_generate_position_map(file_name : String, image_size : int) -> void:
	do_generate_map(file_name, "position", image_size)


func create_menu_generate_normal_map(menu : MMMenuManager.MenuBase) -> void:
	create_menu_map(menu, "generate_normal_map")

func generate_normal_map(i : int) -> void:
	generate_map("do_generate_normal_map", 256 << i)

func do_generate_normal_map(file_name : String, image_size : int) -> void:
	do_generate_map(file_name, "normal", image_size)


func create_menu_generate_curvature_map(menu : MMMenuManager.MenuBase) -> void:
	create_menu_map(menu, "generate_curvature_map")

func generate_curvature_map(i : int) -> void:
	generate_map("do_generate_curvature_map", 256 << i)

func do_generate_curvature_map(file_name : String, image_size : int) -> void:
	do_generate_map(file_name, "curvature", image_size)


func create_menu_generate_thickness_map(menu : MMMenuManager.MenuBase) -> void:
	create_menu_map(menu, "generate_thickness_map")

func generate_thickness_map(i : int) -> void:
	generate_map("do_generate_thickness_map", 256 << i)

func do_generate_thickness_map(file_name : String, image_size : int) -> void:
	do_generate_map(file_name, "thickness", image_size)


func create_menu_generate_ao_map(menu : MMMenuManager.MenuBase) -> void:
	create_menu_map(menu, "generate_ao_map")

func generate_ao_map(i : int) -> void:
	generate_map("do_generate_ao_map", 256 << i)

func do_generate_ao_map(file_name : String, image_size : int) -> void:
	do_generate_map(file_name, "ambient_occlusion", image_size)


func create_menu_generate_bent_normals_map(menu : MMMenuManager.MenuBase) -> void:
	create_menu_map(menu, "generate_bent_normals_map")

func generate_bent_normals_map(i : int) -> void:
	generate_map("do_generate_bent_normals_map", 256 << i)

func do_generate_bent_normals_map(file_name : String, image_size : int) -> void:
	do_generate_map(file_name, "bent_normals", image_size)
