extends Tree

export var supports_drag : bool = true

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
