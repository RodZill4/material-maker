extends WindowDialog

signal ok

func _ready() -> void:
	popup()

func set_title(title) -> void:
	window_title = title

func set_text(text) -> void:
	$VBoxContainer/TextEdit.text = text

func _on_OK_pressed() -> void:
	emit_signal("ok", $VBoxContainer/TextEdit.text)
	queue_free()
