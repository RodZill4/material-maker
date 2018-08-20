tool
extends WindowDialog

signal ok

func _ready():
	pass

func _on_OK_pressed():
	emit_signal("ok", $VBoxContainer/LineEdit.text)
	queue_free()
