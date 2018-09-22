tool
extends "res://addons/material_maker/node_base.gd"

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	rv.rgb = "vec3(1.0)"
	return rv

func serialize():
	var data = .serialize()
	data.text = $Label.text
	return data

func deserialize(data):
	.deserialize(data)
	if data.has("text"):
		$Label.text = data.text

func _on_resize_request(new_minsize):
	rect_min_size = new_minsize

func _on_Label_gui_input(ev):
	if ev is InputEventMouseButton and ev.doubleclick and ev.button_index == BUTTON_LEFT:
		var dialog = preload("res://addons/material_maker/widgets/text_dialog.tscn").instance()
		dialog.set_title("Write comment")
		dialog.set_text($Label.text)
		add_child(dialog)
		dialog.connect("ok", self, "set_comment")
		dialog.popup_centered()

func set_comment(text):
	$Label.text = text
