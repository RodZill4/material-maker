extends Popup

func show_code(text : String) -> void:
	$TextEdit.text = text
	connect("popup_hide", self, "queue_free")
	popup_centered()
