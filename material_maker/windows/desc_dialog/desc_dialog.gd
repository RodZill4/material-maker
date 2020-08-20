extends WindowDialog

signal close(apply)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func edit_descriptions(type : String, short : String, long : String) -> Array:
	window_title = type+" Description"
	$VBoxContainer/HBoxContainer/ShortDesc.text = short
	$VBoxContainer/LongDesc.text = long
	popup_centered()
	if yield(self, "close"):
		short = $VBoxContainer/HBoxContainer/ShortDesc.text
		long = $VBoxContainer/LongDesc.text
	queue_free()
	return [ short, long ]

func _on_OK_pressed():
	emit_signal("close", true)

func _on_Cancel_pressed():
	emit_signal("close", false)

func _on_WindowDialog_popup_hide():
	emit_signal("close", false)
