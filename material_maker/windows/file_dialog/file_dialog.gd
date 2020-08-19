extends FileDialog

signal return_paths(path_list)

func _ready() -> void:
	pass

func _on_FileDialog_file_selected(path) -> void:
	emit_signal("return_paths", [ path ])

func _on_FileDialog_files_selected(paths) -> void:
	emit_signal("return_paths", paths)

func _on_FileDialog_dir_selected(dir) -> void:
	emit_signal("return_paths", [ dir ])

func _on_FileDialog_popup_hide() -> void:
	emit_signal("return_paths", [ ])

func select_files() -> Array:
	popup_centered()
	var result = yield(self, "return_paths")
	queue_free()
	return result
