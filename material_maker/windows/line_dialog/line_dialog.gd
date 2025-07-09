extends Window


signal return_string(status)


func set_value(v) -> void:
	$VBoxContainer/LineEdit.text = v

func _on_OK_pressed() -> void:
	_on_LineEdit_text_entered($VBoxContainer/LineEdit.text)

func _on_LineEdit_text_entered(new_text) -> void:
	emit_signal("return_string", { ok=true, text=new_text })
	queue_free()

func _on_Cancel_pressed():
	emit_signal("return_string", { ok=false })
	queue_free()

func enter_text(window_title : String, label : String, value : String) -> Dictionary:
	title = window_title
	$VBoxContainer/Label.text = label
	$VBoxContainer/LineEdit.grab_focus()
	$VBoxContainer/LineEdit.grab_click_focus()
	set_value(value)
	$VBoxContainer/LineEdit.grab_focus()
	$VBoxContainer/LineEdit.grab_click_focus()
	hide()
	_on_VBoxContainer_minimum_size_changed()
	popup_centered()
	var result = await self.return_string
	queue_free()
	return result

func _on_VBoxContainer_minimum_size_changed():
	size = ($VBoxContainer.get_minimum_size() + Vector2(20, 4))*content_scale_factor

func _context_menu_about_to_popup(context_menu : PopupMenu) -> void:
	context_menu.position =  get_window().position + Vector2i(
			get_mouse_position() * content_scale_factor)

func _on_ready() -> void:
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	var line_edit_context : PopupMenu = $VBoxContainer/LineEdit.get_menu()
	line_edit_context.about_to_popup.connect(
			_context_menu_about_to_popup.bind(line_edit_context))
