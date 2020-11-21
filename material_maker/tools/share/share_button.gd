extends HBoxContainer

var websocket_server : WebSocketServer
var websocket_port : int
var websocket_id : int = -1

func _ready():
	set_process(false)

func create_server() -> void:
	if websocket_server == null:
		websocket_server = WebSocketServer.new()
		websocket_server.connect("client_connected", self, "_on_client_connected")
		websocket_server.connect("client_disconnected", self, "_on_client_disconnected")
		websocket_server.connect("data_received", self, "_on_data_received")
		websocket_port = 8000
		while true:
			if websocket_server.listen(websocket_port) == OK:
				break
			websocket_port += 1
		if websocket_server.is_listening():
			print("Listening on port %d..." % websocket_port)
			set_process(true)

func _on_ConnectButton_pressed() -> void:
	if websocket_id == -1:
		create_server()
		OS.shell_open("https://material-maker.glitch.me/?mm_port=%d" % websocket_port)

func _on_SendButton_pressed():
	var main_window = get_node("/root/MainWindow")
	var status = main_window.update_preview_3d([ $PreviewViewport ])
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	$PreviewViewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	$PreviewViewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var png_image = $PreviewViewport.get_texture().get_data().save_png_to_buffer()
	var png_data = Marshalls.raw_to_base64(png_image)
	var data = { image=png_data, json=JSON.print(main_window.get_current_graph_edit().top_generator.serialize()) }
	websocket_server.get_peer(websocket_id).put_packet(JSON.print(data).to_utf8())


func _process(delta):
	websocket_server.poll()

func _on_client_connected(id: int, protocol: String) -> void:
	if websocket_id == -1:
		websocket_id = id
		$ConnectButton.texture_normal = preload("res://material_maker/tools/share/link.tres")
		$SendButton.visible = false

func _on_client_disconnected(id: int, was_clean_close: bool) -> void:
	if websocket_id == id:
		websocket_id = -1
		$ConnectButton.texture_normal = preload("res://material_maker/tools/share/broken_link.tres")
		$SendButton.visible = false

func _on_data_received(id: int) -> void:
	print("Received data "+str(id))
	var json = JSON.parse(websocket_server.get_peer(id).get_packet().get_string_from_utf8())
	if json.error == OK:
		var data = json.result
		match data.action:
			"logged_in":
				$ConnectButton.texture_normal = preload("res://material_maker/tools/share/golden_link.tres")
				$SendButton.visible = true
			"load_material":
				var main_window = get_node("/root/MainWindow")
				main_window.new_material()
				var graph_edit = main_window.get_current_graph_edit()
				var new_generator = mm_loader.create_gen(JSON.parse(data.json).result)
				graph_edit.set_new_generator(new_generator)
				main_window.hierarchy.update_from_graph_edit(graph_edit)


