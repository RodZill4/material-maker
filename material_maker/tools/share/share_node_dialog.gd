extends Window


@onready var checks : GridContainer = $MarginContainer/VBoxContainer/Checks


const GOOD_ICON : Texture2D = preload("res://material_maker/icons/ok.tres")
const BAD_ICON : Texture2D = preload("res://material_maker/icons/remove.tres")


signal return_status(status)


func _on_Share_pressed() -> void:
	emit_signal("return_status", "ok")

func _on_Share_popup_hide() -> void:
	await get_tree().process_frame
	emit_signal("return_status", "cancel")

func ask(status : Array) -> String:
	size = $MarginContainer.get_combined_minimum_size()
	mm_globals.main_window.add_dialog(self)
	for s in status:
		var icon : TextureRect = TextureRect.new()
		if s.ok:
			icon.texture = GOOD_ICON
		else:
			icon.texture = BAD_ICON
			$MarginContainer/VBoxContainer/Buttons/Share.disabled = true
		checks.add_child(icon)
		var label : Label = Label.new()
		label.text = tr(s.message)
		checks.add_child(label)
	_on_MarginContainer_minimum_size_changed()
	hide()
	popup_centered()
	var result = await self.return_status
	queue_free()
	return result

func _on_MarginContainer_minimum_size_changed():
	size = $MarginContainer.get_minimum_size()+Vector2(4, 4)
