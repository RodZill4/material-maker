extends PanelContainer

const TONEMAPS : Array = ["Linear", "Reinhard", "Filmic", "ACES"]

func _ready() -> void:
	%ToneMap.clear()
	for i in TONEMAPS.size():
		%ToneMap.add_item(TONEMAPS[i], i)

	%EnvironmentEditorButton.icon = get_theme_icon("draw", "MM_Icons")

func _open() -> void:
	update_environment_selector()

	var tonemap_mode: int = mm_globals.get_config("ui_3d_preview_tonemap")
	%ToneMap.select(tonemap_mode)


func update_environment_selector() -> void:
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	if not environment_manager:
		return
	%Environment.clear()
	for env in environment_manager.get_environment_list():
		%Environment.add_icon_item(env.thumbnail, env.name)



func _on_environment_editor_button_pressed() -> void:
	var main_window = get_node("/root/MainWindow")
	if main_window: main_window.environment_editor()


func _on_environment_item_selected(index: int) -> void:
	owner.set_environment(index)


func _on_tone_map_item_selected(index: int) -> void:
	owner.set_tonemap(index)


func _on_clear_background_toggled(toggled_on: bool) -> void:
	owner.clear_background = toggled_on
	owner.set_environment(%Environment.get_selected_id())
