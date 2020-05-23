extends HBoxContainer

func _ready():
	$Type.clear()
	for tn in mm_io_types.type_names:
		var t = mm_io_types.types[tn]
		$Type.add_item(t.label)

func update_up_down_button() -> void:
	var parent = get_parent()
	if not parent:
		return
	$Up.disabled = (get_index() == 0)
	$Down.disabled = (get_index() == get_parent().get_child_count()-2)

func set_model_data(data) -> void:
	$Name.text = data.name
	$Label.text = data.label
	$Type.selected = mm_io_types.type_names.find(data.type)
	$Default.text = data.default
	$Function.pressed = data.has("function") and data.function

func get_model_data() -> Dictionary:
	var data = { name=$Name.text, label=$Label.text, default=$Default.text }
	data.type = mm_io_types.type_names[$Type.selected]
	if $Function.pressed:
		data.function = true
	return data

func _on_Delete_pressed() -> void:
	var p = get_parent()
	p.remove_child(self)
	p.update_up_down_buttons()
	queue_free()

func _on_Up_pressed() -> void:
	get_parent().move_child(self, get_index() - 1)
	get_parent().update_up_down_buttons()

func _on_Down_pressed() -> void:
	get_parent().move_child(self, get_index() + 1)
	get_parent().update_up_down_buttons()
