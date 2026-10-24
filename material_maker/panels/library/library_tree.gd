extends Tree

@export var supports_drag : bool = true

var force_drag_started : bool

var tree_scrollbar : VScrollBar

func _on_ready() -> void:
	for node in get_children(true):
		if node is VScrollBar:
			tree_scrollbar = node
	if mm_globals.get_config("touch_optimization"):
		%Tree.add_theme_constant_override("v_separation", 4)

func get_last_item(parent : TreeItem):
	while true:
		if parent.collapsed:
			return parent
		var items : Array[TreeItem] = parent.get_children()
		if items.is_empty():
			return parent
		parent = items.back()

func _draw() -> void:
	if get_root() == null:
		return
	var last_tree_item = get_last_item(get_root())
	if last_tree_item == null:
		return
	var library_manager = owner.library_manager
	var items : Array[TreeItem] = get_root().get_children()
	for item in items:
		var color = library_manager.get_section_color(item.get_text(0))
		if color.a > 0.0:
			var rect : Rect2 = get_item_area_rect(item)
			var last_rect : Rect2 = rect
			if !item.collapsed:
				var last_item : TreeItem = get_last_item(item)
				if last_item != null:
					last_rect = get_item_area_rect(last_item)
			draw_rect(Rect2(1, rect.position.y, 4, last_rect.position.y-rect.position.y+last_rect.size.y), color)
		item = item.get_next()

func _get_drag_data(_position) -> Variant:
	var _data_preview : Dictionary = _get_data_preview()
	if _data_preview.is_empty():
		return null
	else:
		set_drag_preview(_data_preview.preview)
		return _data_preview.data

func _on_gui_input(event : InputEvent) -> void:
	if not force_drag_started:
		if event is InputEventScreenDrag and event.index == 0:
			var icon_rect : Rect2 = get_item_area_rect(get_selected(), 1)
			icon_rect = icon_rect.grow_individual(6, 0, 6, 0)
			if icon_rect.has_point(get_local_mouse_position()):
				## 1-finger item drag from library
				_force_drag()
				accept_event()
		elif event is InputEventScreenTouch and event.index == 0:
			if not event.pressed and mm_touch.last_touch_duration_msec > 120:
				deselect_all()

	if OS.get_name() == "Android" and event is InputEventPanGesture:
		tree_scrollbar.value += event.delta.y * 2.0
		accept_event()

func _get_data_preview() -> Dictionary:
	var selected_item = get_selected()
	if selected_item != null:
		var data = selected_item.get_metadata(0)
		if data == null:
			return {}
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

		if mm_globals.get_config("touch_optimization"):
			var offset : Vector2 = Vector2.ZERO
			preview.scale = Vector2(1.5, 1.5)
			offset = preview_texture.get_size() if preview_texture else preview.size
			preview.offset_transform_enabled = true
			preview.offset_transform_position = -offset * 0.5

		return { "preview": preview, "data": data } 
	return {}

func _force_drag() -> void:
	if force_drag_started:
		return
	force_drag_started = true
	var drag_data = _get_data_preview()
	if not drag_data.is_empty():
		force_drag(drag_data.data, drag_data.preview)
	force_drag_started = false
