extends HBoxContainer


var website_address : String = "http://localhost:3000"
var request_type : String = ""
var cookies : PoolStringArray = PoolStringArray()


var preview_viewport : Viewport = null

func create_preview_viewport():
	if preview_viewport == null:
		preview_viewport = load("res://material_maker/tools/share/preview_viewport.tscn").instance()
		add_child(preview_viewport)

func http_request(path : String, custom_headers: PoolStringArray = PoolStringArray(), ssl_validate_domain: bool = true, method = 0, request_data_raw: String = "") -> bool:
	var headers = PoolStringArray()
	headers.append_array(custom_headers)
	headers.append("Cookie: %s" % cookies.join("; "))
	var error = $HTTPRequest.request(website_address+path, headers, true, method, request_data_raw)
	return error == OK

func _on_ConnectButton_pressed() -> void:
	var dialog = load("res://material_maker/tools/share/login_dialog.tscn").instance()
	add_child(dialog)
	var saved_login = mm_globals.get_config("website_login")
	var saved_password = mm_globals.get_config("website_password")
	var login_info = dialog.ask(saved_login, saved_password)
	while login_info is GDScriptFunctionState:
		login_info = yield(login_info, "completed")
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
		var body : String = JSON.print(login_info)
		if http_request("/login", [ "Content-Type: application/json" ], true, HTTPClient.METHOD_POST, body):
			request_type = "login"
		else:
			set_logged_out()

func split_headers(headers : PoolStringArray) -> Dictionary:
	var rv : Dictionary = {}
	for h in headers:
		var s = h.split(":", true, 1)
		var n : String = s[0].to_lower()
		var v : String = s[1].strip_edges()
		if n == "set-cookie":
			for c in v.split("; "):
				var found : bool = false
				for i in range(cookies.size()):
					if c.split("=", true, 0)[0] == cookies[i].split("=", true, 0)[0]:
						cookies[i] = c
						found = true
						break
				if !found:
					cookies.append(c)
		else:
			rv[n] = v
	return rv

func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	match response_code:
		200:
			var rt : String = request_type
			request_type = ""
			match rt:
				"login":
					var re : RegEx = RegEx.new()
					re.compile("<div class=\"error\">((?:.*))</div>")
					var re_match : RegExMatch = re.search(body.get_string_from_ascii())
					if re_match != null:
						set_logged_out()
						mm_globals.main_window.accept_dialog(re_match.strings[1], false)
					else:
						set_logged_in()
						if http_request("/api/isConnected", [ "Content-Type: application/json" ]):
							request_type = "isConnected"
						else:
							set_logged_out()
				"isConnected":
					var status_parse_result : JSONParseResult = JSON.parse(body.get_string_from_ascii())
					if status_parse_result == null:
						set_logged_out()
					else:
						var status = status_parse_result.result
						if !status.connected:
							set_logged_out()
						else:
							set_logged_in(status.displayed_name)
		302:
			# Redirection
			var loc = ""
			var header_dict = split_headers(headers)
			if header_dict.has("location"):
				http_request(header_dict.location)
		_:
			print("Unexpected status: %d" % response_code)

func update_preview_texture():
	create_preview_viewport()
	var status = mm_globals.main_window.update_preview_3d([ preview_viewport ], true)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	preview_viewport.get_materials()[0].set_shader_param("uv1_scale", Vector3(4, 2, 4))
	preview_viewport.get_materials()[0].set_shader_param("uv1_offset", Vector3(0, 0.5, 0))
	preview_viewport.get_materials()[0].set_shader_param("depth_offset", 0.8)
	preview_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	preview_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	preview_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

func get_preview_texture():
	return preview_viewport.get_texture()

func can_share():
	return ! $SendButton.disabled

func _on_SendButton_pressed():
	var main_window = mm_globals.main_window
	var asset_type : String
	var preview_texture : Texture
	match main_window.get_current_project().get_project_type():
		"material":
			asset_type = "material"
			create_preview_viewport()
			var status = main_window.update_preview_3d([ preview_viewport ], true)
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			preview_viewport.get_materials()[0].set_shader_param("uv1_scale", Vector3(4, 2, 4))
			preview_viewport.get_materials()[0].set_shader_param("uv1_offset", Vector3(0, 0.5, 0))
			preview_viewport.get_materials()[0].set_shader_param("depth_offset", 0.8)
			preview_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
			preview_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
			preview_viewport.update_worlds()
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			preview_texture = preview_viewport.get_texture()
		"paint":
			asset_type = "brush"
			var status = main_window.get_current_project().get_brush_preview()
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			preview_texture = status
		_:
			return
	send_asset(asset_type, main_window.get_current_graph_edit().top_generator.serialize(), preview_texture)

func send_asset(asset_type : String, asset_data : Dictionary, preview_texture : Texture):
	var png_image = preview_texture.get_data().save_png_to_buffer()
	var png_data = Marshalls.raw_to_base64(png_image)
	var data = { type=asset_type, image=png_data, json=JSON.print(asset_data) }
	#send_data(JSON.print(data))


func set_logged_in(user_name : String = "") -> void:
	$ConnectButton.texture_normal = preload("res://material_maker/tools/share/golden_link.tres")
	if user_name == "":
		$ConnectButton.hint_tooltip = "Logged in.\nMaterials can be submitted."
	else:
		$ConnectButton.hint_tooltip = "Logged in as "+user_name+".\nMaterials can be submitted."
	$SendButton.disabled = false

func set_logged_out() -> void:
	$ConnectButton.texture_normal = preload("res://material_maker/tools/share/broken_link.tres")
	$ConnectButton.hint_tooltip = "Click to log in and submit assets"
	$SendButton.disabled = true

func bring_to_top() -> void:
	var is_always_on_top = OS.is_window_always_on_top()
	OS.set_window_always_on_top(true)
	OS.set_window_always_on_top(is_always_on_top)
