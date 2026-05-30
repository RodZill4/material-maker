extends PanelContainer


func _on_align_start_pressed() -> void:
	mm_globals.main_window.edit_align_start()


func _on_align_end_pressed() -> void:
	mm_globals.main_window.edit_align_end()


func _on_align_top_pressed() -> void:
	mm_globals.main_window.edit_align_top()


func _on_straighten_pressed() -> void:
	mm_globals.main_window.edit_straighten_connections()
