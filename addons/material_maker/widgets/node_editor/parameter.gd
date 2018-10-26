tool
extends HBoxContainer

var size_first = 0
var size_last = 12
var size_default = 8

var enum_values = null
var enum_current = 0

const PARAMETER_TYPE = [ "float", "size", "enum", "boolean" ]

const ENUM_ADD = -1
const ENUM_EDIT = -2
const ENUM_REMOVE = -3
const ENUM_UP = -4
const ENUM_DOWN = -5


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
		data = data.duplicate()
		enum_values = data.values
		update_enum_list()
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
	elif $Type.selected == 2:
		data.values = enum_values
	return data

func _on_Delete_pressed():
	queue_free()

func _on_Type_item_selected(ID):
	for c in $Types.get_children():
		c.visible = "T"+str(ID) == c.name

func update_enum_list():
	var options = $Types/T2/EnumValues
	options.clear()
	if !enum_values.empty():
		for i in range(enum_values.size()):
			var v = enum_values[i]
			options.add_item(v.name+" ("+v.value+")", i)
		options.add_separator()
		var v = enum_values[enum_current]
		options.add_item("Edit "+v.value, ENUM_EDIT)
		options.add_item("Remove "+v.value, ENUM_REMOVE)
		if enum_current > 0:
			options.add_item("Move "+v.value+" up", ENUM_UP)
		if enum_current < enum_values.size() - 1:
			options.add_item("Move "+v.value+" down", ENUM_DOWN)
		options.add_separator()
	options.add_item("Add value", ENUM_ADD)
	options.selected = enum_current

func _on_EnumValues_item_selected(id):
	id = $Types/T2/EnumValues.get_item_id(id)
	if id >= 0 and id < enum_values.size():
		enum_current = id
	elif id == ENUM_EDIT:
		var dialog = load("res://addons/material_maker/widgets/node_editor/enum_editor.tscn").instance()
		var v = enum_values[enum_current]
		add_child(dialog)
		dialog.set_value(v.name, v.value)
		dialog.connect("ok", self, "update_enum_value", [ enum_current ])
		dialog.popup_centered()
	elif id == ENUM_ADD:
		var dialog = load("res://addons/material_maker/widgets/node_editor/enum_editor.tscn").instance()
		add_child(dialog)
		dialog.connect("ok", self, "update_enum_value", [ -1 ])
		dialog.popup_centered()
	elif id == ENUM_REMOVE:
		enum_values.remove(enum_current)
		enum_current = 0
	elif id == ENUM_UP:
		var tmp = enum_values[enum_current]
		enum_values[enum_current] = enum_values[enum_current-1]
		enum_values[enum_current-1] = tmp
		enum_current -= 1
	elif id == ENUM_DOWN:
		var tmp = enum_values[enum_current]
		enum_values[enum_current] = enum_values[enum_current+1]
		enum_values[enum_current+1] = tmp
		enum_current += 1
	update_enum_list()

func update_enum_value(n, v, i):
	if i == -1:
		enum_values.append({ name=n, value=v })
		enum_current = enum_values.size()-1
	else:
		enum_values[i] = { name=n, value=v }
		enum_current = i
	update_enum_list()
