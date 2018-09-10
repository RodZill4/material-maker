tool
extends HBoxContainer

var control = null

func _on_Link_pressed():
	control.pick_linked()

func _on_Remove_pressed():
	control.delete()
