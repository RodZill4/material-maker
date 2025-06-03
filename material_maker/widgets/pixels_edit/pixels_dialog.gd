extends Window


var previous_value


signal pixels_changed(pixels)
signal return_pixels(pixels)


func _ready():
	min_size = $VBoxContainer.get_combined_minimum_size()

func _on_CurveDialog_popup_hide():
	emit_signal("return_pixels", previous_value)

func _on_OK_pressed():
	emit_signal("return_pixels", $VBoxContainer/EditorContainer/PixelsEditor.pixels)

func _on_Cancel_pressed():
	emit_signal("return_pixels", previous_value)

func edit_pixels(pixels : MMPixels) -> Dictionary:
	previous_value = pixels.duplicate()
	$VBoxContainer/EditorContainer/PixelsEditor.set_pixels(pixels)
	hide()
	popup_centered()
	var result = await self.return_pixels
	queue_free()
	return { value=result, previous_value=previous_value }

func _on_PixelsEditor_value_changed(value):
	emit_signal("pixels_changed", value)
