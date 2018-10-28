tool
extends HBoxContainer

func _ready():
	pass

func get_model_data():
	var data = {}
	data.default = $Default.pressed
	return data

func set_model_data(data):
	if data.has("default"):
		$Default.pressed = data.default