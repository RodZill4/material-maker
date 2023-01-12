extends LineEdit


var previous_string : String = "6001"
signal valid_port_entered

func _ready():
	pass # Replace with function body.

func _on_PortLineEdit_text_entered(string : String) -> void:
	print("a")
	if string == previous_string:
		print("b")
		return
	if string.is_valid_integer():
		print("c")
		var int_value = int(string)
		if not 1080 < int_value and int_value < 65536:
			print("d")
			text = previous_string
			return
		emit_signal("valid_port_entered", int_value)
