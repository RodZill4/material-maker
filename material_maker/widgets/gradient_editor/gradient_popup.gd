extends Popup

signal updated(value)

func init(value) -> void:
	$Panel/Control.set_value(value)

func _on_Control_updated(value, cc : bool = true) -> void:
	emit_signal("updated", value, cc)

func _on_GradientPopup_popup_hide() -> void:
	queue_free()
