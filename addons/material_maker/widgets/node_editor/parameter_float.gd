tool
extends HBoxContainer

func _ready():
	pass

func get_model_data():
	var data = {}
	data.min = $Min.value
	data.max = $Max.value
	data.step = $Step.value
	data.default = $Default.value
	if $SpinBox.pressed:
		data.widget = "spinbox"
	return data

func set_model_data(data):
	if data.has("min"):
		$Min.value = data.min
	if data.has("max"):
		$Max.value = data.max
	if data.has("step"):
		$Step.value = data.step
	if data.has("default"):
		$Default.value = data.default
	$SpinBox.pressed = ( data.has("widget") && data.widget == "spinbox" )
