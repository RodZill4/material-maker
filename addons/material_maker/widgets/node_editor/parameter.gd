tool
extends HBoxContainer

const PARAMETER_TYPE = [ "float", "size", "enum", "boolean" ]

func _ready():
	pass

func set_model_data(data):
	if data.has("name"):
		$Name.text = data.name
	if data.has("label"):
		$Label.text = data.label
	if !data.has("type"):
		return
	for t in $Types.get_children():
		t.visible = false
	var w = null
	if data.type == "float":
		$Type.selected = 0
		w = $Types/T0
		if data.has("min"):
			$Types/T0/Min.value = data.min
		if data.has("max"):
			$Types/T0/Max.value = data.max
		if data.has("step"):
			$Types/T0/Step.value = data.step
		$Types/T0/SpinBox.pressed = ( data.has("widget") && data.widget == "spinbox" )
	elif data.type == "size":
		$Type.selected = 1
		w = $Types/T1
	elif data.type == "enum":
		$Type.selected = 2
		w = $Types/T2
	elif data.type == "boolean":
		$Type.selected = 3
		w = $Types/T3
	if w != null:
		w.visible = true

func get_model_data():
	var data = {
		name=$Name.text,
		label=$Label.text,
		type=PARAMETER_TYPE[$Type.selected],
	}
	if $Type.selected == 0:
		data.min = $Types/T0/Min.value
		data.max = $Types/T0/Max.value
		data.step = $Types/T0/Step.value
		if $Types/T0/SpinBox.pressed:
			data.widget = "spinbox"
	return data

func _on_Delete_pressed():
	queue_free()

func _on_OptionButton_item_selected(ID):
	for c in $Types.get_children():
		c.visible = "T"+str(ID) == c.name
