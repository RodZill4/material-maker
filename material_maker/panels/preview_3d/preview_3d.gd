extends ViewportContainer

const CAMERA_DISTANCE_MIN = 0.5
const CAMERA_DISTANCE_MAX = 150.0
const CAMERA_FOV_MIN = 10
const CAMERA_FOV_MAX = 90

export var ui_path : String = "UI/Preview3DUI"

onready var objects_pivot = $MaterialPreview/Preview3d/ObjectsPivot
onready var objects = $MaterialPreview/Preview3d/ObjectsPivot/Objects
onready var current_object = objects.get_child(0)

onready var camera_stand = $MaterialPreview/Preview3d/CameraPivot
onready var camera = $MaterialPreview/Preview3d/CameraPivot/Camera
onready var sun = $MaterialPreview/Preview3d/Sun

var ui
var trigger_on_right_click = true

var moving = false

signal need_update(me)

const MENU = [
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
	{ menu="Model/Generate map/Thickness", submenu="generate_thickness_map" },
	{ menu="Environment/Select", submenu="environment_list" },
	{ menu="Environment/Tonemap", submenu="tonemap_list" }
]


var _mouse_start_position : Vector2 = Vector2.ZERO


func _enter_tree():
	mm_deps.create_buffer("preview_"+str(get_instance_id()), self)

func _exit_tree():
	mm_deps.delete_buffer("preview_"+str(get_instance_id()))

func _ready() -> void:
	ui = get_node(ui_path)
	mm_globals.menu_manager.create_menus(MENU, self, ui)
	$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	_on_Environment_item_selected(0)

	# Required for supersampling to work.
	$MaterialPreview.get_texture().flags = Texture.FLAG_FILTER

	$MaterialPreview.connect("size_changed", self, "_on_material_preview_size_changed")

	# Delay setting the sun shadow by one frame. Otherwise, the large 3D preview
	# attempts to read the setting before the configuration file is loaded.
	yield(get_tree(), "idle_frame")
	sun.shadow_enabled = mm_globals.get_config("ui_3d_preview_sun_shadow")

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

const TONEMAPS : Array = [ "Linear", "Reinhard", "Filmic", "ACES", "ACES Fitted" ]

func create_menu_tonemap_list(menu : PopupMenu) -> void:
	var tonemap_mode : int = mm_globals.get_config("ui_3d_preview_tonemap")
	menu.clear()
	for i in TONEMAPS.size():
		menu.add_radio_check_item(TONEMAPS[i], i)
		if i == tonemap_mode:
			menu.set_item_checked(i, true)
	if !menu.is_connected("id_pressed", self, "_on_Tonemaps_item_selected"):
		menu.connect("id_pressed", self, "_on_Tonemaps_item_selected")

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
	environment.tonemap_mode = mm_globals.get_config("ui_3d_preview_tonemap")

func _on_Tonemaps_item_selected(id) -> void:
	mm_globals.set_config("ui_3d_preview_tonemap", id)
	var environment = $MaterialPreview/Preview3d/CameraPivot/Camera.environment
	environment.tonemap_mode = id

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

func on_dep_update_value(buffer_name, parameter_name, value) -> bool:
	var preview_material = current_object.get_surface_material(0)
	preview_material.set_shader_param(parameter_name, value)
	return false

func zoom(amount : float):
	camera.translation.z = clamp(camera.translation.z*amount, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)

func on_gui_input(event) -> void:
	if event is InputEventPanGesture:
		$MaterialPreview/Preview3d/ObjectRotate.stop(false)
		var camera_basis = camera.global_transform.basis
		var rotation : Vector2 = event.delta
		camera_stand.rotate(camera_basis.x.normalized(), -rotation.y)
		camera_stand.rotate(camera_basis.y.normalized(), -rotation.x)
	elif event is InputEventMagnifyGesture:
		zoom(event.factor)
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT or event.button_index == BUTTON_MIDDLE:
			# Don't stop rotating the preview on mouse wheel usage (zoom change).
			$MaterialPreview/Preview3d/ObjectRotate.stop(false)

		match event.button_index:
			BUTTON_WHEEL_UP:
				if event.command:
					camera.fov = clamp(camera.fov + 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
				else:
					zoom(1.0 / (1.01 if event.shift else 1.1))
			BUTTON_WHEEL_DOWN:
				if event.command:
					camera.fov = clamp(camera.fov - 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
				else:
					zoom(1.01 if event.shift else 1.1)
			BUTTON_LEFT, BUTTON_RIGHT:
				var mask : int = Input.get_mouse_button_mask()
				var lpressed : bool = (mask & BUTTON_MASK_LEFT) != 0
				var rpressed : bool = (mask & BUTTON_MASK_RIGHT) != 0

				if event.pressed and lpressed != rpressed: # xor
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					_mouse_start_position = event.global_position
					moving = true
				elif not lpressed and not rpressed:
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # allow and hide cursor warp
					get_viewport().warp_mouse(_mouse_start_position)
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					moving = false
				if event.button_index == BUTTON_RIGHT:
					if event.pressed:
						trigger_on_right_click = true
					elif trigger_on_right_click:
						trigger_on_right_click = false
						on_right_click()
	elif moving and event is InputEventMouseMotion:
		trigger_on_right_click = false
		if event.pressure != 0.0:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		var motion = event.relative
		if motion.length() > 200:
			return
		if Input.is_key_pressed(KEY_ALT):
			zoom(1.0+motion.y*0.01)
		else:
			motion *= 0.01
			if abs(motion.y) > abs(motion.x):
				motion.x = 0
			else:
				motion.y = 0
			var camera_basis = camera.global_transform.basis
			var objects_rotation : int = -1 if Input.is_key_pressed(KEY_CONTROL) else 1 if Input.is_key_pressed(KEY_SHIFT) else 0
			if event.button_mask & BUTTON_MASK_LEFT:
				objects_pivot.rotate(camera_basis.x.normalized(), objects_rotation * motion.y)
				objects_pivot.rotate(camera_basis.y.normalized(), objects_rotation * motion.x)
				if objects_rotation != 1:
					camera_stand.rotate(camera_basis.x.normalized(), -motion.y)
					camera_stand.rotate(camera_basis.y.normalized(), -motion.x)
			elif event.button_mask & BUTTON_MASK_RIGHT:
				objects_pivot.rotate(camera_basis.z.normalized(), objects_rotation * motion.x)
				if objects_rotation != 1:
					camera_stand.rotate(camera_basis.z.normalized(), -motion.x)

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
	var map_renderer = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instance()
	add_child(map_renderer)
	var id = objects.get_child_count()-1
	var object : MeshInstance = objects.get_child(id)
	var result = map_renderer.gen(object.mesh, map, "save_to_file", [ file_name ], size)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	map_renderer.queue_free()
	OS.clipboard = "{\"name\":\"image\",\"parameters\":{\"image\":\"%s\"},\"type\":\"image\"}" % file_name

func create_menu_map(menu : PopupMenu, function : String) -> void:
	menu.clear()
	for i in range(5):
		menu.add_item(str(256 << i)+"x"+str(256 << i), i)
	if !menu.is_connected("id_pressed", self, function):
		menu.connect("id_pressed", self, function)

func create_menu_generate_normal_map(menu) -> void:
	create_menu_map(menu, "generate_normal_map")

func generate_normal_map(i : int) -> void:
	generate_map("do_generate_normal_map", 256 << i)

func do_generate_normal_map(file_name : String, size : int) -> void:
	do_generate_map(file_name, "normal", size)

func create_menu_generate_position_map(menu) -> void:
	create_menu_map(menu, "generate_position_map")

func generate_position_map(i : int) -> void:
	generate_map("do_generate_position_map", 256 << i)

func do_generate_position_map(file_name : String, size : int) -> void:
	do_generate_map(file_name, "position", size)

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
