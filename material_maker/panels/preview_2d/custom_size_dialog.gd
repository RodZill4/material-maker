extends WindowDialog


signal close(apply)


func ask() -> Dictionary:
	window_title = "Custom size"
	_on_WindowDialog_minimum_size_changed()
	popup_centered()
	var rv : Dictionary
	if yield(self, "close"):
		rv = { size = Vector2($VBoxContainer/GridContainer/Width.value, $VBoxContainer/GridContainer/Height.value) }
	queue_free()
	return rv

func _on_OK_pressed():
	emit_signal("close", true)

func _on_Cancel_pressed():
	emit_signal("close", false)

func _on_WindowDialog_popup_hide():
	emit_signal("close", false)


func _on_WindowDialog_minimum_size_changed():
	rect_size = $VBoxContainer.rect_size+Vector2(4, 4)
