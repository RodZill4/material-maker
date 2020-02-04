extends Tree

func get_drag_data(position):
	var selected_item = get_selected()
	if selected_item != null:
		var data = selected_item.get_metadata(0)
		if data == null:
			return null
		var preview
		var preview_texture = get_parent().get_preview_texture(data)
		if preview_texture != null:
			preview = TextureRect.new()
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
