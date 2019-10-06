extends Popup

signal updated(value)

func init(value):
	$Panel/Control.set_value(value)



func _on_Control_updated(value):
	emit_signal("updated", value)


func _on_GradientPopup_popup_hide():
	queue_free()
