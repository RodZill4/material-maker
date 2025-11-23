extends Node


@onready var menu_manager = $MenuManager

var main_window

var config : ConfigFile = ConfigFile.new()
const DEFAULT_CONFIG : Dictionary = {
	locale = "",
	confirm_quit = true,
	confirm_close_project = true,
	vsync = true,
	fps_limit = 145,
	idle_fps_limit = 20,
	max_viewport_size = 2048,
	ui_scale = 0,
	ui_3d_preview_resolution = 2.0,
	ui_3d_preview_tesselation_detail = 256,
	ui_3d_preview_sun_shadow = false,
	ui_3d_preview_tonemap_enabled = false,
	ui_3d_preview_tonemap = 0,
	ui_3d_preview_tonemap_white = 1.0,
	ui_3d_preview_tonemap_exposure = 1.0,
	ui_3d_preview_glow_enabled = false,
	ui_3d_preview_glow_bloom = 0.0,
	ui_3d_preview_glow_size = 2.0,
	ui_3d_preview_glow_intensity = 0.8,
	ui_3d_preview_glow_strength = 1.0,
	ui_3d_preview_glow_blend_mode = 1,
	ui_3d_preview_glow_blend_mix_factor = 0.05,
	ui_3d_preview_glow_lower_threshold = 1.0,
	ui_3d_preview_glow_upper_threshold = 4.0,
	ui_3d_preview_adjustment_enabled = false,
	ui_3d_preview_adjustment_brightness = 1.0,
	ui_3d_preview_adjustment_contrast = 1.0,
	ui_3d_preview_adjustment_saturation = 1.0,
	ui_3d_preview_dof_enabled = false,
	ui_3d_preview_dof_far = false,
	ui_3d_preview_dof_near = false,
	ui_3d_preview_dof_blur_amount = 0.1,
	ui_3d_preview_dof_far_distance = 10.0,
	ui_3d_preview_dof_near_distance = 2.0,
	ui_3d_preview_dof_far_transition = 5.0,
	ui_3d_preview_dof_near_transition = 1.0,
	ui_console_open = false,
	ui_console_height = 100,
	bake_ray_count = 64,
	bake_ao_ray_dist = 128.0,
	bake_ao_ray_bias = 0.005,
	bake_denoise_radius = 3,
	auto_size_comment = true,
	graph_line_curvature = 0.5,
	graph_line_style = 1,
}


func _enter_tree():
	config.load("user://mm_config.ini")
	for k : String in DEFAULT_CONFIG.keys():
		if ! config.has_section_key("config", k):
			config.set_value("config", k, DEFAULT_CONFIG[k])

func _exit_tree():
	config.save("user://mm_config.ini")

# Config

func has_config(key : String) -> bool:
	return config.has_section_key("config", key)

func get_config(key : String):
	if ! config.has_section_key("config", key):
		if DEFAULT_CONFIG.has(key):
			return DEFAULT_CONFIG[key]
		else:
			return ""
	return config.get_value("config", key)

func set_config(key : String, value):
	config.set_value("config", key, value)

# Clipboard parsing

func try_parse_palette(hex_values_str : String) -> Dictionary:
	var points = []
	var regex_color : RegEx = RegEx.new()
	regex_color.compile("#[0-9a-fA-F]+")
	var regex_matches : Array = regex_color.search_all(hex_values_str)
	var n = regex_matches.size()
	if n < 2:
		return {}
	var i : int = 0
	for m in regex_matches:
		var m_string_0 : String = m.strings[0]
		if not m_string_0.is_valid_html_color():
			return {}
		var color : Color = Color(m_string_0)
		points.push_back({
			pos = (1.0 / (2 * n)) + (float(i) / n),
			r = color.r,
			g = color.g,
			b = color.b,
			a = color.a
		})
		i += 1
	return {
		type = "colorize",
		parameters = {
			gradient = {
				interpolation = 0,
				points = points,
				type = "Gradient"
			}
		}
	}

var last_paste_data : String = ""
var last_parsed_paste_data : Dictionary = { type="none", graph={} }
func parse_paste_data(data : String):
	if data == last_paste_data:
		return last_parsed_paste_data
	var graph = {}
	var type : String = "none"
	if data.is_valid_html_color():
		var color = Color(data)
		graph = { type="uniform", color={ r=color.r, g=color.g, b=color.b, a=color.a } }
		type = "color"
	elif data.left(4) == "http":
		var http_request : HTTPRequest = HTTPRequest.new()
		add_child(http_request)
		var error = http_request.request(data)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		else:
			var downloaded_data : String = (await http_request.request_completed)[3].get_string_from_utf8()
			var test_json_conv : JSON = JSON.new()
			error = test_json_conv.parse(downloaded_data)
			if error == OK:
				graph = test_json_conv.get_data()
		http_request.queue_free()
	else:
		var test_json_conv = JSON.new()
		var error = test_json_conv.parse(data)
		if error == OK:
			graph = test_json_conv.get_data()
	if graph != null and graph is Dictionary:
		if graph.has("nodes"):
			if graph.has("type") and graph.type == "graph":
				type = "newgraph"
			else:
				type = "graph"
		elif graph.has("type"):
			type = "graph"
			graph = { connections=[], nodes=[graph] }
		else:
			graph = null
	if graph == null or ! graph is Dictionary:
		var palette = try_parse_palette(data)
		if not palette.is_empty():
			graph = palette
			type = "palette"
		else:
			graph = {}
	last_paste_data = data
	last_parsed_paste_data = { type=type, graph=graph }
	return { type=type, graph=graph }

# Misc. UI functions

func popup_menu(menu : PopupMenu, parent : Control):
	var zoom_fac = 1.0
	if parent is GraphNode:
		zoom_fac *= mm_globals.main_window.get_current_graph_edit().zoom
	
	var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	menu.popup(Rect2(parent.get_local_mouse_position()*content_scale_factor*zoom_fac + parent.get_screen_position(), Vector2(0, 0)))

func set_tip_text(tip : String, timeout : float = 0.0, priority: int = 0):
	if main_window:
		main_window.set_tip_text(TranslationServer.translate(tip), timeout, priority)
	else:
		print(tip)

static func do_propagate_shortcuts(control : Control, event : InputEvent):
	for child in control.get_children():
		if not child is Control:
			continue
		if child is Button:
			if child.shortcut and child.shortcut.matches_event(event):
				control.accept_event()
				if child.toggle_mode:
					child.button_pressed = not child.button_pressed
					child.toggled.emit(child.button_pressed)
				if child is MM_OptionEdit:
					child.roll()
				else:
					child.pressed.emit()
		do_propagate_shortcuts(child, event)

func propagate_shortcuts(control : Control, event : InputEvent):
	if not control.shortcut_context:
		return
	if not control.shortcut_context.get_global_rect().has_point(control.get_global_mouse_position()):
		return
	do_propagate_shortcuts(control, event)


func interpret_file_name(file_name: String, path:="", file_extension:="",additional_identifiers:={}) -> String:
	for i in additional_identifiers:
		file_name = file_name.replace(i, additional_identifiers[i])

	var current_graph: MMGraphEdit = get_node("/root/MainWindow").get_current_graph_edit()
	if current_graph.save_path:
		file_name = file_name.replace("$project", current_graph.save_path.get_file().trim_suffix("."+current_graph.save_path.get_extension()))
	else:
		file_name = file_name.replace("$project", "unnamed_project")

	if file_extension != "" and not file_name.ends_with(file_extension):
		file_name += file_extension

	if "$idx" in file_name:
		if path:
			var idx := 1
			while FileAccess.file_exists(path.path_join(file_name).replace("$idx", str(idx).pad_zeros(2))):
				idx += 1
			file_name = file_name.replace("$idx", str(idx).pad_zeros(2))
		else:
			file_name = file_name.replace("$idx", str(1).pad_zeros(2))

	return file_name
