extends Tree

export(int, 0, 3) var preview : int = 0

var update_index : int = 0

signal group_selected

func update_from_graph_edit(graph_edit) -> void:
	update_index += 1
	set_column_expand(0, true)
	columns = preview+1
	for i in range(1, columns):
		set_column_expand(i, false)
		set_column_min_width(i, 28)
	if graph_edit == null:
		return
	var file_name = "PTex"
	if graph_edit.save_path != null:
		file_name = graph_edit.save_path.get_file()
	fill_tree(graph_edit.top_generator, graph_edit.generator, file_name)

func fill_tree(top : MMGenGraph, selected : MMGenGraph, top_name : String) -> void:
	clear()
	if top == null or selected == null:
		return
	var root : TreeItem = create_item(null)
	root.set_text(0, top_name)
	if top == selected:
		root.set_custom_color(0, Color(0.5, 0.5, 1))
	else:
		root.set_custom_color(0, Color(1, 1, 1))
	root.set_metadata(0, top)
	fill_item(root, top, selected)

func set_icon(item, generator) -> void:
	var index = update_index
	var output_count = min(generator.get_output_defs().size(), 3)
	for o in range(output_count):
		var result = generator.render(o, 24, true)
		while result is GDScriptFunctionState:
			if index != update_index:
				return
			result = yield(result, "completed")
		if index == update_index:
			var tex = ImageTexture.new()
			result.copy_to_texture(tex)
			item.set_icon(1+preview-output_count+o, tex)
		result.release()

func fill_item(parent : TreeItem, generator : MMGenGraph, selected : MMGenGraph) -> void:
	for c in generator.get_children():
		if c is MMGenGraph:
			if c.is_template():
				continue
			var item : TreeItem = create_item(parent)
			item.set_text(0, c.get_type_name())
			if c == selected:
				item.set_custom_color(0, Color(0.5, 0.5, 1))
			elif c.is_editable():
				item.set_custom_color(0, Color(1, 1, 1))
			item.set_metadata(0, c)
			if preview > 0 and c.get_output_defs().size() > 0:
				call_deferred("set_icon", item, c)
			fill_item(item, c, selected)

func _on_Hierarchy_item_double_clicked():
	emit_signal("group_selected", get_selected().get_metadata(0))
