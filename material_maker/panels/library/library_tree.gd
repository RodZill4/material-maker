extends Tree

@export var supports_drag : bool = true

var scroll_position = 0.0

func get_last_item(parent : TreeItem):
	while true:
		var items : Array[TreeItem] = parent.get_children()
		var last_item : TreeItem = items.back()
		if last_item.collapsed or last_item.get_children().size() == 0:
			return last_item
		else:
			parent = last_item

func _draw():
	var bottom_rect = get_item_area_rect(get_last_item(get_root()))
	var sp : float = get_scroll().y
	if bottom_rect.position.y + bottom_rect.size.y < size.y:
		sp = 0
	var library_manager = get_parent().library_manager
	var items : Array[TreeItem] = get_root().get_children()
	for item in items:
		var color = library_manager.get_section_color(item.get_text(0))
		if color != null:
			var rect : Rect2 = get_item_area_rect(item)
			var last_rect : Rect2 = rect
			if !item.collapsed:
				var last_item : TreeItem = get_last_item(item)
				if last_item != null:
					last_rect = get_item_area_rect(last_item)
			draw_rect(Rect2(1, rect.position.y+6-sp, 4, last_rect.position.y-rect.position.y+last_rect.size.y), color)
		item = item.get_next()

func _get_drag_data(_position):
	if !supports_drag:
		return null
	var selected_item = get_selected()
	if selected_item != null:
		var data = selected_item.get_metadata(0)
		if data == null:
			return null
		var preview : Control
		var preview_texture = selected_item.get_icon(1)
		if preview_texture != null:
			preview = TextureRect.new()
			preview.scale = Vector2(0.5, 0.5)
			preview.texture = preview_texture
		elif data.has("type") and data.type == "uniform":
			preview = ColorRect.new()
			preview.size = Vector2(32, 32)
			if data.has("color"):
				preview.color = Color(data.color.r, data.color.g, data.color.b, data.color.a)
		else:
			preview = Label.new()
			preview.text = data.tree_item
		set_drag_preview(preview)
		return data
	return null
