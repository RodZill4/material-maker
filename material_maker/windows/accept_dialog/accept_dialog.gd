extends AcceptDialog


signal return_status(status)


func _ready() -> void:
	pass

func _on_AcceptDialog_confirmed() -> void:
	emit_signal("return_status", "ok")

func _on_AcceptDialog_custom_action(action) -> void:
	emit_signal("return_status", String(action))

func _on_AcceptDialog_popup_hide() -> void:
	await get_tree().process_frame
	emit_signal("return_status", "cancel")

func ask() -> String:
	get_window().content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	get_window().set_size(get_contents_minimum_size()*get_window().content_scale_factor)
	popup_centered()
	var result : String = await self.return_status
	queue_free()
	return result
