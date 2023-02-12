extends Popup


@onready var http_request = $HTTPRequest

var languages : Dictionary

const INDEX_URL : String = "https://rodzill4.github.io/material-maker/languages.json"


func _ready():
	var error = http_request.request(INDEX_URL)
	if error != OK:
		print("Could not open url")
		queue_free()
		return
	var data = await http_request.request_completed[3].get_string_from_utf8()
	var test_json_conv = JSON.new()
	test_json_conv.parse(data)
	var parse_result : JSON = test_json_conv.get_data()
	if parse_result == null or ! parse_result.result is Dictionary:
		queue_free()
		return
	languages = parse_result.result
	for l in languages.keys():
		var label : Label
		var button : Button
		label = Label.new()
		label.text = TranslationServer.get_locale_name(l)
		$ScrollContainer/Languages.add_child(label)
		label = Label.new()
		label.text = "("+languages[l].author+")"
		$ScrollContainer/Languages.add_child(label)
		button = Button.new()
		button.text = "Download"
		$ScrollContainer/Languages.add_child(button)
		button.connect("pressed",Callable(self,"download_language").bind( l ))
	var minimum_size : Vector2 = $ScrollContainer/Languages.get_minimum_size()
	popup(Rect2(get_global_mouse_position(), minimum_size))

func download_language(l : String):
	var locale = load("res://material_maker/locale/locale.gd").new()
	locale.uninstall_translation(l)
	locale.create_translations_dir()
	var ext : String = languages[l].url.get_extension()
	$HTTPRequest.download_file = locale.get_translations_dir().path_join(l+"."+ext)
	var error = $HTTPRequest.request(languages[l].url)
	if error == OK:
		print("Downloading")
