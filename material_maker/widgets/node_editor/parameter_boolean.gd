tool
extends HBoxContainer

func get_model_data() -> Dictionary:
	return {
		default = $Default.pressed,
	}

func set_model_data(data) -> void:
	if data.has("default"):
		$Default.pressed = data.default
