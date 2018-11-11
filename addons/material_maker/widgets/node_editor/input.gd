tool
extends HBoxContainer

func _ready():
	pass

func set_model_data(data):
	$Name.text = data.name
	$Label.text = data.label
	if data.type == "rgb":
		$Type.selected = 1
	elif data.type == "rgba":
		$Type.selected = 2
	else:
		$Type.selected = 0
	$Default.text = data.default

func get_model_data():
	var data = { name=$Name.text, label=$Label.text, default=$Default.text }
	if $Type.selected == 1:
		data.type = "rgb"
	elif $Type.selected == 2:
		data.type = "rgba"
	else:
		data.type = "f"
	return data

func _on_Delete_pressed():
	queue_free()
