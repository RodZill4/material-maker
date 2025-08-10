extends PanelContainer

const SETTING_PREVIEW_CLEAR_BG := "3D_preview_panel_clear_background"

@onready var preview3D := owner

@onready var ClearBackground := %ClearBackground
@onready var EnvironmentList := %EnvironmentList


func _ready() -> void:
	if mm_globals.has_config(SETTING_PREVIEW_CLEAR_BG):
		ClearBackground.button_pressed = mm_globals.get_config(SETTING_PREVIEW_CLEAR_BG)


func _open() -> void:
	update_environment_selector()


func update_environment_selector() -> void:
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	if not environment_manager:
		return

	EnvironmentList.clear()

	var idx := 0
	for env in environment_manager.get_environment_list():
		EnvironmentList.add_icon_item(env.thumbnail)
		EnvironmentList.set_item_tooltip(idx, env.name)
		idx += 1

	size = Vector2()


func _on_environment_editor_button_pressed() -> void:
	var main_window = get_node("/root/MainWindow")
	if main_window:
		var env_editor: Node = main_window.environment_editor()
		env_editor.tree_exited.connect(update_environment_selector)


func _on_environment_list_item_selected(index: int) -> void:
	preview3D.set_environment(index)


func _on_clear_background_toggled(toggled_on: bool) -> void:
	preview3D.clear_background = toggled_on
	mm_globals.set_config(SETTING_PREVIEW_CLEAR_BG, toggled_on)
	if preview3D.is_node_ready():
		preview3D.set_environment(-1)


func _on_minimum_size_changed() -> void:
	size = get_combined_minimum_size()
