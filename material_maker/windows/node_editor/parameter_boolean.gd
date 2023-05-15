extends HBoxContainer


func get_model_data() -> Dictionary:
	return {
		default = $Default.button_pressed,
	}

func set_model_data(data) -> void:
	if data.has("default"):
		$Default.button_pressed = data.default
