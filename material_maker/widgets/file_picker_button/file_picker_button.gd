extends Button
class_name FilePickerButton

var path : String = "" setget set_path
var filters : PoolStringArray = PoolStringArray()

signal on_file_selected(f)

func _ready() -> void:
	pass

func set_path(p : String) -> void:
	path = p
	text = path.get_file()

func add_filter(f : String) -> void:
	filters.append(f)

func _on_Control_pressed() -> void:
	var dialog : FileDialog = FileDialog.new()
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.current_dir = path.get_base_dir()
	for f in filters:
		dialog.add_filter(f)
	add_child(dialog)
	dialog.connect("file_selected", self, "on_file_selected")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func on_file_selected(f) -> void:
	set_path(f)
	emit_signal("on_file_selected", f)
