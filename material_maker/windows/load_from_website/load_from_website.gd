extends WindowDialog

var materials = []

signal return_material(json)

func _ready() -> void:
	pass

func _on_ItemList_item_activated(index) -> void:
	var m = materials[index]
	var error = $HTTPRequest.request("https://www.materialmaker.org/api/getMaterial?id="+str(m.id))
	if error != OK:
		return
	var data = yield($HTTPRequest, "request_completed")[3].get_string_from_utf8()
	var parse_result : JSONParseResult = JSON.parse(data)
	if parse_result == null or ! parse_result.result is Dictionary:
		return
	emit_signal("return_material", parse_result.result.json)

func _on_LoadFromWebsite_popup_hide() -> void:
	emit_signal("return_material", "")

func _on_OK_pressed() -> void:
	if $VBoxContainer/ItemList.get_selected_items().empty():
		emit_signal("return_material", "")
		return
	_on_ItemList_item_activated($VBoxContainer/ItemList.get_selected_items()[0])

func _on_Cancel_pressed() -> void:
	emit_signal("return_material", "")

func select_material() -> String:
	var error = $HTTPRequest.request("https://www.materialmaker.org/api/getMaterials")
	if error != OK:
		queue_free()
		return ""
	popup_centered()
	var data = yield($HTTPRequest, "request_completed")[3].get_string_from_utf8()
	var parse_result : JSONParseResult = JSON.parse(data)
	if parse_result == null or ! parse_result.result is Array:
		queue_free()
		return ""
	materials = parse_result.result
	materials.invert()
	for i in range(materials.size()):
		var m = materials[i]
		$VBoxContainer/ItemList.add_item(m.name)
	update_thumbnails()
	var result = yield(self, "return_material")
	queue_free()
	return result

func update_thumbnails() -> void:
	for i in range(materials.size()):
		var m = materials[i]
		var error = $ImageHTTPRequest.request("https://www.materialmaker.org/data/materials/material_"+str(m.id)+".webp")
		if error == OK:
			var data : PoolByteArray = yield($ImageHTTPRequest, "request_completed")[3]
			var image : Image = Image.new()
			image.load_webp_from_buffer(data)
			var texture : ImageTexture = ImageTexture.new()
			texture.create_from_image(image)
			$VBoxContainer/ItemList.set_item_icon(i, texture)

func _on_ItemList_item_selected(index):
	$VBoxContainer/Buttons/OK.disabled = false

func _on_ItemList_nothing_selected():
	$VBoxContainer/Buttons/OK.disabled = true
