extends HBoxContainer

@onready var default = $Default

func get_model_data() -> Dictionary:
	return {
		default = default.value.serialize(),
	}

func set_model_data(data) -> void:
	if data.has("default"):
		var v = MMPixels.new()
		v.deserialize(data.default)
		default.value = v
