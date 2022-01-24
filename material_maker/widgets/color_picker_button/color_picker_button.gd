extends ColorPickerButton


var previous_color : Color


signal color_changed_undo(c, previous)


func _ready():
	connect("color_changed", self, "on_color_changed")
	connect("picker_created", self, "on_picker_created")
	connect("popup_closed", self, "on_popup_closed")

func set_color(c):
	print(c)
	.set_color(c)

func get_drag_data(_position):
	var preview = ColorRect.new()
	preview.color = color
	preview.rect_min_size = Vector2(32, 32)
	set_drag_preview(preview)
	return color

func can_drop_data(_position, data) -> bool:
	return typeof(data) == TYPE_COLOR

func drop_data(_position, data) -> void:
	var old_color : Color = color
	color = data
	emit_signal("color_changed", color)
	emit_signal("color_changed_undo", color, old_color)

func on_color_changed(c):
	emit_signal("color_changed_undo", c, null)

func on_picker_created():
	get_popup().connect("about_to_show", self, "on_about_to_show")
	previous_color = color

func on_about_to_show():
	previous_color = color

func on_popup_closed():
	emit_signal("color_changed_undo", color, previous_color)
