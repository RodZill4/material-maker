extends Window

signal ok

func set_value(n, v) -> void:
	$VBoxContainer/GridContainer/name.text = n
	$VBoxContainer/GridContainer/value.text = v

func _on_OK_pressed() -> void:
	emit_signal("ok", $VBoxContainer/GridContainer/name.text, $VBoxContainer/GridContainer/value.text)
	queue_free()
