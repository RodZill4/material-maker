extends HBoxContainer


@onready var http_request : HTTPRequest = $HTTPRequest
var request_type : String = ""
@onready var connect_button : TextureButton = $ConnectButton

var licenses : Array = []
var my_assets : Array = []

var preview_viewport : SubViewport = null


func create_preview_viewport():
	if preview_viewport == null:
		preview_viewport = load("res://material_maker/tools/share/preview_viewport.tscn").instantiate()
		add_child(preview_viewport)

func update_my_assets():
	var request_status = await http_request.do_request("/api/getMyMaterials")
	if ! request_status.has("error"):
		var json = JSON.new()
		if json.parse(request_status.body) == OK:
			var asset_types = [ "material", "brush", "environment", "node" ]
			my_assets = json.data
			for a in my_assets:
				a.type = asset_types[int(a.type) & 15]

func set_logged_in(user_name : String) -> void:
	$ConnectButton.texture_normal = preload("res://material_maker/tools/share/golden_link.tres")
	if user_name == "":
		$ConnectButton.tooltip_text = "Logged in.\nMaterials can be submitted."
	else:
		$ConnectButton.tooltip_text = "Logged in as "+user_name+".\nMaterials can be submitted."
	$SendButton.disabled = false
	connect_button.disabled = false

func set_logged_out(message : String = "") -> void:
	$ConnectButton.texture_normal = preload("res://material_maker/tools/share/broken_link.tres")
	$ConnectButton.tooltip_text = "Click to log in and submit assets"
	$SendButton.disabled = true
	if message != "":
		await mm_globals.main_window.accept_dialog(message, false)
	connect_button.disabled = false

func _on_ConnectButton_pressed() -> void:
	connect_button.disabled = true
	var dialog = load("res://material_maker/tools/share/login_dialog.tscn").instantiate()
	var saved_login = mm_globals.get_config("website_login")
	var saved_password = mm_globals.get_config("website_password")
	var login_info = await dialog.ask(saved_login, saved_password)
	if login_info.has("user") and login_info.has("password"):
		if login_info.has("save_user"):
			if login_info.save_user:
				mm_globals.set_config("website_login", login_info.user)
			else:
				mm_globals.set_config("website_login", "")
			login_info.erase("save_user")
		if login_info.has("save_password"):
			if login_info.save_password:
				mm_globals.set_config("website_password", login_info.password)
			else:
				mm_globals.set_config("website_password", "")
			login_info.erase("save_password")
		var body : String = JSON.stringify(login_info)
		var request_status = await http_request.do_request("/login", [ "Content-Type: application/json" ], HTTPClient.METHOD_POST, body)
		if request_status.has("error"):
			set_logged_out("Failed to connect to the website")
		else:
			var re : RegEx = RegEx.new()
			re.compile("<div class=\"error\">((?:.*))</div>")
			var re_match : RegExMatch = re.search(request_status.body)
			if re_match != null:
				set_logged_out(re_match.strings[1])
				return
			request_status = await http_request.do_request("/api/isConnected", [ "Content-Type: application/json" ])
			if request_status.has("error"):
				set_logged_out("Failed to connect to the website")
				return
			var json = JSON.new()
			if json.parse(request_status.body) != OK:
				set_logged_out("Failed to connect to the website")
				return
			var status = json.data
			if !status.connected:
				set_logged_out("Failed to connect to the website")
				return
			set_logged_in(status.displayed_name)
			if licenses.is_empty():
				request_status = await http_request.do_request("/api/getLicenses")
				if ! request_status.has("error"):
					if json.parse(request_status.body) == OK:
						licenses = json.data
			if my_assets.is_empty():
				update_my_assets()
	connect_button.disabled = false

func update_preview_texture():
	create_preview_viewport()
	await mm_globals.main_window.update_preview_3d([ preview_viewport ], true)
	preview_viewport.get_materials()[0].set_shader_parameter("uv1_scale", Vector3(4, 2, 4))
	preview_viewport.get_materials()[0].set_shader_parameter("uv1_offset", Vector3(0, 0.5, 0))
	preview_viewport.get_materials()[0].set_shader_parameter("depth_offset", 0.8)
	preview_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame

func get_preview_texture():
	return preview_viewport.get_texture()

func can_share():
	return ! $SendButton.disabled

func _on_SendButton_pressed():
	var main_window = mm_globals.main_window
	var asset_type : String
	var preview_texture : Texture2D
	match main_window.get_current_project().get_project_type():
		"material":
			asset_type = "material"
			create_preview_viewport()
			await main_window.update_preview_3d([ preview_viewport ], true)
			preview_viewport.get_materials()[0].set_shader_parameter("uv1_scale", Vector3(4, 2, 4))
			preview_viewport.get_materials()[0].set_shader_parameter("uv1_offset", Vector3(0, 0.5, 0))
			preview_viewport.get_materials()[0].set_shader_parameter("depth_offset", 0.8)
			preview_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
			preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			await get_tree().process_frame
			await get_tree().process_frame
			preview_texture = preview_viewport.get_texture()
		"paint":
			asset_type = "brush"
			var status = await main_window.get_current_project().get_brush_preview()
			preview_texture = status
		_:
			return
	send_asset(asset_type, main_window.get_current_graph_edit().top_generator.serialize(), preview_texture)

func find_in_parameter_values(node : Dictionary, keywords : Array) -> bool:
	if node.has("parameters") and node.parameters is Dictionary:
		for p in node.parameters.keys():
			if node.parameters[p] is String:
				for k in keywords:
					if node.parameters[p].find(k) != -1:
						return true
	if node.has("nodes") and node.nodes is Array:
		for n in node.nodes:
			if find_in_parameter_values(n, keywords):
				return true
	return false

func send_asset(asset_type : String, asset_data : Dictionary, preview_texture : Texture2D) -> void:
	var data = { type=asset_type, preview=preview_texture, licenses=licenses, my_assets=my_assets }
	var upload_dialog = load("res://material_maker/tools/share/upload_dialog.tscn").instantiate()
	var asset_info = await upload_dialog.ask(data)
	if asset_info.is_empty():
		return
	var png_image = preview_texture.get_data().save_png_to_buffer()
	asset_info.type = asset_type
	asset_info.mm_version = ProjectSettings.get_setting("application/config/actual_release")
	asset_info.image_text = "data:image/png;base64,"+Marshalls.raw_to_base64(png_image)
	asset_info.json = JSON.stringify(asset_data)
	var url : String
	if asset_info.has("id"):
		url = "/api/updateMaterial"
		asset_info.doupdate = "on"
	else:
		url = "/api/addMaterial"
	match asset_type:
		"material":
			asset_info.type = 0
		"brush":
			var type_options : int = 0
			for n in asset_data.nodes:
				if n.name == "Brush":
					if n.has("parameters"):
						var channels : Array = [ "albedo", "metallic", "roughness", "emission", "depth" ]
						for ci in channels.size():
							var parameter_name = "has_"+channels[ci]
							if n.parameters.has(parameter_name) and n.parameters[parameter_name] is bool and n.parameters[parameter_name]:
								type_options |= 1 << ci
					break
			if find_in_parameter_values(asset_data, [ "pressure", "tilt" ]):
				type_options |= 1 << 5
			asset_info.type = 1 | (type_options << 4)
		"environment":
			asset_info.type = 2
		"node":
			asset_info.type = 3
	await http_request.do_request(url, [ "Content-Type: application/json" ], HTTPClient.METHOD_POST, JSON.stringify(asset_info))
	update_my_assets()
