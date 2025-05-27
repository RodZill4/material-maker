extends Popup

signal item_icon_double_clicked(generator)

@onready var tree = $Tree

func _ready() -> void:
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = Vector2(500, 500) * content_scale_factor

func init(graph_name : String, generator : MMGenGraph) -> void:
	tree.clear()
	var root : TreeItem = tree.create_item(null)
	root.set_text(0, graph_name)
	root.set_custom_color(0, Color(1, 1, 1))
	root.set_metadata(0, generator)
	fill_item(root, generator)

func fill_item(parent : TreeItem, generator : MMGenGraph) -> void:
	for c in generator.get_children():
		if c is MMGenGraph:
			var item : TreeItem = tree.create_item(parent)
			item.set_text(0, c.get_type_name())
			if c.is_editable():
				item.set_custom_color(0, Color(1, 1, 1))
			item.set_metadata(0, c)
			fill_item(item, c)

func _on_Tree_item_double_clicked() -> void:
	emit_signal("item_icon_double_clicked", tree.get_selected().get_metadata(0))
	queue_free()
