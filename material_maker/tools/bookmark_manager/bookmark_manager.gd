extends Node

class_name BookmarkManager

## Graph bookmarks to revisit them later

var bookmarks : Dictionary

signal should_refresh_bookmarks



func set_bookmarks(new_bookmarks: Dictionary) -> void:
	bookmarks = new_bookmarks


static func is_default_bookmark_node(node: GraphElement) -> bool:
	return (node.get_script() in [MMGraphReroute, MMGraphComment, MMGraphCommentLine]
			or node.name in ["node_Material"])


func add_bookmark(node: GraphElement, gen_path: String) -> void:
	if not bookmarks.has(gen_path):
		var label : String = node.title
		if label == "":
			label = node.name.trim_prefix("node_")
		bookmarks[gen_path] = label
		mm_globals.set_tip_text("Added bookmark for %s" % label, 1.0, 1)
	should_refresh_bookmarks.emit()


func add_bookmark_from_path(path: String, label: String) -> void:
	bookmarks[path] = label 
	should_refresh_bookmarks.emit()


func remove_bookmark(path: String) -> void:
	bookmarks.erase(path)


func edit_bookmark(path: String, new_label: String) -> void:
	bookmarks[path] = new_label
