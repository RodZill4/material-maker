extends Node


# warning-ignore:unused_class_variable
@onready var menu_manager = $MenuManager

# warning-ignore:unused_class_variable
var main_window

var config : ConfigFile = ConfigFile.new()
const DEFAULT_CONFIG = {
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
	ui_3d_preview_tonemap = 0,
	bake_ray_count = 64,
	bake_ao_ray_dist = 128.0,
	bake_ao_ray_bias = 0.005,
	bake_denoise_radius = 3,
	auto_size_comment = true
}


func _enter_tree():
	config.load("user://cache.ini")
	for k in DEFAULT_CONFIG.keys():
		if ! config.has_section_key("config", k):
			config.set_value("config", k, DEFAULT_CONFIG[k])

func _exit_tree():
	config.save("user://cache.ini")

func _ready():
	pass # Replace with function body.


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


func try_parse_palette(hex_values_str : String) -> Dictionary:
	var points = []
	var regex_color : RegEx = RegEx.new()
	regex_color.compile("#[0-9a-fA-F]+")
	var regex_matches : Array = regex_color.search_all(hex_values_str)
	var n = regex_matches.size()
	if n < 2:
		return {}
	var i = 0
	for m in regex_matches:
		if not m.strings[0].is_valid_html_color():
			return {}
		var color = Color(m.strings[0])
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
		var http_request = HTTPRequest.new()
		add_child(http_request)
		var error = http_request.request(data)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		else:
			var downloaded_data = (await http_request.request_completed)[3].get_string_from_utf8()
			var test_json_conv = JSON.new()
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

func set_tip_text(tip : String, timeout : float = 0.0):
	main_window.set_tip_text(tip, timeout)
