tool
extends HBoxContainer

func get_model_data() -> Dictionary:
	var data = {
		min = $Min.value,
		max = $Max.value,
		step = $Step.value,
		default = $Default.value,
	}

	return data

func set_model_data(data) -> void:
	if data.has("min"):
		$Min.value = data.min
		$Default.min_value = data.min
	if data.has("max"):
		$Max.value = data.max
		$Default.max_value = data.max
	if data.has("step"):
		$Step.value = data.step
		$Default.step = data.step
	if data.has("default"):
		$Default.value = data.default


func _on_Min_value_changed(v : float) -> void:
	$Default.min_value = v

func _on_Max_value_changed(v : float) -> void:
	$Default.max_value = v

func _on_Step_value_changed(v : float) -> void:
	$Default.step = v
