extends WindowDialog

onready var environment_manager = get_node("/root/MainWindow/EnvironmentManager")

onready var environment_list : ItemList = $Main/HSplitContainer/Environments
onready var camera : Camera = $Main/HSplitContainer/ViewportContainer/Viewport/CameraPosition/CameraRotation1/CameraRotation2/Camera
onready var camera_position = $Main/HSplitContainer/ViewportContainer/Viewport/CameraPosition
onready var camera_rotation1 = $Main/HSplitContainer/ViewportContainer/Viewport/CameraPosition/CameraRotation1
onready var camera_rotation2 = $Main/HSplitContainer/ViewportContainer/Viewport/CameraPosition/CameraRotation1/CameraRotation2
onready var environment : Environment = camera.environment
onready var sun : DirectionalLight = $Main/HSplitContainer/ViewportContainer/Viewport/Sun
onready var ui : GridContainer = $Main/HSplitContainer/UI

var share_button

var new_environment_icon = preload("res://material_maker/windows/environment_editor/new_environment.png")

var current_environment = -1

func _ready():
	popup_centered()
	_on_ViewportContainer_resized()
	connect_controls()
	environment_manager.connect("environment_updated", self, "on_environment_updated")
	environment_manager.connect("name_updated", self, "on_name_updated")
	environment_manager.connect("thumbnail_updated", self, "on_thumbnail_updated")
	read_environment_list()
	share_button = get_node("/root/MainWindow").get_share_button()
	$Main/Buttons/Share.disabled = ! share_button.can_share()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func connect_controls() -> void:
	for c in ui.get_children():
		if c is LineEdit:
			if c.get_script() == preload("res://material_maker/widgets/float_edit/float_edit.gd"):
				c.connect("value_changed", self, "set_environment_value", [ c.name ])
			else:
				c.connect("text_entered", self, "set_environment_value", [ c.name ])
		elif c is ColorPickerButton:
			c.connect("color_changed", self, "set_environment_value", [ c.name ])
		elif c is CheckBox:
			c.connect("toggled", self, "set_environment_value", [ c.name ])

func set_environment_value(value, variable):
	environment_manager.set_value(current_environment, variable, value)

func on_environment_updated(index):
	if index == current_environment:
		environment_manager.apply_environment(current_environment, environment, sun)

func on_name_updated(index, text):
	environment_list.set_item_text(index, text)

func on_thumbnail_updated(index, texture):
	environment_list.set_item_icon(index, texture)

func read_environment_list():
	environment_list.clear()
	for e in environment_manager.get_environment_list():
		environment_list.add_item(e.name)
		if e.has("thumbnail"):
			environment_list.set_item_icon(environment_list.get_item_count()-1, e.thumbnail)
	environment_list.add_item("New...")
	environment_list.set_item_icon(environment_list.get_item_count()-1, new_environment_icon)
	if environment_list.get_item_count() > 1:
		environment_list.select(0)
		set_current_environment(0)

func _on_ViewportContainer_resized():
	$Main/HSplitContainer/ViewportContainer/Viewport.size = $Main/HSplitContainer/ViewportContainer.rect_size

func _on_name_text_entered(new_text : String):
	environment_list.set_item_text(current_environment, new_text)

func _on_ViewportContainer_gui_input(ev : InputEvent):
	if ev is InputEventMouseMotion:
		if ev.button_mask & BUTTON_MASK_MIDDLE != 0:
			if ev.shift:
				var factor = 0.0025*camera.translation.z
				camera_position.translate(-factor*ev.relative.x*camera.global_transform.basis.x)
				camera_position.translate(factor*ev.relative.y*camera.global_transform.basis.y)
			else:
				camera_rotation2.rotate_x(-0.01*ev.relative.y)
				camera_rotation1.rotate_y(-0.01*ev.relative.x)
	elif ev is InputEventMouseButton:
		if ev.control:
			if ev.button_index == BUTTON_WHEEL_UP:
				camera.fov += 1
			elif ev.button_index == BUTTON_WHEEL_DOWN:
				camera.fov -= 1
			else:
				return
			accept_event()
		else:
			var zoom = 0.0
			if ev.button_index == BUTTON_WHEEL_UP:
				zoom -= 1.0
			elif ev.button_index == BUTTON_WHEEL_DOWN:
				zoom += 1.0
			if zoom != 0.0:
				camera.translate(Vector3(0.0, 0.0, zoom*(1.0 if ev.shift else 0.1)))
				accept_event()

func _update_environment_variable(value, variable):
	environment.set(variable, value)

func set_current_environment(index : int) -> void:
	current_environment = index
	var env : Dictionary = environment_manager.environments[index]
	for k in env.keys():
		var control : Control = ui.get_node(k)
		if control is LineEdit:
			if control.get_script() == preload("res://material_maker/widgets/float_edit/float_edit.gd"):
				control.set_value(env[k])
			else:
				control.text = env[k]
		elif control is ColorPickerButton:
			control.color = MMType.deserialize_value(env[k])
		elif control is CheckBox:
			control.pressed = env[k]
	environment_manager.apply_environment(index, environment, sun)
	var read_only : bool = environment_manager.is_read_only(index)
	for c in ui.get_children():
		if c is LineEdit:
			c.editable = !read_only
		elif c is ColorPickerButton or c is CheckBox:
			c.disabled = read_only

func _on_Environments_item_selected(index):
	if index == environment_list.get_item_count()-1:
		environment_list.remove_item(index)
		environment_list.add_item("")
		environment_manager.new_environment(current_environment)
		environment_list.add_item("New...")
		environment_list.set_item_icon(environment_list.get_item_count()-1, new_environment_icon)
		environment_list.select(index)
	set_current_environment(index)

func _on_Environments_gui_input(event):
	if ! (event is InputEventMouseButton) or event.button_index != BUTTON_RIGHT:
		return
	var context_menu = $Main/HSplitContainer/Environments/ContextMenu
	var index = environment_list.get_item_at_position(event.position)
	if environment_list.is_selected(index) and ! environment_manager.is_read_only(index):
		context_menu.popup(Rect2(get_global_mouse_position(), context_menu.get_minimum_size()))

func _on_ContextMenu_id_pressed(id):
	var index = environment_list.get_selected_items()[0]
	environment_manager.delete_environment(index)
	environment_list.remove_item(index)
	environment_list.select(index-1)
	_on_Environments_item_selected(index-1)

func _on_Share_pressed():
	var image = environment_manager.create_preview(current_environment, 512)
	while image is GDScriptFunctionState:
		image = yield(image, "completed")
	var preview_texture : ImageTexture = ImageTexture.new()
	preview_texture.create_from_image(image)
	share_button.send_asset("environment", environment_manager.get_environment(current_environment), preview_texture)
