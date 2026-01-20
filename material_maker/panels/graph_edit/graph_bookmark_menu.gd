extends PanelContainer

var bookmark_manager : BookmarkManager

@onready var tree := $Tree

var is_unpinned_double_click_edited := false

enum ContextMenu {
	RENAME,
	DELETE,
}

func _ready() -> void:
	if not mm_globals.main_window.is_node_ready():
		await mm_globals.main_window.ready

	# Workaround for godot issue #111756 (fixed in 4.6)
	for p in tree.get_children(true):
		if p is Popup:
			p.about_to_popup.connect(fix_tree_line_edit_size.bind(p))
			break

	bookmark_manager = mm_globals.main_window.bookmark_manager
	bookmark_manager.bookmark_added.connect(update_bookmarks)

	%Projects.tab_changed.connect(connect_graph_view_update_signal.unbind(1))


func connect_graph_view_update_signal():
	var graph : MMGraphEdit = mm_globals.main_window.get_current_graph_edit()
	if not graph.view_updated.is_connected(update_bookmarks):
		graph.view_updated.connect(update_bookmarks)


func fix_tree_line_edit_size(p : Popup):
	var vbox : VBoxContainer = p.get_child(0)
	vbox.minimum_size_changed.connect(
		func():
			await get_tree().process_frame
			var contents_min_size = vbox.get_window().get_contents_minimum_size().y
			@warning_ignore("narrowing_conversion")
			vbox.get_window().max_size.y = contents_min_size + get_theme_constant("v_separation", "Tree"))


func _open() -> void:
	update_bookmarks()


func update_bookmarks(with_updated_view : MMGenGraph = null) -> void:
	validate_bookmarks(with_updated_view)
	rebuild_bookmark_tree()


func validate_bookmarks(current_subgraph : MMGenGraph) -> void:
	var graph : MMGraphEdit = mm_globals.main_window.get_current_graph_edit()

	if tree.get_root():
		for item : TreeItem in tree.get_root().get_children():
			var bookmark : Dictionary = item.get_metadata(0)
			var node_name : String = bookmark.node_name

			if node_name in ["node_Material", "node_Brush"]:
				continue

			# Top-level graph
			if graph.generator == graph.top_generator:
				# Remove invalid reference
				if not graph.has_node(NodePath(node_name)):
					bookmark_manager.remove_bookmark(node_name)
			# Inside subgraph
			else:
				# Update bookmark to reference new subgraph node(at top-level)
				if not is_instance_valid(bookmark.generator):
					continue
				if current_subgraph != null and current_subgraph.get_children().has(bookmark.generator):
					var top_subgraph : MMGenGraph = current_subgraph
					while top_subgraph.get_parent().get_parent() is not MMGraphEdit:
						top_subgraph = top_subgraph.get_parent()

					var new_node_name := "node_" + top_subgraph.name
					bookmark_manager.remove_bookmark(node_name)
					bookmark_manager.add_bookmark_entry({
							"node_name": new_node_name,
							"label": top_subgraph.name,
							"generator": top_subgraph
					})
					


func rebuild_bookmark_tree() -> void:
	await get_tree().process_frame
	tree.clear()
	var root : TreeItem = tree.create_item()

	var bookmarks : Dictionary[String, Dictionary] = bookmark_manager.get_bookmarks()
	for bookmark_key : String in bookmarks:
		var new_item : TreeItem = tree.create_item(root)
		var bookmark = bookmarks[bookmark_key]
		new_item.set_metadata(0, bookmark)
		new_item.set_text(0, bookmark["label"])

	# Show placeholder/hint if bookmarks are empty
	tree.visible = tree.get_root().get_child_count() != 0
	$MarginContainer.visible = tree.get_root().get_child_count() == 0


func _on_tree_item_lmb_selected() -> void:
	var selected_item : TreeItem = tree.get_selected()
	var bookmark : Dictionary = selected_item.get_metadata(0)
	var node_path := NodePath(bookmark.node_name)
	var graph : MMGraphEdit = mm_globals.main_window.get_current_graph_edit()

	# Jump back to top-level graph
	if graph.generator != graph.top_generator:
		graph.update_view(graph.top_generator)

	# Center view on bookmarked node
	if graph.has_node(node_path):
		var node : GraphElement = graph.get_node(node_path)
		if node != null:
			graph.select_none()
			node.selected = true
			var tween := get_tree().create_tween()
			var center := node.position_offset + 0.5 * node.size
			var target_offset := center * graph.zoom - 0.5 * graph.size
			tween.tween_property(graph, "scroll_offset", target_offset, 0.5).set_ease(
					Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_tree_item_rmb_selected(_mouse_position : Vector2i):
	mm_globals.popup_menu($ContextMenu, self)


func _on_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			accept_event()
			if tree.get_selected():
				_on_context_menu_id_pressed(ContextMenu.RENAME)
				# keep panel pinned while editing
				is_unpinned_double_click_edited = not get_parent().pinned
				get_parent().pinned = true


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_on_tree_item_rmb_selected(mouse_position)
	elif mouse_button_index == MOUSE_BUTTON_LEFT:
		_on_tree_item_lmb_selected()


func _on_context_menu_id_pressed(id: int) -> void:
	var item : TreeItem = tree.get_selected()
	match id:
		ContextMenu.RENAME:
			item.set_editable(0, true)
			tree.edit_selected()
		ContextMenu.DELETE:
			bookmark_manager.remove_bookmark(item.get_metadata(0).node_name)
			rebuild_bookmark_tree()


func _on_tree_item_edited() -> void:
	var item : TreeItem = tree.get_selected()
	item.set_editable(0, false)
	bookmark_manager.edit_bookmark(item.get_metadata(0), item.get_text(0))
	if is_unpinned_double_click_edited:
		get_parent().pinned = false
