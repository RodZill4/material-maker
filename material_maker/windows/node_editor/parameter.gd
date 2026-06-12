extends HBoxContainer

func _ready() -> void:
	$Type.clear()
	for t in $Types.get_children():
		$Type.add_item(t.name)
	for child in $Types/color.get_children():
		if child is ColorPickerButton:
			var picker_popup = child.get_popup()
			picker_popup.content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
			picker_popup.min_size = picker_popup.get_contents_minimum_size() * picker_popup.content_scale_factor
	_on_Type_item_selected($Type.selected)

func update_up_down_button() -> void:
	var parent = get_parent()
	if parent == null:
		return
	$Up.disabled = (get_index() == 0)
	$Down.disabled = (get_index() == get_parent().get_child_count()-2)

func set_model_data(data) -> void:
	if data.has("name"):
		$Name.text = data.name
	if data.has("label"):
		$Label.text = data.label
	if !data.has("type"):
		return
	$Description.short_description = data.shortdesc if data.has("shortdesc") else ""
	$Description.long_description = data.longdesc if data.has("longdesc") else ""
	$Description.update_tooltip()
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
	if $Description.short_description != "":
		data.shortdesc = $Description.short_description
	if $Description.long_description != "":
		data.longdesc = $Description.long_description
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

func _on_Type_item_selected(ID) -> void:
	for t in $Types.get_children():
		t.visible = false
	var t = $Types.get_child(ID)
	if t != null:
		t.visible = true
	else:
		print(ID)

func get_parameter_hbox() -> HBoxContainer:
	return $Types.get_child($Type.selected)
