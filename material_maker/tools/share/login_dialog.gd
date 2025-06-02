extends Window


signal return_status(status)


func _ready():
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	await get_tree().process_frame
	_on_MarginContainer_minimum_size_changed()

func _on_LoginButton_pressed():
	emit_signal("return_status", "ok")

func _on_LoginDialog_popup_hide() -> void:
	emit_signal("return_status", "cancel")

func ask(user : String, password : String) -> Dictionary:
	mm_globals.main_window.add_dialog(self)
	if user != "":
		$MarginContainer/VBoxContainer/UserName.text = user
		$MarginContainer/VBoxContainer/SaveUser.button_pressed = true
	if password != "":
		$MarginContainer/VBoxContainer/Password.text = password
		$MarginContainer/VBoxContainer/SavePassword.button_pressed = true
	hide()
	popup_centered()
	var result = await self.return_status
	queue_free()
	if result == "ok":
		return {
			user=$MarginContainer/VBoxContainer/UserName.text,
			save_user=$MarginContainer/VBoxContainer/SaveUser.pressed,
			password=$MarginContainer/VBoxContainer/Password.text,
			save_password=$MarginContainer/VBoxContainer/SavePassword.pressed
		}
	return {}

func _on_MarginContainer_minimum_size_changed():
	size = $MarginContainer.get_minimum_size() * content_scale_factor

func _on_RegisterButton_pressed():
	OS.shell_open(MMPaths.WEBSITE_ADDRESS+"/register")
