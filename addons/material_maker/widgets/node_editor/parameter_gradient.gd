tool
extends HBoxContainer

onready var default = $Default

func _ready():
	pass

func get_model_data():
	var data = {}
	data.default = default.value.serialize()
	return data

func set_model_data(data):
	if data.has("default"):
		var v = MMGradient.new()
		v.deserialize(data.default)
		default.value = v
