extends PanelContainer

var pixel_editor : PixelsView = null

@onready var width : FloatEdit = $Grid/Box/Width
@onready var height : FloatEdit = $Grid/Box/Height
@onready var bpp : FloatEdit = $Grid/BPP

func _open() -> void:
	width.value = float(pixel_editor.pixels.size.x)
	height.value = float(pixel_editor.pixels.size.y)
	bpp.value = float(pixel_editor.pixels.bpp)

func _on_width_value_changed(_value : Variant) -> void:
	update_from_values()

func _on_height_value_changed(_value : Variant) -> void:
	update_from_values()

func _on_bpp_value_changed(_value : Variant) -> void:
	update_from_values()

func update_from_values() -> void:
	bpp.value = clampf(bpp.value, 1.0, 8.0)
	pixel_editor.pixels.set_size(int(width.value), int(height.value), int(bpp.value))
	pixel_editor.queue_redraw()
	pixel_editor.update_color_buttons()
	pixel_editor.value_changed.emit(pixel_editor.pixels)
