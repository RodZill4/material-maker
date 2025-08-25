extends PanelContainer


const SETTING_GENERATE_MAP_EXPORT_PATH := "3D_generate_map_export_path"
const SETTING_GENERATE_MAP_LAST_TYPE := "3D_generage_map_type"
const SETTING_GENERATE_MAP_RESOLUTION := "3D_generate_map_resolution"

@onready var preview3D := owner

@onready var MapExportFile := %MapExportFile
@onready var MapType := %MapType
@onready var MapFileType := %MapFileType
@onready var MapExportFileResultLabel := %MapExportFileResultLabel
@onready var MapResolution := %MapResolution

func _ready() -> void:
	pass


func _open() -> void:
	if mm_globals.has_config(SETTING_GENERATE_MAP_EXPORT_PATH):
		MapExportFile.text = mm_globals.get_config(SETTING_GENERATE_MAP_EXPORT_PATH)
	update_generate_map_file_label()

	if mm_globals.has_config(SETTING_GENERATE_MAP_LAST_TYPE):
		MapType.select(mm_globals.get_config(SETTING_GENERATE_MAP_LAST_TYPE))

	if mm_globals.has_config(SETTING_GENERATE_MAP_RESOLUTION):
		MapResolution.select(mm_globals.get_config(SETTING_GENERATE_MAP_RESOLUTION))


func _on_map_type_item_selected(index: int) -> void:
	mm_globals.set_config(SETTING_GENERATE_MAP_LAST_TYPE, index)
	update_generate_map_file_label()


func _on_generate_map_button_pressed() -> void:
	var file_name: String = MapExportFileResultLabel.text

	var extension := ""
	match MapFileType.selected:
		0: extension += ".png"
		1: extension += ".exr"

	var dialog := preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.png; PNG image File")
	dialog.add_filter("*.exr; EXR image File")
	if mm_globals.config.has_section_key("path", "maps"):
		dialog.current_dir = get_node("/MainWindow").mm_globals.config.get_value("path", "maps")

	dialog.current_file = file_name+extension

	var files = await dialog.select_files()
	if files.size() != 1:
		return

	var resolution: int = 256 << MapResolution.selected

	match MapType.selected:
		0: preview3D.do_generate_map(files[0], "position", resolution)
		1: preview3D.do_generate_map(files[0], "normal", resolution)
		2: preview3D.do_generate_map(files[0], "curvature", resolution)
		3: preview3D.do_generate_map(files[0], "ambient_occlusion", resolution)
		4: preview3D.do_generate_map(files[0], "thickness", resolution)


func _on_map_export_file_text_changed(new_text: String) -> void:
	mm_globals.set_config(SETTING_GENERATE_MAP_EXPORT_PATH, new_text)
	update_generate_map_file_label()


func _on_map_resolution_item_selected(index: int) -> void:
	mm_globals.set_config(SETTING_GENERATE_MAP_RESOLUTION, index)


func update_generate_map_file_label() -> void:
	var file_result := interpret_map_file_name(MapExportFile.text)
	MapExportFileResultLabel.text = file_result
	MapExportFileResultLabel.tooltip_text = file_result
	MapExportFileResultLabel.visible = not MapExportFile.text.is_empty() and MapExportFile.text.count("$") != file_result.count("$")
	size = Vector2()


func interpret_map_file_name(file_name: String, path:="") -> String:
	var additional_ids := {"$type": MapType.get_item_text(MapType.selected).to_snake_case()}

	var extension := ""
	match MapFileType.selected:
		0: extension += ".png"
		1: extension += ".exr"

	return mm_globals.interpret_file_name(file_name, path, extension, additional_ids)


func _on_map_file_type_item_selected(_index: int) -> void:
	update_generate_map_file_label()
