tool
extends EditorPlugin

var editor = null

func _enter_tree():
	editor = preload("res://addons/procedural_material/pm_editor.tscn").instance()
	add_control_to_bottom_panel(editor, "ProceduralMaterial")

func _exit_tree():
	remove_control_from_bottom_panel(editor)
	editor.queue_free()
	editor = null

func _get_state():
	var s = {}
	return s

func _set_state(s):
	pass
