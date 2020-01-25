extends Popup

func show_code(text : String) -> void:
	$TextEdit.text = text
	popup_centered()
