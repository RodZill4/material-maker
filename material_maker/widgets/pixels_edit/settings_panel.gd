extends PanelContainer

var pixel_editor: Control = null

@onready var width := $Grid/Box/Width
@onready var height := $Grid/Box/Height
@onready var bpp := $Grid/BPP

func _open() -> void:
	width.value = float(pixel_editor.pixels.size.x)
	height.value = float(pixel_editor.pixels.size.y)
	bpp.value = float(pixel_editor.pixels.bpp)


func _on_width_value_changed(_value: Variant) -> void:
	update_from_values()


func _on_height_value_changed(_value: Variant) -> void:
	update_from_values()


func _on_bpp_value_changed(_value: Variant) -> void:
	update_from_values()


func update_from_values() -> void:
	pixel_editor.pixels.set_size(int(width.value), int(height.value), int(bpp.value))
	pixel_editor.queue_redraw()
	pixel_editor.update_color_buttons()
	pixel_editor.value_changed.emit(pixel_editor.pixels)
