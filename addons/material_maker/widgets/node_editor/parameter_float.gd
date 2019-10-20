tool
extends HBoxContainer

func get_model_data() -> Dictionary:
	var data = {
		min = $Min.value,
		max = $Max.value,
		step = $Step.value,
		default = $Default.value,
	}

	if $SpinBox.pressed:
		data.widget = "spinbox"

	return data

func set_model_data(data) -> void:
	if data.has("min"):
		$Min.value = data.min
	if data.has("max"):
		$Max.value = data.max
	if data.has("step"):
		$Step.value = data.step
	if data.has("default"):
		$Default.value = data.default
	$SpinBox.pressed = ( data.has("widget") && data.widget == "spinbox" )
