extends Window


var file_path = ""
var file_name = ""


signal return_info(status)


func _ready():
	$VBoxContainer/GridContainer/HBoxContainerPath/FilePickerButton.set_mode(FileDialog.FILE_MODE_OPEN_DIR)
	$VBoxContainer/GridContainer/HBoxContainerPath/FilePickerButton.icon = get_parent().get_theme_icon("folder", "MM_Icons")
	popup_centered()

func set_value(v) -> void:
	$VBoxContainer/GridContainer/LineEdit.text = v

func popup_centered_(window_size : Vector2i = Vector2i(0, 0)) -> void:
	super.popup_centered(window_size)
	$VBoxContainer/GridContainer/LineEdit.grab_focus()

func _on_LineEdit_text_entered(_new_text) -> void:
	pass

func _on_line_edit_text_changed(new_text: String) -> void:
	file_name = $VBoxContainer/GridContainer/LineEdit.text
	$VBoxContainer/HBoxContainer/OK.disabled = ((file_path == "") || (file_name == ""))

func _on_line_edit_2_text_changed(new_text: String) -> void:
	file_path = new_text
	$VBoxContainer/HBoxContainer/OK.disabled = ((file_path == "") || (file_name == ""))
	
func _on_FilePickerButton_file_selected(f):
	if file_name == "":
		$VBoxContainer/GridContainer/HBoxContainerPath/LineEdit2.text = f + "/"
	else:
		$VBoxContainer/GridContainer/HBoxContainerPath/LineEdit2.text = f + "/" + file_name.validate_filename() + ".json"
	file_path = $VBoxContainer/GridContainer/HBoxContainerPath/LineEdit2.text
	$VBoxContainer/HBoxContainer/OK.disabled = ((file_path == "") || (file_name == ""))
	

func _on_OK_pressed() -> void:
	var fp
	if file_path.ends_with(".json"):
		fp = file_path
	else:
		fp = file_path + "/" + file_name.validate_filename() + ".json"
	emit_signal("return_info", { ok=true, name=$VBoxContainer/GridContainer/LineEdit.text, path=fp })

func _on_Cancel_pressed():
	emit_signal("return_info", { ok=false })

func _on_close_requested() -> void:
	emit_signal("return_info", { ok=false })

func enter_info(value : String = "") -> Dictionary:
	set_value(value)
	$VBoxContainer/GridContainer/LineEdit.grab_focus()
	$VBoxContainer/GridContainer/LineEdit.grab_click_focus()
	popup_centered()
	var result = await self.return_info
	queue_free()
	return result

func _on_VBoxContainer_minimum_size_changed():
	size = $VBoxContainer.size+Vector2(4, 4)
