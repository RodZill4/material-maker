extends Window


signal close(apply)


func ask() -> Dictionary:
	title = "Custom size"
	popup_centered()
	_on_WindowDialog_minimum_size_changed()
	var rv : Dictionary
	if await self.close:
		rv = { size = Vector2($MarginContainer/VBoxContainer/GridContainer/Width.value, $MarginContainer/VBoxContainer/GridContainer/Height.value) }
	queue_free()
	return rv

func _on_OK_pressed():
	emit_signal("close", true)

func _on_Cancel_pressed():
	emit_signal("close", false)

func _on_WindowDialog_popup_hide():
	emit_signal("close", false)


func _on_WindowDialog_minimum_size_changed():
	size = $MarginContainer.get_combined_minimum_size()
