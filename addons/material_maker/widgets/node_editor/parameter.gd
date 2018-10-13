tool
extends HBoxContainer

var size_first = 0
var size_last = 12
var size_default = 8

const PARAMETER_TYPE = [ "float", "size", "enum", "boolean" ]

func _ready():
	pass

# Parameter of type SIZE

func update_size_option_button(button, first, last, current):
	button.clear()
	for i in range(first, last+1):
		var s = pow(2, i)
		button.add_item("%dx%d" % [ s, s ])
	button.selected = current - first

func update_size_configuration():
	update_size_option_button($Types/T1/First, 0, size_last, size_first)
	update_size_option_button($Types/T1/Last, size_first, 12, size_last)
	update_size_option_button($Types/T1/Default, size_first, size_last, size_default)

func _on_First_item_selected(ID):
	size_first = ID
	update_size_configuration()

func _on_Last_item_selected(ID):
	size_last = size_first + ID
	update_size_configuration()

func _on_Default_item_selected(ID):
	size_default = size_first + ID

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
		if data.has("first"):
			size_first = data.first
		if data.has("last"):
			size_last = data.last
		update_size_configuration()
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
	elif $Type.selected == 1:
		data.first =  size_first
		data.last =  size_last
		data.default =  size_default
	return data

func _on_Delete_pressed():
	queue_free()

func _on_OptionButton_item_selected(ID):
	for c in $Types.get_children():
		c.visible = "T"+str(ID) == c.name

