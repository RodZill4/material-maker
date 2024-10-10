extends PanelContainer

const GUIDES_CUSTOM_GRID := 7

func _open() -> void:
	%ViewMode.selected = owner.get_view_mode()
	%PostProcessing.selected = owner.get_post_processing()
	
	%Guides.selected = owner.get_node("Guides").style
	if owner.get_node("Guides").style == 1000:
		%Guides.selected = GUIDES_CUSTOM_GRID
	%CustomGridSize.visible = %Guides.selected == GUIDES_CUSTOM_GRID
	%CustomGridSizeLabel.visible = %Guides.selected == GUIDES_CUSTOM_GRID
	
	%GuidesColor.color = owner.get_node("Guides").color
	
	size = Vector2()


func _on_reset_view_button_pressed() -> void:
	owner.reset_view()


func _on_view_mode_item_selected(index: int) -> void:
	owner.set_view_mode(index)


func _on_post_processing_item_selected(index: int) -> void:
	owner.set_post_processing(index)


func _on_guides_item_selected(index: int) -> void:
	%CustomGridSize.visible = index == GUIDES_CUSTOM_GRID
	%CustomGridSizeLabel.visible = index == GUIDES_CUSTOM_GRID
	if index == GUIDES_CUSTOM_GRID:
		owner.get_node("Guides").show_grid(%CustomGridSize.get_value())
		owner.get_node("Guides").style = 1000
	else:
		owner.get_node("Guides").style = index
	size = Vector2()


func _on_guides_color_color_changed(color: Color) -> void:
	owner.get_node("Guides").color = color


func _on_custom_grid_size_value_changed(value: Variant) -> void:
	owner.get_node("Guides").show_grid(value)
