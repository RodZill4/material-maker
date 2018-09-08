tool
extends WindowDialog

signal ok

func _ready():
	pass

func set_texts(title, label):
	window_title = title
	$VBoxContainer/Label.text = label
	$VBoxContainer/LineEdit.grab_focus()
	$VBoxContainer/LineEdit.grab_click_focus()

func _on_OK_pressed():
	_on_LineEdit_text_entered($VBoxContainer/LineEdit.text)

func _on_LineEdit_text_entered(new_text):
	emit_signal("ok", new_text)
	queue_free()
