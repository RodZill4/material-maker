extends Control

@export var closed : bool = true: set = set_closed
var value = null: set = set_value


signal updated(pixels, old_value)


func _ready():
	set_value(MMPixels.new())

func set_closed(c : bool = true):
	closed = c
	$PixelsView.set_closed(c)

func set_value(v) -> void:
	value = v.duplicate()
	$PixelsView.pixels = value
	$PixelsView.queue_redraw()

func _on_PixelsEdit_pressed():
	var dialog = preload("res://material_maker/widgets/pixels_edit/pixels_dialog.tscn").instantiate()
	dialog.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	dialog.min_size = Vector2(500, 500) * dialog.content_scale_factor
	mm_globals.main_window.add_dialog(dialog)
	dialog.pixels_changed.connect(self.on_value_changed)
	var new_pixels = await dialog.edit_pixels(value)
	if new_pixels != null:
		set_value(new_pixels.value)
		emit_signal("updated", new_pixels.value.duplicate(), null if new_pixels.value.compare(new_pixels.previous_value) else new_pixels.previous_value)

func on_value_changed(v) -> void:
	set_value(v)
	emit_signal("updated", v.duplicate(), null)

func _get_drag_data(_position):
	return value.duplicate()

func _can_drop_data(_position, data) -> bool:
	return data is MMPixels

func _drop_data(_position, data) -> void:
	var old_pixels : MMPixels = value
	value = data
	emit_signal("updated", value, old_pixels)
