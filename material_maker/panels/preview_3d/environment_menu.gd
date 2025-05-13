extends PanelContainer

const SETTING_PREVIEW_CLEAR_BG := "3D_preview_panel_clear_background"

const TONEMAPS : Array = ["Linear", "Reinhard", "Filmic", "ACES", "AgX"]

@onready var preview3D := owner

@onready var ToneMap := %ToneMap
@onready var ClearBackground := %ClearBackground
@onready var EnvironmentList := %EnvironmentList


func _ready() -> void:
	ToneMap.clear()
	for i in TONEMAPS.size():
		ToneMap.add_item(TONEMAPS[i], i)

	if mm_globals.has_config(SETTING_PREVIEW_CLEAR_BG):
		ClearBackground.button_pressed = mm_globals.get_config(SETTING_PREVIEW_CLEAR_BG)



func _open() -> void:
	update_environment_selector()

	var tonemap_mode: int = mm_globals.get_config("ui_3d_preview_tonemap")
	ToneMap.select(tonemap_mode)
	
	if mm_globals.has_config("ui_3d_preview_tonemap_exposure"):
		$VBoxContainer/VBox/Exposure.set_value(mm_globals.get_config("ui_3d_preview_tonemap_exposure"))
	
	if mm_globals.has_config("ui_3d_preview_tonemap_white"):
		$VBoxContainer/VBox/White.set_value(mm_globals.get_config("ui_3d_preview_tonemap_white"))
	
	$VBoxContainer/VBox/White.visible = tonemap_mode > 0 && tonemap_mode <= 3
	$VBoxContainer/VBox/WhiteLabel.visible = tonemap_mode > 0 && tonemap_mode <= 3
	
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

	EnvironmentList.fixed_icon_size.x = EnvironmentList.size.x/4.0 - 7
	EnvironmentList.fixed_icon_size.y = EnvironmentList.fixed_icon_size.x
	EnvironmentList.get_parent().custom_minimum_size.y = EnvironmentList.size.x/4.0
	size = Vector2()


func _on_environment_editor_button_pressed() -> void:
	var main_window = get_node("/root/MainWindow")
	if main_window:
		var env_editor: Node = main_window.environment_editor()
		env_editor.tree_exited.connect(update_environment_selector)



func _on_environment_list_item_selected(index: int) -> void:
	preview3D.set_environment(index)



func _on_tone_map_item_selected(index: int) -> void:
	preview3D.set_tonemap(index)
	$VBoxContainer/VBox/White.visible = index > 0 && index <= 3
	$VBoxContainer/VBox/WhiteLabel.visible = index > 0 && index <= 3

func _on_clear_background_toggled(toggled_on: bool) -> void:
	preview3D.clear_background = toggled_on
	mm_globals.set_config(SETTING_PREVIEW_CLEAR_BG, toggled_on)
	if preview3D.is_node_ready():
		preview3D.set_environment(-1)


func _on_minimum_size_changed() -> void:
	size = get_combined_minimum_size()
