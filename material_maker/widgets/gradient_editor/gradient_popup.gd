@tool
extends Popup

signal updated(value)

func init(value) -> void:
	$Panel/Control.set_value(value)

func _on_Control_updated(value, cc : bool = true) -> void:
	emit_signal("updated", value, cc)

func _on_GradientPopup_popup_hide() -> void:
	queue_free()

func _on_size_changed():
	$Panel.position = Vector2i(0, 0)
	$Panel.size = size
	$Panel/Control.position = Vector2i(5, 5)
	$Panel/Control.size = size-Vector2i(10, 10)
