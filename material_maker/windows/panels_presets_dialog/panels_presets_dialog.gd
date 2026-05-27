extends Window

var layout_presets : Array[Dictionary]
var selected_item : int = -1

func _ready() -> void:
	content_scale_factor = get_tree().root.content_scale_factor
	size = $MarginContainer.get_combined_minimum_size() * content_scale_factor
	min_size = size

func edit_presets(presets : Array[Dictionary]) -> void:
	layout_presets = presets
	_ready()
	hide()
	popup_centered()
	update_item_list()
	await %Buttons/Close.pressed
	queue_free()

func update_item_list() -> void:
	%ItemList.clear()
	if not layout_presets.is_empty():
		for preset in layout_presets:
			var idx : int = %ItemList.add_item(preset.name)
			%ItemList.set_item_tooltip_enabled(idx, false)
	else:
		enable_buttons(false)
	if selected_item != -1 and selected_item < %ItemList.item_count:
		%ItemList.select(selected_item)

func enable_buttons(enable : bool) -> void:
	for btn in %Buttons.get_children():
		if btn.name != "Close":
			btn.disabled = not enable

func _on_item_list_item_selected(index : int) -> void:
	selected_item = index

func _on_rename_pressed() -> void:
	if selected_item == -1:
		return
	var renamed_item : String = %ItemList.get_item_text(selected_item)
	var dialog : Window = preload(
					"res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
	add_child(dialog)

	var status : Dictionary = await dialog.enter_text("Rename Preset",
			"Enter a new name for this preset", renamed_item)
	var renamed_item_id : int = -1
	var preset_data : Dictionary
	if status.ok and not status.text.strip_edges().is_empty():
		for preset in layout_presets.size():
			if layout_presets[preset].name == renamed_item:
				renamed_item_id = preset
				preset_data = layout_presets[preset].duplicate()
				break
	else:
		return

	var new_preset_name : String = status.text.strip_edges()
	for item_index in %ItemList.item_count:
		if %ItemList.get_item_text(item_index) == new_preset_name:
			if renamed_item_id != item_index:
				mm_globals.main_window.accept_dialog(
						"Preset \"%s\" already exists." % [new_preset_name])
				return
	layout_presets.remove_at(renamed_item_id)
	preset_data.name = status.text.strip_edges()
	layout_presets.insert(renamed_item_id, preset_data)
	update_item_list()

func _on_remove_pressed() -> void:
	if selected_item == -1:
		return
	for preset in layout_presets.size():
		if layout_presets[preset].name == %ItemList.get_item_text(selected_item):
			layout_presets.remove_at(preset)
			break
	if layout_presets.is_empty():
		enable_buttons(false)
	update_item_list()

func _on_apply_pressed() -> void:
	if selected_item == -1:
		return
	var layout : HBoxContainer = mm_globals.main_window.layout
	layout.get_node("FlexibleLayout").init(layout_presets[selected_item].preset)
