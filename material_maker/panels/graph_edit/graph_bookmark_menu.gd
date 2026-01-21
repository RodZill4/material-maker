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
	bookmark_manager.should_refresh_bookmarks.connect(update_bookmarks)

	%Projects.tab_changed.connect(projects_panel_tab_changed.unbind(1))

func projects_panel_tab_changed():
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


func update_bookmarks(updated_view : MMGenGraph = null) -> void:
	validate_bookmarks(updated_view)
	rebuild_bookmark_tree()


func validate_bookmarks(updated_view : MMGenGraph = null) -> void:
	# Update and remove invalid references
	var graph : MMGraphEdit = mm_globals.main_window.get_current_graph_edit()

	if tree.get_root() == null:
		return

	for item : TreeItem in tree.get_root().get_children():
		var bookmark_path : String = item.get_metadata(0)

		# Material & Brush nodes are always in top level graph
		if bookmark_path in ["./Material", "./Brush"]:
			continue

		# Bookmarked path does not point to anything
		if not graph.top_generator.has_node(bookmark_path):
			var target_node : String = bookmark_path.split("/")[-1]

			# Remove invalid reference
			bookmark_manager.remove_bookmark(bookmark_path)

			# Check if the node is part of the updated graph view
			# i.e. from grouping the currently bookmarked node

			# Add bookmark if it's in the updated view
			if updated_view != null:
				var node_path := "node_" + target_node
				if graph.has_node(node_path):
					var gen : MMGenBase = graph.get_node(node_path).generator
					var new_path := BookmarkManager.get_path_from_gen(gen, graph.top_generator)
					bookmark_manager.add_bookmark_from_path(new_path, target_node)


func rebuild_bookmark_tree() -> void:
	await get_tree().process_frame
	tree.clear()
	var root : TreeItem = tree.create_item()

	var bookmarks : Dictionary[String, String] = bookmark_manager.get_bookmarks()
	for path : String in bookmarks:
		var new_item : TreeItem = tree.create_item(root)
		new_item.set_metadata(0, path)
		new_item.set_text(0, bookmarks[path])

	# Show placeholder/hint if bookmarks are empty
	tree.visible = tree.get_root().get_child_count() != 0
	$MarginContainer.visible = tree.get_root().get_child_count() == 0


func _on_tree_item_lmb_selected() -> void:
	var selected_item : TreeItem = tree.get_selected()
	var path : String = selected_item.get_metadata(0)
	path = path.get_slice("./", 1)
	var graph : MMGraphEdit = mm_globals.main_window.get_current_graph_edit()

	var target_gen : MMGenBase

	# Top-level bookmark
	if "/" not in path:
		# Jump back to top if we are in a subgraph
		if graph.generator != graph.top_generator:
			graph.update_view(graph.top_generator)
		# Get bookmarked node from current graph
		var node_path := NodePath("node_" + path)
		if graph.has_node(node_path):
			target_gen = graph.get_node(node_path).generator
	else:
		# Subgraph bookmark
		target_gen = graph.top_generator.get_node(NodePath(path))

	if target_gen == null:
		# bookmark no longer exists
		return

	if target_gen.get_parent() is MMGenGraph and target_gen.get_parent() != graph.top_generator:
		# Jump to node's subgraph if we are not already in it
		if graph.generator != target_gen.get_parent():
			graph.update_view(target_gen.get_parent())

	# Center view on bookmarked node
	var bookmark_node_path : NodePath = "node_" + target_gen.name
	if graph.has_node(bookmark_node_path):
		var node : GraphElement = graph.get_node(bookmark_node_path)
		if node != null:
			graph.select_none()
			node.selected = true
			var center := node.position_offset + 0.5 * node.size
			var tween := get_tree().create_tween()
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
