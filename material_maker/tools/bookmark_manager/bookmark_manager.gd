extends Node

class_name BookmarkManager

## Top-level graph bookmarks to revisit them later

var bookmarks : Dictionary[String, String]

signal should_refresh_bookmarks


func add_bookmark(node: GraphElement, gen_path: String) -> void:
	if not bookmarks.has(gen_path):
		bookmarks[gen_path] = node.name.trim_prefix("node_")
		mm_globals.set_tip_text("Added bookmark for %s" % node.name.trim_prefix("node_"), 1.0, 1)
	should_refresh_bookmarks.emit()


func add_bookmark_from_path(path: String, label: String) -> void:
	bookmarks[path] = label 
	should_refresh_bookmarks.emit()


func remove_bookmark(path: String) -> void:
	bookmarks.erase(path)


func edit_bookmark(bookmark: Dictionary, new_label: String) -> void:
	bookmark.label = new_label


func get_bookmarks() -> Dictionary[String, String]:
	return bookmarks


static func get_path_from_gen(generator: MMGenBase, top_generator: MMGenGraph) -> String:
	var parent_gen = generator.get_parent()
	var node_path : PackedStringArray
	var current_gen = parent_gen
	node_path.append(current_gen.name)
	if current_gen != top_generator:
		while current_gen.get_parent() != top_generator:
			current_gen = current_gen.get_parent()
			node_path.append(current_gen.name)
	else:
		return "./" + generator.name
	node_path.append(".")
	node_path.reverse()
	node_path.append(generator.name)
	return "/".join(node_path)


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass
