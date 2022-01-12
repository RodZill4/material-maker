extends Button
class_name FilePickerButton

var mode = FileDialog.MODE_OPEN_FILE
var path: String = "" setget set_path
var filters: PoolStringArray = PoolStringArray()

signal file_selected(f)


func _ready() -> void:
	if !is_connected("pressed", self, "_on_Control_pressed"):
		connect("pressed", self, "_on_Control_pressed")


func set_mode(m):
	mode = m


func set_path(p: String) -> void:
	path = p
	text = path.get_file()


func add_filter(f: String) -> void:
	filters.append(f)


func _on_Control_pressed() -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = mode
	dialog.current_dir = path.get_base_dir()
	for f in filters:
		dialog.add_filter(f)
	add_child(dialog)
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		set_path(files[0])
		emit_signal("file_selected", files[0])
