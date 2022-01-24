extends WindowDialog

signal return_string(status)

func set_value(v) -> void:
	$VBoxContainer/LineEdit.text = v

func popup_centered(size : Vector2 = Vector2(0, 0)) -> void:
	.popup_centered(size)
	$VBoxContainer/LineEdit.grab_focus()

func _on_OK_pressed() -> void:
	_on_LineEdit_text_entered($VBoxContainer/LineEdit.text)

func _on_LineEdit_text_entered(new_text) -> void:
	emit_signal("return_string", { ok=true, text=new_text })
	queue_free()

func _on_Cancel_pressed():
	emit_signal("return_string", { ok=false })
	queue_free()

func enter_text(title : String, label : String, value : String) -> Dictionary:
	window_title = title
	$VBoxContainer/Label.text = label
	$VBoxContainer/LineEdit.grab_focus()
	$VBoxContainer/LineEdit.grab_click_focus()
	set_value(value)
	$VBoxContainer/LineEdit.grab_focus()
	$VBoxContainer/LineEdit.grab_click_focus()
	popup_centered()
	var result = yield(self, "return_string")
	queue_free()
	return result

func _on_VBoxContainer_minimum_size_changed():
	rect_size = $VBoxContainer.rect_size+Vector2(4, 4)
