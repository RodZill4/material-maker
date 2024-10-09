extends PanelContainer



func _open() -> void:
	%ViewMode.selected = owner.get_view_mode()
	%PostProcessing.selected = owner.get_post_processing()
	%Guides.selected = owner.get_node("Guides").style
	%GuidesColor.color = owner.get_node("Guides").color


func _on_reset_view_button_pressed() -> void:
	owner.reset_view()


func _on_view_mode_item_selected(index: int) -> void:
	owner.set_view_mode(index)


func _on_post_processing_item_selected(index: int) -> void:
	owner.set_post_processing(index)


func _on_guides_item_selected(index: int) -> void:
	owner.get_node("Guides").style = index


func _on_guides_color_color_changed(color: Color) -> void:
	owner.get_node("Guides").color = color
