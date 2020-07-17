extends ColorRect

signal clicked

func _ready() -> void:
	pass # Replace with function body.

func set_color(c) -> void:
	$ColorRect.color = c

func select(b : bool) -> void:
	color = Color(1.0, 1.0, 1.0, 1.0) if b else Color(1.0, 1.0, 1.0, 0.0)

func _on_ColorSlot_gui_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked", self)

func get_drag_data(position):
	var preview = ColorRect.new()
	preview.color = $ColorRect.color
	preview.rect_min_size = Vector2(32, 32)
	set_drag_preview(preview)
	return $ColorRect.color
