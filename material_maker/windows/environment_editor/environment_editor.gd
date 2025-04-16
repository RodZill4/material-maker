extends Window

@onready var environment_manager = get_node("/root/MainWindow/EnvironmentManager")

@onready var environment_list : ItemList = $Main/HSplitContainer/Environments
@onready var camera : Camera3D = $Main/HSplitContainer/SubViewportContainer/SubViewport/Camera3D
@onready var camera_controller = $Main/HSplitContainer/SubViewportContainer/SubViewport/CameraTargetPosition
@onready var environment : Environment = camera.environment
@onready var sun : DirectionalLight3D = $Main/HSplitContainer/SubViewportContainer/SubViewport/Sun
@onready var ui : GridContainer = $Main/HSplitContainer/UI

var share_button

var new_environment_icon = preload("res://material_maker/windows/environment_editor/new_environment.png")

var current_environment = -1

func _ready():
	popup_centered()
	_on_ViewportContainer_resized()
	connect_controls()
	environment_manager.environment_updated.connect(self.on_environment_updated)
	environment_manager.name_updated.connect(self.on_name_updated)
	environment_manager.thumbnail_updated.connect(self.on_thumbnail_updated)
	read_environment_list()
	share_button = mm_globals.main_window.get_share_button()
	# todo  $Main/Buttons/Share.disabled = ! share_button.can_share()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func connect_controls() -> void:
	for c in ui.get_children():
		if c is FloatEdit:
			c.value_changed.connect(set_environment_value.bind(c.name))
		elif c is LineEdit:
			c.text_submitted.connect(set_environment_value.bind(c.name))
		elif c is ColorPickerButton:
			c.color_changed.connect(set_environment_value.bind(c.name))
		elif c is CheckBox:
			c.toggled.connect(set_environment_value.bind(c.name))

func set_environment_value(value, variable):
	environment_manager.set_value(current_environment, variable, value)

func on_environment_updated(index):
	if index == current_environment:
		environment_manager.apply_environment(current_environment, environment, sun)

func on_name_updated(index, text):
	environment_list.set_item_text(index, text)

func on_thumbnail_updated(index, texture):
	environment_list.set_item_icon(index, null)
	environment_list.set_item_icon(index, texture)

func read_environment_list(select : int = 0):
	environment_list.clear()
	for e in environment_manager.get_environment_list():
		environment_list.add_item(e.name)
		if e.has("thumbnail"):
			environment_list.set_item_icon(environment_list.get_item_count()-1, e.thumbnail)
	environment_list.add_item("New...")
	environment_list.set_item_icon(environment_list.get_item_count()-1, new_environment_icon)
	if environment_list.get_item_count() > 1:
		if select < 0:
			select += environment_list.get_item_count()-1
		environment_list.select(select)
		set_current_environment(select)

func _on_ViewportContainer_resized():
	$Main/HSplitContainer/SubViewportContainer/SubViewport.size = $Main/HSplitContainer/SubViewportContainer.size

func _on_name_text_entered(new_text : String):
	environment_list.set_item_text(current_environment, new_text)

func _on_ViewportContainer_gui_input(event : InputEvent):
	if camera_controller.process_event(event, get_viewport()):
		$Main.accept_event()
	elif event is InputEventMouseButton:
		if event.is_command_or_control_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.fov += 1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.fov -= 1
			else:
				return
			$Main.accept_event()

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
			control.button_pressed = env[k]
	environment_manager.apply_environment(index, environment, sun)
	var read_only : bool = environment_manager.is_read_only(index)
	for c in ui.get_children():
		if c is LineEdit:
			c.editable = !read_only
		elif c is FloatEdit:
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
	if ! (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_RIGHT:
		return
	var context_menu : PopupMenu = $Main/HSplitContainer/Environments/ContextMenu
	var index = environment_list.get_item_at_position(event.position)
	if environment_list.is_selected(index) and ! environment_manager.is_read_only(index):
		mm_globals.popup_menu(context_menu, $Main/HSplitContainer/Environments)

func _on_ContextMenu_id_pressed(id):
	var index = environment_list.get_selected_items()[0]
	environment_manager.delete_environment(index)
	environment_list.remove_item(index)
	environment_list.select(index-1)
	_on_Environments_item_selected(index-1)

func _on_Download_pressed():
	var dialog = load("res://material_maker/windows/load_from_website/load_from_website.tscn").instantiate()
	var result : Dictionary = await dialog.select_asset(2)
	if result != {}:
		var new_environment = result
		new_environment.erase("thumbnail")
		environment_manager.add_environment(new_environment)
		read_environment_list(-1)

func _on_Share_pressed():
	var image = await environment_manager.create_preview(current_environment, 512)
	var preview_texture : ImageTexture = ImageTexture.new()
	preview_texture.set_image(image)
	var env = environment_manager.get_environment(current_environment).duplicate()
	env.erase("thumbnail")
	share_button.send_asset("environment", env, preview_texture)

func _on_Main_minimum_size_changed():
	size = $Main.size+Vector2(4, 4)
