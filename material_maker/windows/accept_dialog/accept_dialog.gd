extends AcceptDialog

signal return_status(status)


func _ready() -> void:
	pass


func _on_AcceptDialog_confirmed() -> void:
	emit_signal("return_status", "ok")


func _on_AcceptDialog_custom_action(action) -> void:
	emit_signal("return_status", action)


func _on_AcceptDialog_popup_hide() -> void:
	yield(get_tree(), "idle_frame")
	emit_signal("return_status", "cancel")


func ask() -> String:
	popup_centered()
	var result = yield(self, "return_status")
	queue_free()
	return result
