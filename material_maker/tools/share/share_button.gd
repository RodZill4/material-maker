extends HBoxContainer


onready var http_request : HTTPRequest = $HTTPRequest
var request_type : String = ""

var licenses : Array = []
var my_assets : Array = []

var preview_viewport : Viewport = null


func create_preview_viewport():
	if preview_viewport == null:
		preview_viewport = load("res://material_maker/tools/share/preview_viewport.tscn").instance()
		add_child(preview_viewport)

func update_my_assets():
	var request_status = http_request.do_request("/api/getMyMaterials")
	while request_status is GDScriptFunctionState:
		request_status = yield(request_status, "completed")
	if ! request_status.has("error"):
		var status_parse_result : JSONParseResult = JSON.parse(request_status.body)
		if status_parse_result != null:
			var asset_types = [ "material", "brush", "environment", "node" ]
			my_assets = status_parse_result.result
			for a in my_assets:
				a.type = asset_types[int(a.type) & 15]

func _on_ConnectButton_pressed() -> void:
	var dialog = load("res://material_maker/tools/share/login_dialog.tscn").instance()
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
		var request_status = http_request.do_request("/login", [ "Content-Type: application/json" ], true, HTTPClient.METHOD_POST, body)
		while request_status is GDScriptFunctionState:
			request_status = yield(request_status, "completed")
		if request_status.has("error"):
			set_logged_out()
		else:
			var re : RegEx = RegEx.new()
			re.compile("<div class=\"error\">((?:.*))</div>")
			var re_match : RegExMatch = re.search(request_status.body)
			if re_match != null:
				set_logged_out()
				mm_globals.main_window.accept_dialog(re_match.strings[1], false)
				return
			request_status = http_request.do_request("/api/isConnected", [ "Content-Type: application/json" ])
			while request_status is GDScriptFunctionState:
				request_status = yield(request_status, "completed")
			if request_status.has("error"):
				set_logged_out()
				return
			var status_parse_result : JSONParseResult = JSON.parse(request_status.body)
			if status_parse_result == null:
				set_logged_out()
				return
			var status = status_parse_result.result
			if !status.connected:
				set_logged_out()
				return
			set_logged_in(status.displayed_name)
			if licenses.empty():
				request_status = http_request.do_request("/api/getLicenses")
				while request_status is GDScriptFunctionState:
					request_status = yield(request_status, "completed")
				if ! request_status.has("error"):
					status_parse_result = JSON.parse(request_status.body)
					if status_parse_result != null:
						licenses = status_parse_result.result
			if my_assets.empty():
				update_my_assets()

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
	var data = { type=asset_type, preview=preview_texture, licenses=licenses, my_assets=my_assets }
	var upload_dialog = load("res://material_maker/tools/share/upload_dialog.tscn").instance()
	var asset_info = upload_dialog.ask(data)
	while asset_info is GDScriptFunctionState:
		asset_info = yield(asset_info, "completed")
	if asset_info.empty():
		return
	var png_image = preview_texture.get_data().save_png_to_buffer()
	asset_info.type = asset_type
	asset_info.mm_version = ProjectSettings.get_setting("application/config/actual_release")
	asset_info.image_text = "data:image/png;base64,"+Marshalls.raw_to_base64(png_image)
	asset_info.json = JSON.print(asset_data)
	var url : String
	if asset_info.has("id"):
		url = "/api/updateMaterial"
		asset_info.doupdate = "on"
	else:
		url = "/api/addMaterial"
	var request_status = http_request.do_request(url, [ "Content-Type: application/json" ], true, HTTPClient.METHOD_POST, JSON.print(asset_info))
	while request_status is GDScriptFunctionState:
		request_status = yield(request_status, "completed")
	update_my_assets()

func set_logged_in(user_name : String) -> void:
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
