tool
extends HBoxContainer

func _ready() -> void:
	$Type.clear()
	for t in $Types.get_children():
		$Type.add_item(t.name)
	_on_Type_item_selected($Type.selected)

func set_model_data(data) -> void:
	if data.has("name"):
		$Name.text = data.name
	if data.has("label"):
		$Label.text = data.label
	if !data.has("type"):
		return
	var type = $Types.get_node(data.type)
	type.set_model_data(data)
	var selected = type.get_index()
	$Type.selected = selected
	_on_Type_item_selected(selected)

func get_model_data() -> Dictionary:
	var data = $Types.get_node($Type.get_item_text($Type.selected)).get_model_data()
	data.name=$Name.text
	data.label=$Label.text
	data.type=$Type.get_item_text($Type.selected)
	return data

func _on_Delete_pressed() -> void:
	queue_free()

func _on_Type_item_selected(ID) -> void:
	for t in $Types.get_children():
		t.visible = false
	var t = $Types.get_child(ID)
	if t != null:
		t.visible = true
	else:
		print(ID)

