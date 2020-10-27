extends "res://material_maker/panels/library/library.gd"

func _ready():
	pass

func _on_Tree_item_activated():
	var main_window = get_node("/root/MainWindow")
	main_window.get_current_graph_edit().new_material($Tree.get_selected().get_metadata(0))
	main_window.get_current_project().update_brush()
