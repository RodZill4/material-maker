tool
extends Panel

var current_tab = -1 setget set_current_tab

signal tab_changed
signal no_more_tabs

func _ready():
	pass

func add_child(control):
	.add_child(control)
	if !(control is Tabs):
		$Tabs.add_tab(control.name)
		move_child(control, $Tabs.get_tab_count()-1)

func close_tab(tab = null):
	if tab == null:
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

func move_active_tab_to(idx_to):
	$Tabs.move_tab(current_tab, idx_to)
	move_child(get_child(current_tab), idx_to)
	set_current_tab(idx_to)

func set_current_tab(t):
	if t == current_tab:
		return
	var node
	if current_tab >= 0 && current_tab < $Tabs.get_tab_count():
		node = get_child(current_tab)
		node.visible = false
	current_tab = t
	if current_tab >= 0 && current_tab < $Tabs.get_tab_count():
		node = get_child(current_tab)
		node.visible = true
		node.rect_position = Vector2(0, $Tabs.rect_size.y)
		node.rect_size = rect_size - node.rect_position
	else:
		print("Incorrect current tab "+str(current_tab))
	$Tabs.current_tab = current_tab
	emit_signal("tab_changed", current_tab)

func set_tab_title(index, title):
	$Tabs.set_tab_title(index, title)

func get_current_tab_control():
	return get_child(current_tab)

func _on_Tabs_tab_changed(tab):
	set_current_tab(tab)

func _on_Projects_resized():
	$Tabs.rect_size.x = rect_size.x

