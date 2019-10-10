tool
extends HBoxContainer

var text setget set_text, get_text

signal label_changed(new_label)

func _ready():
	pass

func get_text():
	return $Label.text

func set_text(t):
	$Label.text = t

func _on_gui_input(ev):
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == BUTTON_LEFT:
		$Label.visible = false
		$Editor.text = $Label.text
		$Editor.visible = true
		$Editor.select()
		$Editor.grab_focus()

func _on_Editor_text_entered(__):
	_on_Editor_focus_exited()

func _on_Editor_focus_exited():
	$Label.text = $Editor.text
	$Label.visible = true
	$Editor.visible = false
	emit_signal("label_changed", $Editor.text)
