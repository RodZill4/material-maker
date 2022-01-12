extends WindowDialog

var file_path = ""

signal return_info(status)


func _ready():
	$VBoxContainer/GridContainer/FilePickerButton.set_mode(FileDialog.MODE_SAVE_FILE)
	$VBoxContainer/GridContainer/FilePickerButton.add_filter("*.json;Material Maker library")
	popup_centered()


func set_value(v) -> void:
	$VBoxContainer/GridContainer/LineEdit.text = v


func popup_centered(size: Vector2 = Vector2(0, 0)) -> void:
	.popup_centered(size)
	$VBoxContainer/GridContainer/LineEdit.grab_focus()


func _on_LineEdit_text_entered(new_text) -> void:
	pass


func _on_FilePickerButton_file_selected(f):
	file_path = f
	$VBoxContainer/HBoxContainer/OK.disabled = (file_path == "")


func _on_OK_pressed() -> void:
	emit_signal(
		"return_info",
		{ok = true, name = $VBoxContainer/GridContainer/LineEdit.text, path = file_path}
	)


func _on_Cancel_pressed():
	emit_signal("return_info", {ok = false})


func enter_info(value: String = "") -> Dictionary:
	set_value(value)
	$VBoxContainer/GridContainer/LineEdit.grab_focus()
	$VBoxContainer/GridContainer/LineEdit.grab_click_focus()
	popup_centered()
	var result = yield(self, "return_info")
	queue_free()
	return result


func _on_VBoxContainer_minimum_size_changed():
	rect_size = $VBoxContainer.rect_size + Vector2(4, 4)
