tool
extends HBoxContainer

func set_model_data(data) -> void:
	$Name.text = data.name
	$Label.text = data.label
	if data.type == "rgb":
		$Type.selected = 1
	elif data.type == "rgba":
		$Type.selected = 2
	else:
		$Type.selected = 0
	$Default.text = data.default

func get_model_data() -> Dictionary:
	var data = { name=$Name.text, label=$Label.text, default=$Default.text }
	if $Type.selected == 1:
		data.type = "rgb"
	elif $Type.selected == 2:
		data.type = "rgba"
	else:
		data.type = "f"
	return data

func _on_Delete_pressed() -> void:
	queue_free()
