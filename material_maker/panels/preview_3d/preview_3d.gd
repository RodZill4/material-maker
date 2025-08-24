extends SubViewportContainer

const CAMERA_DISTANCE_MIN = 0.5
const CAMERA_DISTANCE_MAX = 150.0
const CAMERA_FOV_MIN = 10
const CAMERA_FOV_MAX = 90


@onready var objects_pivot = $MaterialPreview/Preview3d/ObjectsPivot
@onready var objects = $MaterialPreview/Preview3d/ObjectsPivot/Objects
@onready var current_object = objects.get_child(0)

@onready var camera_controller = $MaterialPreview/Preview3d/CameraController
@onready var camera = $MaterialPreview/Preview3d/Camera3D
@onready var sun = $MaterialPreview/Preview3d/Sun

var trigger_on_right_click = true

var moving = false

var _mouse_start_position : Vector2 = Vector2.ZERO

var clear_background := true
var current_environment := 0

@onready var main_menu := $MainMenu


signal need_update(me)


func _enter_tree():
	mm_deps.create_buffer("preview_"+str(get_instance_id()), self)


func _exit_tree():
	mm_deps.delete_buffer("preview_"+str(get_instance_id()))


func _ready() -> void:
	# Delay setting the sun shadow by one frame. Otherwise, the large 3D preview
	# attempts to read the setting before the configuration file is loaded.
	await get_tree().process_frame
	sun.shadow_enabled = mm_globals.get_config("ui_3d_preview_sun_shadow")


func reattach_menu(node:Node) -> Node:
	main_menu.get_parent().remove_child(main_menu)
	node.add_child(main_menu)
	return main_menu


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_THEME_CHANGED:
		set_environment(current_environment)


func set_model(id : int, custom_model_path : String = "") -> bool:
	if id == objects.get_child_count()-1:
		if custom_model_path == "":
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
				custom_model_path = files[0]
			else:
				return false
		do_load_custom_mesh(custom_model_path)
	select_object(id)
	return true


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

func get_current_model_path() -> String:
	if current_object.mesh.has_meta("file_path"):
		return current_object.mesh.get_meta("file_path")
	return ""

func select_object(id) -> void:
	current_object.visible = false
	current_object = objects.get_child(id)
	if current_object.has_method("update_mesh"):
		current_object.update_mesh()
	current_object.visible = true
	emit_signal("need_update", [ self ])
	var aabb : AABB = current_object.get_aabb()
	current_object.transform.origin = -(aabb.position+0.5*aabb.size)

func _on_Environment_item_selected(id) -> void:
	set_environment(id)

func set_environment(id:int) -> void:
	if id >= 0:
		current_environment = id
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	var environment = $MaterialPreview/Preview3d/WorldEnvironment.environment
	if clear_background:
		$MaterialPreview.transparent_bg = true
		environment_manager.apply_environment(current_environment, environment, sun, Color.TRANSPARENT, true)
	else:
		$MaterialPreview.transparent_bg = false
		environment_manager.apply_environment(current_environment, environment, sun)

	environment.tonemap_mode = mm_globals.get_config("ui_3d_preview_tonemap")
	environment.tonemap_exposure = mm_globals.get_config("ui_3d_preview_tonemap_exposure")
	environment.tonemap_white = mm_globals.get_config("ui_3d_preview_tonemap_white")


func set_tonemap(id) -> void:
	mm_globals.set_config("ui_3d_preview_tonemap", id)
	var environment = $MaterialPreview/Preview3d/WorldEnvironment.environment
	environment.tonemap_mode = id


func configure_model() -> void:
	var popup = preload("res://material_maker/panels/preview_3d/mesh_config_popup.tscn").instantiate()
	popup.hide()
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
	# Update 3D scale
	$MaterialPreview.scaling_3d_scale = mm_globals.main_window.preview_rendering_scale_factor
	# Return materials
	if current_object != null and current_object.get_material() != null:
		return [ current_object.get_material() ]
	return []


func get_preview_settings() -> Dictionary:
	var settings : Dictionary = {}
	settings.object_mesh = current_object.mesh
	settings.object_material = current_object.get_active_material(0)
	settings.object_transform = current_object.global_transform
	settings.camera_transform = camera.global_transform
	settings.camera_fov = camera.fov
	settings.camera_near = camera.near
	settings.camera_far = camera.far
	return settings


func on_dep_update_value(_buffer_name, parameter_name, value) -> bool:
	var preview_material = current_object.get_material()
	preview_material.set_shader_parameter(parameter_name, value)
	return false


func zoom(amount : float):
	camera.position.z = clamp(camera.position.z*amount, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)


func on_gui_input(event : InputEvent) -> void:
	if camera_controller.process_event(event, get_viewport()):
		accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			# Don't stop rotating the preview on mouse wheel usage (zoom change).
			pass
			#$MaterialPreview/Preview3d/ObjectRotate.stop(false)
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.is_command_or_control_pressed():
					camera.fov = clamp(camera.fov + 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
				else:
					zoom(1.0 / (1.01 if event.shift_pressed else 1.1))
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.is_command_or_control_pressed():
					camera.fov = clamp(camera.fov - 1, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
				else:
					zoom(1.01 if event.shift_pressed else 1.1)
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				var mask : int = Input.get_mouse_button_mask()
				var lpressed : bool = (mask & MOUSE_BUTTON_MASK_LEFT) != 0
				var rpressed : bool = (mask & MOUSE_BUTTON_MASK_RIGHT) != 0

				if event.pressed and lpressed != rpressed: # xor
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					_mouse_start_position = event.global_position
					moving = true
				elif not lpressed and not rpressed:
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # allow and hide cursor warp
					get_viewport().warp_mouse(_mouse_start_position)
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					moving = false
				if event.button_index == MOUSE_BUTTON_RIGHT:
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
			var objects_rotation : int = -1 if Input.is_key_pressed(KEY_CTRL) else 1 if Input.is_key_pressed(KEY_SHIFT) else 0
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				objects_pivot.rotate(camera_basis.x.normalized(), objects_rotation * motion.y)
				objects_pivot.rotate(camera_basis.y.normalized(), objects_rotation * motion.x)
			elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
				objects_pivot.rotate(camera_basis.z.normalized(), objects_rotation * motion.x)

func on_right_click():
	pass


func do_generate_map(file_name : String, map : String, image_size : int) -> void:
	var id = objects.get_child_count()-1
	var object : MeshInstance3D = objects.get_child(id)
	var t : MMTexture = await MMMapGenerator.get_map(object.mesh, map, image_size)
	t.save_to_file(file_name)
	DisplayServer.clipboard_set("{\"name\":\"image\",\"parameters\":{\"image\":\"%s\"},\"type\":\"image\"}" % file_name)


func _on_exposure_value_changed(value: Variant) -> void:
	var environment = $MaterialPreview/Preview3d/WorldEnvironment.environment
	environment.tonemap_exposure = value
	mm_globals.set_config("ui_3d_preview_tonemap_exposure", value)


func _on_white_value_changed(value: Variant) -> void:
	var environment = $MaterialPreview/Preview3d/WorldEnvironment.environment
	environment.tonemap_white = value
	mm_globals.set_config("ui_3d_preview_tonemap_white", value)
