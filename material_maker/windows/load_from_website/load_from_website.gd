extends Window


var assets : Array[Dictionary] = []
var displayed_assets : PackedInt32Array = []
var only_return_index : bool = false

@onready var item_list : ItemList = $VBoxContainer/ItemList

signal return_asset(json : Dictionary)

var missing_thumbnail_indexes : Array[int]

enum AssetID {
	MATERIAL,
	BRUSH,
	ENVIRONMENT,
	NODE,
}

const MAX_CONNECTIONS : int = 8

func _ready() -> void:
	for c in range(MAX_CONNECTIONS):
		$ImageHTTPRequestPool.add_child(HTTPRequest.new())

	DirAccess.open("user://").make_dir_recursive("user://website_cache")

func _on_ItemList_item_activated(index) -> void:
	if only_return_index:
		emit_signal("return_asset", { index=displayed_assets[index] })
	else:
		var error : Error = $HTTPRequest.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterial?id="+str(displayed_assets[index]))
		if error != OK:
			return
		var data : String = ( await $HTTPRequest.request_completed )[3].get_string_from_utf8()
		var json : JSON = JSON.new()
		if json.parse(data) != OK or ! json.data is Dictionary:
			return
		var parse_result : Dictionary = json.data
		if json.parse(parse_result.json) == OK and json.data is Dictionary:
			emit_signal("return_asset", json.data)
		else:
			print(parse_result.json)

func _on_LoadFromWebsite_popup_hide() -> void:
	emit_signal("return_asset", {})

func _on_OK_pressed() -> void:
	if item_list.get_selected_items().is_empty():
		emit_signal("return_asset", {})
		return
	_on_ItemList_item_activated(item_list.get_selected_items()[0])

func _on_Cancel_pressed() -> void:
	emit_signal("return_asset", {})

func fill_list(filter : String) -> void:
	item_list.clear()
	displayed_assets = []
	var item_index : int = 0
	var prioritized : Array[int] = []
	for i in range(assets.size()):
		var m = assets[i]
		if filter == "" or m.name.to_lower().find(filter.to_lower()) != -1 or m.tags.to_lower().find(filter.to_lower()) != -1:
			item_list.add_item(m.name)
			item_list.set_item_icon(item_index, m.texture)
			item_list.set_item_tooltip(item_index, "Name: %s\nAuthor: %s\nLicense: %s" % [ m.name, m.author, m.license ])
			displayed_assets.push_back(m.id)
			item_index += 1
			if i in missing_thumbnail_indexes:
				#print("Moving ", i, " to front")
				missing_thumbnail_indexes.erase(i)
				prioritized.push_back(i)
	prioritized.append_array(missing_thumbnail_indexes)
	missing_thumbnail_indexes = prioritized

func select_asset(type : int = 0, return_index : bool = false) -> Dictionary:
	# Hide the window until the asset list is loaded
	visible = false
	content_scale_factor = mm_globals.ui_scale_factor()
	mm_globals.main_window.add_dialog(self)
	var error = $HTTPRequest.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterials")
	if error == OK:
		var data = ( await $HTTPRequest.request_completed )[3].get_string_from_utf8()
		var json = JSON.new()
		if json.parse(data) == OK and json.get_data() is Array:
			only_return_index = return_index
			var parse_result : Array = json.get_data()
			visible = true
			%Filter.grab_focus()
			size = get_contents_minimum_size()
			hide()
			popup_centered()
			var tmp_assets : Array = parse_result
			tmp_assets.reverse()
			assets = []
			for i in range(tmp_assets.size()):
				var m = tmp_assets[i]
				m.id = int(m.id)
				m.type = int(m.type)
				if m.type & 15 == type:
					m.texture = ImageTexture.new()
					m.texture.set_image(get_placeholder_icon(type))
					assets.push_back(m)
			fill_list("")
			update_thumbnails()
			var result = await self.return_asset
			queue_free()
			return result
	queue_free()
	var dialog : AcceptDialog = load("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instantiate()
	dialog.dialog_text = "Cannot get assets from the website"
	mm_globals.main_window.add_child(dialog)
	dialog.ask()
	return {}

func update_thumbnails() -> void:
	missing_thumbnail_indexes = []
	for i in range(assets.size()):
		var m = assets[i]
		var cache_filename : String = "user://website_cache/thumbnail_%d.png" % m.id
		var image : Image = Image.new()
		if ! FileAccess.file_exists(cache_filename) or image.load(cache_filename) != OK:
			missing_thumbnail_indexes.append(i)
		else:
			m.texture.set_image(image)

	for connection in range(MAX_CONNECTIONS):
		download_thumbnail()

func download_thumbnail() -> void:
	if missing_thumbnail_indexes.is_empty():
		return
	var missing_index : int = missing_thumbnail_indexes.pop_front()
	var m : Dictionary = assets[missing_index]
	var address : String = MMPaths.WEBSITE_ADDRESS + "/data/materials/material_%d.webp" % m.id

	for http : HTTPRequest in $ImageHTTPRequestPool.get_children():
		if http.get_http_client_status() == HTTPClient.Status.STATUS_DISCONNECTED:
			var _error : Error = http.request(address)
			http.request_completed.connect(
				(func(_result : int, _response_code : int,
						_headers : PackedStringArray, body : PackedByteArray,
						index : int) -> void:
					var material : Dictionary = assets[index]
					var save_path : String = "user://website_cache/thumbnail_%d.png" % material.id
					var image : Image = Image.new()
					image.load_webp_from_buffer(body)
					image.save_png(save_path)
					material.texture.set_image(image)
					download_thumbnail()).bind(missing_index), CONNECT_ONE_SHOT)
			return

func _on_ItemList_item_selected(_index : int) -> void:
	$VBoxContainer/Buttons/OK.disabled = false

func _on_ItemList_nothing_selected() -> void:
	$VBoxContainer/Buttons/OK.disabled = true

func _on_VBoxContainer_minimum_size_changed() -> void:
	size = ($VBoxContainer.size+Vector2(4, 4))*content_scale_factor

func _on_Filter_changed(new_text : String) -> void:
	fill_list(new_text)

func get_placeholder_icon(type : AssetID) -> Image:
	const icons : String = "res://material_maker/windows/load_from_website/icons/%s"
	match type:
		AssetID.MATERIAL:
			return preload(icons % "material.svg").get_image()
		AssetID.BRUSH:
			return preload(icons % "brush.svg").get_image()
		AssetID.NODE:
			return preload(icons % "node.svg").get_image()
		AssetID.ENVIRONMENT:
			return preload(icons % "environment.svg").get_image()
		_:
			return Image.new()
