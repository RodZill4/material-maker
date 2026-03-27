extends Node

var environments = []
var environment_textures = []

@onready var base_dir : String = MMPaths.get_resource_dir()
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
	if environments.is_empty():
		environments = load_environment(base_dir+"/environments/environments.json")
		if environments.is_empty():
			environments = load_environment("res://material_maker/environments/environments.json")
		ro_environments = environments.size()
		environments += load_environment("user://environments.json")
		for i in environments.size():
			var texture : ImageTexture = ImageTexture.new()
			if environments[i].has("thumbnail"):
				var image : Image = Image.new()
				if image.load_png_from_buffer(Marshalls.base64_to_raw(environments[i].thumbnail)) == OK:
					texture.set_image(image)
					#print("created thumbnail")
					#print(texture.get_size())
				else:
					print("Failed to read thumbnail for environment")
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
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file != null:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			array = json.get_data()
	return array

func _exit_tree() -> void:
	for i in environments.size():
		var image : Image = environment_textures[i].thumbnail.get_image()
		if image != null:
			environments[i].thumbnail = Marshalls.raw_to_base64(image.save_png_to_buffer())
	var file = FileAccess.open("user://environments.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(environments.slice(3, environments.size())))

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

func create_environment_menu(menu : MMMenuManager.MenuBase) -> void:
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
			await read_hdr(index, value)
			environment_updated.emit(index)
		elif variable == "name":
			name_updated.emit(index, value)
		else:
			environment_updated.emit(index)
		update_thumbnail(index)

func apply_environment(index: int, e: Environment, s: DirectionalLight3D, bg_color := Color.TRANSPARENT, force_color := false) -> void:
	if index < 0 || index >= environments.size():
		return
	var env : Dictionary = environments[index]
	var env_textures : Dictionary = environment_textures[index]

	var custom_bg_color := false

	if bg_color != Color.TRANSPARENT or force_color:
		custom_bg_color = true

		e.background_mode = Environment.BG_COLOR
		e.background_color = bg_color
		e.background_energy_multiplier = 1
	elif env.show_color:
		e.background_mode = Environment.BG_COLOR
		e.background_color = MMType.deserialize_value(env.color)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	else:
		e.background_mode = Environment.BG_SKY
		e.background_energy_multiplier = env.sky_energy

	if not e.has_meta("hdri") or e.get_meta("hdri") != env.hdri_url:
		if not env_textures.has("hdri"):
			await read_hdr(index, env.hdri_url)
		if env_textures.has("hdri"):
			if custom_bg_color:
				e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			e.sky = Sky.new()
			e.sky.sky_material = PanoramaSkyMaterial.new()
			e.sky.sky_material.panorama = env_textures.hdri
		e.set_meta("hdri", env.hdri_url)
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
		await get_tree().process_frame
	environment_textures[index].erase("hdri")
	if set_hdr(index, base_dir+"/environments/hdris/"+url.get_file()):
		return true
	if set_hdr(index, "res://material_maker/environments/hdris/"+url.get_file()):
		return true
	var file_path : String = "user://hdris/"+url.get_file()
	if set_hdr(index, file_path):
		return true
	if OS.get_name() == "HTML5":
		return false
	DirAccess.make_dir_absolute("user://hdris")
	$HTTPRequest.download_file = file_path
	var error = $HTTPRequest.request(url)
	if error == OK:
		progress_window = preload("res://material_maker/windows/progress_window/progress_window.tscn").instantiate()
		mm_globals.main_window.add_child(progress_window)
		progress_window.set_text("Downloading HDRI file")
		progress_window.set_progress(0)
		set_physics_process(true)
		await $HTTPRequest.request_completed
		progress_window.queue_free()
		progress_window = null
		set_physics_process(false)
		if set_hdr(index, file_path):
			update_thumbnail(index)
			return true
	if accept_dialog == null:
		accept_dialog = AcceptDialog.new()
		accept_dialog.title = "HDRI Download Error"
		accept_dialog.dialog_text = "Failed to download %s" % url
		accept_dialog.content_scale_factor = get_window().content_scale_factor
		accept_dialog.min_size = accept_dialog.get_contents_minimum_size() * accept_dialog.content_scale_factor
		accept_dialog.min_size.y = 40
		mm_globals.main_window.add_child(accept_dialog)
		accept_dialog.connect("confirmed", Callable(accept_dialog, "queue_free"))
		accept_dialog.connect("popup_hide", Callable(accept_dialog, "queue_free"))
		accept_dialog.connect("tree_exiting", Callable(self, "on_accept_dialog_closed"))
		accept_dialog.popup_centered()
	return false

func _physics_process(_delta) -> void:
	progress_window.set_progress(float($HTTPRequest.get_downloaded_bytes())/float($HTTPRequest.get_body_size()))

func set_hdr(index, hdr_path) -> bool:
	print("Setting hdr "+hdr_path)
	var hdr_image : Image = Image.load_from_file(hdr_path)
	if hdr_image == null:
		return false
	var hdr : ImageTexture = ImageTexture.create_from_image(hdr_image)
	environment_textures[index].hdri = hdr
	return true

func new_environment(index : int) -> void:
	var new_env : Dictionary
	if index >= 0:
		new_env = environments[index].duplicate()
	else:
		new_env = DEFAULT_ENVIRONMENT
	environments.push_back(new_env)
	environment_textures.push_back({ thumbnail=ImageTexture.new() })
	emit_signal("name_updated", environments.size()-1, new_env.name)
	emit_signal("environment_updated", environments.size()-1)
	update_thumbnail(environments.size()-1)

func delete_environment(index : int) -> void:
	environments.remove_at(index)
	environment_textures.remove_at(index)

var thumbnail_update_list = []
var rendering = false

func update_thumbnail(index) -> void:
	while rendering:
		await get_tree().process_frame
	if thumbnail_update_list.find(index) == -1:
		thumbnail_update_list.push_back(index)
	$Timer.wait_time = 0.5
	$Timer.one_shot = true
	$Timer.stop()
	$Timer.start()

@onready var preview_generator : SubViewport = $PreviewGenerator

func create_preview(index : int, size : int = 64) -> Image:
	apply_environment(index, $PreviewGenerator/CameraPosition/CameraRotation1/CameraRotation2/Camera3D.environment, $PreviewGenerator/Sun)
	preview_generator.size = Vector2(size, size)
	preview_generator.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	return preview_generator.get_texture().get_image()

func do_update_thumbnail() -> void:
	rendering = true
	for index in thumbnail_update_list:
		var image = await create_preview(index)
		if image != null:
			var t : ImageTexture = environment_textures[index].thumbnail
			t.set_image(image)
			emit_signal("thumbnail_updated", index, t)
	thumbnail_update_list = []
	rendering = false
