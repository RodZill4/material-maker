tool
extends HBoxContainer

var control = null

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _on_Link_pressed():
	control.pick_linked()

func _on_Remove_pressed():
	control.delete()
