extends Tree


func _on_ready() -> void:
	update_tree()


func update_tree() -> void:
	var selected_section_id : int = 0
	var current_section: TreeItem = get_selected()
	if current_section:
		selected_section_id = current_section.get_metadata(0)
	clear()
	hide_root = true
	var root: TreeItem = create_item()
	var sections = []

	for child in %TabContainer.get_children():
		var item: TreeItem = create_item()
		item.set_text(0, " %s " % tr(child.name))
		item.set_metadata(0, child.get_index())
		sections.append(item)

	set_selected(sections[selected_section_id], 0)


func update_from_locale() -> void:
	update_tree()


func _on_item_selected() -> void:
	%TabContainer.current_tab = get_selected().get_index()
