extends Window

var file_path_line_edit: LineEdit
var file_path = ""
var file_name_line_edit: LineEdit
var file_name = ""


signal return_info(status)


func _ready():
	$VBoxContainer/GridContainer/HBoxContainerPath/FilePickerButton.set_mode(FileDialog.FILE_MODE_OPEN_DIR)
	$VBoxContainer/GridContainer/HBoxContainerPath/FilePickerButton.icon = get_parent().get_theme_icon("folder", "MM_Icons")
	file_name_line_edit = $VBoxContainer/GridContainer/LineEdit
	file_path_line_edit = $VBoxContainer/GridContainer/HBoxContainerPath/LineEdit2
	popup_centered()

func set_value(v) -> void:
	file_name_line_edit.text = v

func popup_centered_(window_size : Vector2i = Vector2i(0, 0)) -> void:
	super.popup_centered(window_size)
	file_name_line_edit.grab_focus()

func _on_LineEdit_text_entered(_new_text) -> void:
	pass

func validate_ok_button(fpath: String, fname: String):
	$VBoxContainer/HBoxContainer/OK.disabled = ((fpath == "") || (fname == ""))

func _on_line_edit_text_changed(new_text: String) -> void:
	file_name = new_text
	validate_ok_button(file_path, file_name)

func _on_line_edit_2_text_changed(new_text: String) -> void:
	file_path = new_text
	validate_ok_button(file_path, file_name)
	
func _on_FilePickerButton_file_selected(f):
	if file_name == "":
		file_path_line_edit.text = f + "/"
	else:
		file_path_line_edit.text = f + "/" + file_name.validate_filename() + ".json"
	file_path = file_path_line_edit.text
	validate_ok_button(file_path, file_name)

func _on_OK_pressed() -> void:
	var fp
	if file_path.ends_with(".json"):
		fp = file_path
	else:
		fp = file_path + "/" + file_name.validate_filename() + ".json"
	emit_signal("return_info", { ok=true, name=file_name, path=fp })

func _on_Cancel_pressed():
	emit_signal("return_info", { ok=false })

func _on_close_requested() -> void:
	emit_signal("return_info", { ok=false })

func enter_info(value : String = "") -> Dictionary:
	set_value(value)
	file_name_line_edit.grab_focus()
	file_name_line_edit.grab_click_focus()
	popup_centered()
	var result = await self.return_info
	queue_free()
	return result

func _on_VBoxContainer_minimum_size_changed():
	size = $VBoxContainer.size+Vector2(4, 4)
