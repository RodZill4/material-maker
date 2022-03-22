extends Tree

export var supports_drag : bool = true

var scroll_position = 0.0

func _ready():
	print("tree")
	for c in get_children():
		print(c)
		if c.get_class() == "VScrollBar":
			c.connect("value_changed", self, "on_scrollbar")

func on_scrollbar(value : float):
	scroll_position = value
	update()

func get_last_item(parent : TreeItem):
	var last_item : TreeItem = parent.get_children()
	var item : TreeItem = last_item
	while last_item != null:
		if last_item.get_next() != null:
			last_item = last_item.get_next()
		elif !last_item.collapsed:
			last_item = last_item.get_children()
		else:
			break
		item = last_item
	return item

func _draw():
	var bottom_rect = get_item_area_rect(get_last_item(get_root()))
	var sp : float = scroll_position
	if bottom_rect.position.y + bottom_rect.size.y < rect_size.y:
		sp = 0
	var library_manager = get_parent().library_manager
	var item : TreeItem = get_root().get_children()
	while item != null:
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

func get_drag_data(_position):
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
			preview.rect_scale = Vector2(0.5, 0.5)
			preview.texture = preview_texture
		elif data.has("type") and data.type == "uniform":
			preview = ColorRect.new()
			preview.rect_size = Vector2(32, 32)
			if data.has("color"):
				preview.color = Color(data.color.r, data.color.g, data.color.b, data.color.a)
		else:
			preview = Label.new()
			preview.text = data.tree_item
		set_drag_preview(preview)
		return data
	return null
