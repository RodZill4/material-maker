extends Control


@onready var projects = $Projects
@onready var preview_2d_background = $BackgroundPreviews/Preview2D
@onready var preview_2d_background_button = %"2DPreview"
@onready var preview_3d_background = $BackgroundPreviews/Preview3D
@onready var preview_3d_background_button = %"3DPreview"
@onready var preview_3d_background_panel

var current_graph_edit: GraphEdit = null:
	set(value):
		if current_graph_edit:
			current_graph_edit.item_rect_changed.disconnect(update_menu_position)
		current_graph_edit = value
		if value:
			current_graph_edit.item_rect_changed.connect(update_menu_position)

func _ready() -> void:
	preview_3d_background_panel = $BackgroundPreviews/Preview3D.reattach_menu($MenuBar/HBox)
	preview_3d_background_panel.hide()

	preview_3d_background.need_update.connect(get_node("/root/MainWindow").update_preview_3d)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		if not is_node_ready():
			await ready
		preview_2d_background_button.icon = get_theme_icon("2D_preview", "MM_Icons")
		preview_3d_background_button.icon = get_theme_icon("3D_preview", "MM_Icons")
		%ControlView.texture = get_theme_icon("3D_preview_control", "MM_Icons")

func get_projects():
	return projects

func _on_projects_panel_resized():
	var preview_position : Vector2 = Vector2(0.0, 0.0)
	var preview_size : Vector2 = size
	preview_position.y += $Projects/TabBar.size.y
	preview_size.y -= $Projects/TabBar.size.y
	$BackgroundPreviews.position = preview_position
	$BackgroundPreviews.size = preview_size
	$MenuBar.position = preview_position
	update_menu_position()


func show_background_preview_2d(button_pressed):
	preview_2d_background.visible = button_pressed
	if button_pressed:
		preview_3d_background_button.button_pressed = false


func show_background_preview_3d(button_pressed):
	preview_3d_background.visible = button_pressed
	preview_3d_background_panel.visible = button_pressed
	%ControlView.visible = button_pressed
	if button_pressed:
		preview_2d_background_button.button_pressed = false


func _on_projects_no_more_tabs():
	mm_globals.main_window.new_material()
	await get_tree().process_frame
	_on_projects_panel_resized()

func _on_projects_tab_changed(tab : int):
	mm_globals.main_window._on_Projects_tab_changed(tab)

	if mm_globals.main_window.current_mode == "paint":
		%PreviewsMenu.hide()
		preview_2d_background.hide()
		preview_3d_background.hide()
		current_graph_edit = %Projects.get_current_tab_control().get_graph_edit()
	else:
		%PreviewsMenu.show()
		preview_2d_background.visible = preview_2d_background_button.button_pressed
		preview_3d_background.visible = preview_3d_background_button.button_pressed
		current_graph_edit = %Projects.get_current_tab_control()

	await get_tree().process_frame
	_on_projects_panel_resized()



func update_menu_position() -> void:
	if not current_graph_edit:
		%MenuBar.position = Vector2()
		return
	%MenuBar.global_position = current_graph_edit.global_position
	%MenuBar.size.x = current_graph_edit.size.x
	%MenuBar.item_rect_changed.emit()
