tool
extends WindowDialog

signal ok

func _ready():
	popup()

func set_title(title):
	window_title = title

func set_text(text):
	$VBoxContainer/TextEdit.text = text

func _on_OK_pressed():
	emit_signal("ok", $VBoxContainer/TextEdit.text)
	queue_free()
