extends Window

var object : Object = null
var method : String
var extra_parameters : Array = []
var accept_empty : bool = false

@onready var editor = $MarginContainer/VBoxContainer/TextEdit
@onready var parser = load("res://addons/material_maker/parser/glsl_parser.gd").new()

func _context_menu_about_to_popup(context_menu):
	context_menu.position =  get_window().position + Vector2i( get_mouse_position() * mm_globals.main_window.get_window().content_scale_factor)

func _ready():
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = Vector2(300, 100) * content_scale_factor
	
	editor.get_menu().about_to_popup.connect(_context_menu_about_to_popup.bind(editor.get_menu()))

func edit_parameter(wt : String, value : String, o : Object, m : String, ep : Array = [], ae : bool = false):
	object = o
	method = m
	extra_parameters = ep
	accept_empty = ae
	title = wt
	editor.text = value
	popup_centered()
	editor.set_caret_column(editor.text.length())
	editor.grab_focus()

func _on_Apply_pressed():
	var value = editor.text.replace("\n", "").strip_edges()
	var parameters : Array = [ value ]
	parameters.append_array(extra_parameters)
	object.callv(method, parameters)

func _on_OK_pressed():
	_on_Apply_pressed()
	queue_free()

func _on_Cancel_pressed():
	queue_free()

func _on_TextEdit_gui_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				_on_OK_pressed()
			KEY_ESCAPE:
				_on_Cancel_pressed()
			_:
				if accept_empty and editor.text == "":
					$MarginContainer/VBoxContainer/HBoxContainer/OK.disabled = false
					$MarginContainer/VBoxContainer/HBoxContainer/Apply.disabled = false
				else:
					var parse_result = parser.parse(editor.text)
					if parse_result.status == "OK" and parse_result.non_terminal == "expression":
						$MarginContainer/VBoxContainer/HBoxContainer/OK.disabled = false
						$MarginContainer/VBoxContainer/HBoxContainer/Apply.disabled = false
					else:
						$MarginContainer/VBoxContainer/HBoxContainer/OK.disabled = true
						$MarginContainer/VBoxContainer/HBoxContainer/Apply.disabled = true
