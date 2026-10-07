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
var existing_connections : int = 0

var thumbnail_tasks : PackedInt32Array = []

var loading_tween : Tween

func _ready() -> void:
	for c in range(MAX_CONNECTIONS):
		$ImageHTTPRequestPool.add_child(HTTPRequest.new())

	DirAccess.open("user://").make_dir_recursive("user://website_cache")

func _on_ItemList_item_activated(index) -> void:
	if loading_tween.is_running():
		return
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
	$VBoxContainer.modulate.a = 0.5
	$VBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

func process_data(_result : int, _response_code : int,
		_headers : PackedStringArray, body : PackedByteArray,
		type : int = 0, return_index : bool = false) -> void:

	if _response_code != HTTPClient.RESPONSE_OK:
		const scene : String = "res://material_maker/windows/accept_dialog/accept_dialog.tscn"
		var dialog : AcceptDialog = load(scene).instantiate()
		dialog.dialog_text = "Cannot get assets from the website"
		mm_globals.main_window.add_child(dialog)
		await dialog.ask()
		queue_free()
		return

	var data : String = body.get_string_from_utf8()

	var json : JSON = JSON.new()
	if json.parse(data) == OK and json.get_data() is Array:
		only_return_index = return_index
		var parse_result : Array = json.get_data()
		assets = []
		var placeholder_tex : ImageTexture = ImageTexture.\
				create_from_image(get_placeholder_icon(type))
		for i in range(parse_result.size() - 1, -1, -1):
			var m = parse_result[i]
			m.id = int(m.id)
			m.type = int(m.type)
			if m.type & 15 == type:
				m.texture = placeholder_tex
				assets.push_back(m)
		loading_tween.kill()
		item_list.modulate.a = 1.0
		fill_list("")
		update_thumbnails()

func select_asset(type : int = 0, return_index : bool = false) -> Dictionary:
	mm_globals.main_window.add_dialog(self)
	var placeholder : ImageTexture = ImageTexture.create_from_image(
			get_placeholder_icon(type))
	for i in range(250):
		item_list.add_item("loading...", placeholder, false)

	loading_tween = get_tree().create_tween()
	loading_tween.set_trans(Tween.TRANS_QUAD).set_loops()
	loading_tween.tween_property(item_list, "modulate:a", 0.2, 0.7)
	loading_tween.tween_property(item_list, "modulate:a", 0.7, 0.7)

	content_scale_factor = mm_globals.ui_scale_factor()
	$VBoxContainer.minimum_size_changed.emit()
	hide()
	popup_centered()
	start_download_asset(type, return_index)

	return_asset.connect(queue_free.unbind(1))
	return await return_asset

func process_thumbnail(m : Dictionary, id : int) -> void:
	var cache_filename : String = "user://website_cache/thumbnail_%d.webp" % m.id
	var image : Image = Image.new()
	if ! FileAccess.file_exists(cache_filename) or image.load(cache_filename) != OK:
		missing_thumbnail_indexes.append.call_deferred(id)
		if existing_connections < MAX_CONNECTIONS:
			existing_connections += 1
			download_thumbnail.call_deferred()
	else:
		thumbnail_set.call_deferred(m, image)

func thumbnail_set(material : Dictionary, image : Image) -> void:
	material.texture = ImageTexture.create_from_image(image)
	var displayed : int = displayed_assets.find(material.id)
	if displayed != -1:
		item_list.set_item_icon(displayed, material.texture)

func update_thumbnails() -> void:
	missing_thumbnail_indexes = []
	for i in range(assets.size()):
		thumbnail_tasks.append(WorkerThreadPool.add_task(
				process_thumbnail.bind(assets[i], i)))

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
				(func(_result : int, response_code : int,
						_headers : PackedStringArray, body : PackedByteArray,
						index : int) -> void:
					if response_code != HTTPClient.RESPONSE_OK:
						return
					existing_connections -= 1
					var material : Dictionary = assets[index]
					var save_path : String = "user://website_cache/thumbnail_%d.webp" % material.id
					var image : Image = Image.new()
					image.load_webp_from_buffer(body)
					image.save_webp(save_path)
					thumbnail_set(material, image)
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

func start_download_asset(type : int = 0, return_index : bool = false) -> void:
	var error : Error = $HTTPRequest.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterials")
	if error == OK:
		$HTTPRequest.request_completed.connect(process_data.bind(type, return_index))

func _exit_tree() -> void:
	for t in thumbnail_tasks:
		WorkerThreadPool.wait_for_task_completion(t)
