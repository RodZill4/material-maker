tool
extends Popup

signal item_double_clicked(generator)

func init(graph_name : String, generator : MMGenGraph) -> void:
	$Tree.clear()
	var root : TreeItem = $Tree.create_item(null)
	root.set_text(0, graph_name)
	root.set_metadata(0, generator)
	fill_item(root, generator)

func fill_item(parent : TreeItem, generator : MMGenGraph) -> void:
	for c in generator.get_children():
		if c is MMGenGraph:
			var item : TreeItem = $Tree.create_item(parent)
			item.set_text(0, c.get_type_name())
			item.set_metadata(0, c)
			fill_item(item, c)

func _on_Tree_item_double_clicked() -> void:
	emit_signal("item_double_clicked", $Tree.get_selected().get_metadata(0))
	queue_free()
