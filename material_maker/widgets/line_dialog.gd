extends WindowDialog

signal ok

func set_value(v) -> void:
	$VBoxContainer/LineEdit.text = v

func set_texts(title, label) -> void:
	window_title = title
	$VBoxContainer/Label.text = label
	$VBoxContainer/LineEdit.grab_focus()
	$VBoxContainer/LineEdit.grab_click_focus()

func _on_OK_pressed() -> void:
	_on_LineEdit_text_entered($VBoxContainer/LineEdit.text)

func _on_LineEdit_text_entered(new_text) -> void:
	emit_signal("ok", new_text)
	queue_free()
