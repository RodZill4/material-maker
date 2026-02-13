extends Window

var object : Object = null
var method : String

@onready var editor = $MarginContainer/VBoxContainer/TextEdit

func _on_ready() -> void:
	var csf = mm_globals.ui_scale_factor()
	get_window().content_scale_factor = csf
	get_window().min_size = size * csf


func edit_text(wt : String, value : String, o : Object, m : String):
	object = o
	method = m
	title = wt
	editor.text = value.replace("\\n", "\n")
	hide()
	popup_centered()
	editor.set_caret_column(editor.text.length())
	editor.grab_focus()


func _on_ok_button_pressed() -> void:
	var parameters : Array = [ editor.text.replace("\n","\\n") ]
	object.callv(method, parameters)
	queue_free()


func _on_cancel_button_pressed() -> void:
	queue_free()


func _on_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.as_text_keycode():
			"Shift+Enter":
				_on_ok_button_pressed()
			"Escape":
				_on_cancel_button_pressed()


func _on_close_requested() -> void:
	_on_cancel_button_pressed()
