extends Node

class_name BookmarkManager

## Top-level graph bookmarks to revisit them later

var bookmarks : Dictionary[String, Dictionary]

signal bookmark_added

func add_bookmark(node : GraphElement, is_in_subgraph : bool) -> void:
	var new_bookmark := {}

	new_bookmark.node_name = node.name
	new_bookmark.label = node.name.trim_prefix("node_")

	# temporary reference(unsaved to .ptex) to track subgraph inclusion
	new_bookmark.generator = node.generator

	# Not part of top-level graph
	if is_in_subgraph:
		return

	if not bookmarks.has(node.name):
		bookmarks[node.name] = new_bookmark
		mm_globals.set_tip_text("Added bookmark for %s" % node.name.trim_prefix("node_"), 1.0, 1)
	bookmark_added.emit()

func remove_bookmark(node_name : String) -> void:
	bookmarks.erase(node_name)

func set_generator(bookmark : Dictionary, subgraph_gen : MMGenGraph) -> void:
	bookmark.generator = subgraph_gen

func set_node(bookmark : Dictionary, node_name : String) -> void:
	bookmark.node_name = node_name

func edit_bookmark(bookmark : Dictionary, new_label : String) -> void:
	bookmark.label = new_label

func get_bookmarks() -> Dictionary[String, Dictionary]:
	return bookmarks

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
