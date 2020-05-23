extends Panel

var current_tab = -1 setget set_current_tab

signal tab_changed
signal no_more_tabs

func add_child(control, legible_unique_name = false) -> void:
	.add_child(control, legible_unique_name)
	if !(control is Tabs):
		$Tabs.add_tab(control.name)
		move_child(control, $Tabs.get_tab_count()-1)

func close_tab(tab = null) -> void:
	if not tab:
		tab = $Tabs.get_current_tab()
	get_child(tab).queue_free()
	$Tabs.remove_tab(tab)
	var control = get_child(tab)
	remove_child(control)
	control.free()
	current_tab = -1
	if $Tabs.get_tab_count() == 0:
		emit_signal("no_more_tabs")
	else:
		set_current_tab(0)

func move_active_tab_to(idx_to) -> void:
	$Tabs.move_tab(current_tab, idx_to)
	move_child(get_child(current_tab), idx_to)
	set_current_tab(idx_to)

func set_current_tab(t) -> void:
	if t == current_tab or t < 0 or t >= $Tabs.get_tab_count():
		return
	var node
	if current_tab >= 0 && current_tab < $Tabs.get_tab_count():
		node = get_child(current_tab)
		node.visible = false
	current_tab = t
	node = get_child(current_tab)
	node.visible = true
	node.rect_position = Vector2(0, $Tabs.rect_size.y)
	node.rect_size = rect_size - node.rect_position
	$Tabs.current_tab = current_tab
	emit_signal("tab_changed", current_tab)

func set_tab_title(index, title) -> void:
	$Tabs.set_tab_title(index, title)

func get_current_tab_control() -> Node:
	return get_child(current_tab)

func _on_Tabs_tab_changed(tab) -> void:
	set_current_tab(tab)

func _on_Projects_resized() -> void:
	$Tabs.rect_size.x = rect_size.x
