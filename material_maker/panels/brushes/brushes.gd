extends "res://material_maker/panels/library/library.gd"

func _ready():
	pass

func _on_Tree_item_activated():
	var main_window = get_node("/root/MainWindow")
	main_window.get_current_project().set_brush($Tree.get_selected().get_metadata(0))
