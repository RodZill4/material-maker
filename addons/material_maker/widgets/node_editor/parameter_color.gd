tool
extends HBoxContainer

func _ready():
	pass

func get_model_data():
	var data = {}
	var default = $Default.color
	data.default = { r=default.r, g=default.g, b=default.b, a=default.a}
	return data

func set_model_data(data):
	if data.has("default"):
		$Default.color = Color(data.default.r, data.default.g, data.default.b, data.default.a)
