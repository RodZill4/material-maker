extends Node

var environments = []
var environment_textures = []

onready var main_window : Control = get_node("/root/MainWindow")
onready var base_dir : String = OS.get_executable_path().get_base_dir()
var ro_environments = 0

const DEFAULT_ENVIRONMENT = {
	"name": "Wide Street",
	"hdri_url": "https://hdrihaven.com/files/hdris/wide_street_01_2k.hdr",
	"show_color": false,
	"color": { "type": "Color", "r": 0, "g": 0, "b": 0, "a": 1 },
	"sky_energy": 1.1,
	"ambient_light_color": { "type": "Color", "r": 0, "g": 0, "b": 0, "a": 1 },
	"ambient_light_energy": 1,
	"ambient_light_sky_contribution": 1,
	"sun_color": { "type": "Color", "r": 1, "g": 1, "b": 1, "a": 1 },
	"sun_energy": 0,
	"sun_direction": 0,
	"sun_angle": 90
}

signal environment_updated(index)
signal name_updated(index, text)
signal thumbnail_updated(index, texture)

func _ready():
	set_physics_process(false)
	if environments.empty():
		environments = load_environment(base_dir+"/environments/environments.json")
		if environments.empty():
			environments = load_environment("res://material_maker/environments/environments.json")
		ro_environments = environments.size()
		environments += load_environment("user://environments.json")
		for i in environments.size():
			var texture : ImageTexture = ImageTexture.new()
			if environments[i].has("thumbnail"):
				var image : Image = Image.new()
				image.load_png_from_buffer(Marshalls.base64_to_raw(environments[i].thumbnail))
				texture.create_from_image(image)
			environment_textures.push_back({ thumbnail=texture })

func add_environment(data : Dictionary):
	environments.push_back(data)
	environment_textures.push_back({ thumbnail=ImageTexture.new() })
	emit_signal("name_updated", environments.size()-1, data.name)
	emit_signal("environment_updated", environments.size()-1)
	update_thumbnail(environments.size()-1)

func get_environment(index : int) -> Dictionary:
	return environments[index]

func load_environment(file_path : String) -> Array:
	var array : Array = []
	var file = File.new()
	if file.open(file_path, File.READ) == OK:
		array = parse_json(file.get_as_text())
		file.close()
	return array

func _exit_tree() -> void:
	for i in environments.size():
		var image : Image = environment_textures[i].thumbnail.get_data()
		environments[i].thumbnail = Marshalls.raw_to_base64(image.save_png_to_buffer())
	var file = File.new()
	file.open("user://environments.json", File.WRITE)
	file.store_string(JSON.print(environments.slice(3, environments.size()-1)))
	file.close()

func get_environment_list() -> Array:
	var list = []
	for i in environments.size():
		var env = environments[i]
		var env_textures = environment_textures[i]
		var item = {
			name = env.name if env.has("name") else "unnamed",
			thumbnail = env_textures.thumbnail
		}
		list.push_back(item)
	return list

func create_environment_menu(menu : PopupMenu) -> void:
	menu.clear()
	for e in get_environment_list():
		menu.add_icon_item(e.thumbnail, e.name)

func is_read_only(index) -> bool:
	return index < ro_environments

func set_value(index, variable, value, force = false):
	if index < ro_environments || index >= environments.size():
		return
	var serialized_value = MMType.serialize_value(value)
	if force or environments[index][variable] != serialized_value:
		environments[index][variable] = serialized_value
		if variable == "hdri_url":
			var status = read_hdr(index, value)
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			emit_signal("environment_updated", index)
		elif variable == "name":
			emit_signal("name_updated", index, value)
		else:
			emit_signal("environment_updated", index)
		update_thumbnail(index)

func apply_environment(index : int, e : Environment, s : DirectionalLight) -> void:
	if index < 0 || index >= environments.size():
		return
	var env : Dictionary = environments[index]
	var env_textures : Dictionary = environment_textures[index]
	e.background_mode = Environment.BG_COLOR_SKY if env.show_color else Environment.BG_SKY
	e.background_color = MMType.deserialize_value(env.color)
	if !e.has_meta("hdri") or e.get_meta("hdri") != env.hdri_url:
		if !env_textures.has("hdri"):
			var status = read_hdr(index, env.hdri_url)
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
		if env_textures.has("hdri"):
			e.background_sky.panorama = env_textures.hdri
		else:
			e.background_sky.panorama = null
		e.set_meta("hdri", env.hdri_url)
	e.background_energy = env.sky_energy
	e.ambient_light_color = MMType.deserialize_value(env.ambient_light_color)
	e.ambient_light_energy = env.ambient_light_energy
	e.ambient_light_sky_contribution = env.ambient_light_sky_contribution
	e.ambient_light_sky_contribution = env.ambient_light_sky_contribution
	s.light_color = MMType.deserialize_value(env.sun_color)
	s.light_energy = env.sun_energy
	s.rotation_degrees.y = env.sun_direction
	s.rotation_degrees.x = -env.sun_angle

var progress_window = null

var accept_dialog : AcceptDialog = null

func on_accept_dialog_closed():
	accept_dialog = null

func read_hdr(index : int, url : String) -> bool:
	while progress_window != null:
		yield(get_tree(), "idle_frame")
	environment_textures[index].erase("hdri")
	var dir : Directory = Directory.new()
	var file_path
	file_path = base_dir+"/environments/hdris/"+url.get_file()
	if dir.file_exists(file_path):
		set_hdr(index, file_path)
		return true
	file_path = "res://material_maker/environments/hdris/"+url.get_file()
	if dir.file_exists(file_path):
		set_hdr(index, file_path)
		return true
	file_path = "user://hdris/"+url.get_file()
	if dir.file_exists(file_path):
		set_hdr(index, file_path)
		return true
	Directory.new().make_dir_recursive("user://hdris")
	$HTTPRequest.download_file = file_path
	var error = $HTTPRequest.request(url)
	if error == OK:
		progress_window = preload("res://material_maker/windows/progress_window/progress_window.tscn").instance()
		main_window.add_child(progress_window)
		progress_window.set_text("Downloading HDRI file")
		progress_window.set_progress(0)
		set_physics_process(true)
		yield($HTTPRequest, "request_completed")
		progress_window.queue_free()
		progress_window = null
		set_physics_process(false)
		if Directory.new().file_exists(file_path):
			set_hdr(index, file_path)
			update_thumbnail(index)
			return true
	if accept_dialog == null:
		accept_dialog = AcceptDialog.new()
		accept_dialog.window_title = "HDRI download error"
		accept_dialog.dialog_text = "Failed to download %s" % url
		get_node("/root/MainWindow").add_child(accept_dialog)
		accept_dialog.connect("confirmed", accept_dialog, "queue_free")
		accept_dialog.connect("popup_hide", accept_dialog, "queue_free")
		accept_dialog.connect("tree_exiting", self, "on_accept_dialog_closed")
		accept_dialog.popup_centered()
	return false

"""
func _on_HTTPRequest_request_completed(_result, _response_code, _headers, _body, index):
	set_hdr(index, $HTTPRequest.download_file)
	progress_window.queue_free()
	progress_window = null
	set_physics_process(false)
	update_thumbnail(index)
	emit_signal("environment_updated", index)
"""

func _physics_process(_delta) -> void:
	progress_window.set_progress(float($HTTPRequest.get_downloaded_bytes())/float($HTTPRequest.get_body_size()))

func set_hdr(index, hdr_path) -> void:
	var hdr : ImageTexture = ImageTexture.new()
	hdr.load(hdr_path)
	environment_textures[index].hdri = hdr

func new_environment(index : int) -> void:
	var new_environment : Dictionary
	if index >= 0:
		new_environment = environments[index].duplicate()
	else:
		new_environment = DEFAULT_ENVIRONMENT
	environments.push_back(new_environment)
	environment_textures.push_back({ thumbnail=ImageTexture.new() })
	emit_signal("name_updated", environments.size()-1, new_environment.name)
	emit_signal("environment_updated", environments.size()-1)
	update_thumbnail(environments.size()-1)

func delete_environment(index : int) -> void:
	environments.remove(index)

var thumbnail_update_list = []
var rendering = false

func update_thumbnail(index) -> void:
	while rendering:
		yield(get_tree(), "idle_frame")
	if thumbnail_update_list.find(index) == -1:
		thumbnail_update_list.push_back(index)
	$Timer.wait_time = 0.5
	$Timer.one_shot = true
	$Timer.stop()
	$Timer.start()

onready var preview_generator : Viewport = $PreviewGenerator

func create_preview(index : int, size : int = 64) -> Image:
	apply_environment(index, $PreviewGenerator/CameraPosition/CameraRotation1/CameraRotation2/Camera.environment, $PreviewGenerator/Sun)
	preview_generator.size = Vector2(size, size)
	preview_generator.render_target_update_mode = Viewport.UPDATE_ONCE
	preview_generator.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	return preview_generator.get_texture().get_data()

func do_update_thumbnail() -> void:
	rendering = true
	for index in thumbnail_update_list:
		var image = create_preview(index)
		while image is GDScriptFunctionState:
			image = yield(image, "completed")
		if image != null:
			var t : ImageTexture = environment_textures[index].thumbnail
			t.create_from_image(image)
			emit_signal("thumbnail_updated", index, t)
	thumbnail_update_list = []
	rendering = false
