extends Window


@onready var asset_target : OptionButton = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Target
@onready var asset_name : LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Name
@onready var asset_license : OptionButton = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/License
@onready var asset_tags : LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/GridContainer/Tags
@onready var asset_description : TextEdit = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Description
@onready var asset_preview : TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/Preview


var my_assets : Array = []


signal return_status(status)


func _on_OKButton_pressed():
	emit_signal("return_status", "ok")

func _on_UploadDialog_popup_hide() -> void:
	emit_signal("return_status", "cancel")

func ask(data : Dictionary) -> Dictionary:
	size = $MarginContainer.get_combined_minimum_size()
	mm_globals.main_window.add_dialog(self)
	if data.type == "node":
		asset_target.visible = false
	else:
		asset_target.clear()
		my_assets = data.my_assets
		asset_target.add_item("Upload as new asset", 0)
		for a in my_assets:
			if a.type == data.type:
				asset_target.add_item("Update - %s (%d)" % [ a.name, a.id ], a.id)
	asset_preview.texture = data.preview
	asset_license.clear()
	for l in data.licenses:
		asset_license.add_item(l.name)
	validate_form()
	await get_tree().process_frame
	_on_MarginContainer_minimum_size_changed()
	popup_centered()
	var result = await self.return_status
	queue_free()
	if result == "ok":
		var rv : Dictionary = {
			name=asset_name.text,
			license=asset_license.selected,
			tags=asset_tags.text,
			description=asset_description.text
		}
		if asset_target.selected > 0:
			rv.id = asset_target.get_item_id(asset_target.selected)
		return rv
	return {}

func _on_MarginContainer_minimum_size_changed():
	size = $MarginContainer.get_minimum_size()

func validate_form():
	var valid = true
	if asset_name.text == "":
		valid = false
	$MarginContainer/VBoxContainer/Buttons/OK.disabled = !valid

func _on_Name_text_changed(_new_text):
	validate_form()

func _on_Target_item_selected(index):
	if index != 0:
		for a in my_assets:
			if a.id == asset_target.get_item_id(index):
				asset_name.text = a.name
				asset_license.selected = a.license
				asset_tags.text = a.tags
				asset_description.text = a.description
				break
	validate_form()
