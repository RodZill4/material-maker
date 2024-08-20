extends PanelContainer

var pixel_editor: Control = null


func _open() -> void:
	$Grid/Width.value = float(pixel_editor.pixels.size.x)
	$Grid/Height.value = float(pixel_editor.pixels.size.y)
	$Grid/BPP.value = float(pixel_editor.pixels.bpp)


func _on_width_value_changed(value: Variant) -> void:
	update_from_values()


func _on_height_value_changed(value: Variant) -> void:
	update_from_values()


func _on_bpp_value_changed(value: Variant) -> void:
	update_from_values()


func update_from_values() -> void:
	pixel_editor.pixels.set_size(int($Grid/Width.value), int($Grid/Height.value), int($Grid/BPP.value))
	pixel_editor.queue_redraw()
	pixel_editor.update_color_buttons()
	pixel_editor.value_changed.emit(pixel_editor.pixels)
