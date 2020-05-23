extends Panel

export var rearrange_group : int = 0

var current_tab = -1

signal tab_changed
signal no_more_tabs

func _ready():
	$Tabs.set_tabs_rearrange_group(rearrange_group)
	add_to_group("tab_group_"+str(rearrange_group))

func add_child(control, legible_unique_name = false) -> void:
	.add_child(control, legible_unique_name)
	if !(control is Tabs):
		$Tabs.add_tab(control.name)
		set_current_tab($Tabs.get_tab_count()-1)

func close_tab(tab = null) -> void:
	if not tab:
		tab = $Tabs.get_current_tab()
	get_node($Tabs.get_tab_title(tab)).queue_free()
	$Tabs.remove_tab(tab)
	if $Tabs.get_tab_count() == 0:
		emit_signal("no_more_tabs")
		current_tab = -1
	else:
		set_current_tab(0)

func set_current_tab(t) -> void:
	if t == current_tab or t < 0 or t >= $Tabs.get_tab_count():
		if $Tabs.get_tab_count():
			current_tab = -1
		return
	print("Setting current tab to "+str(t))
	var node
	if current_tab >= 0:
		node = get_node($Tabs.get_tab_title(current_tab))
		if node:
			node.visible = false
	print("Hiding "+$Tabs.get_tab_title($Tabs.current_tab))
	$Tabs.current_tab = t
	current_tab = t
	node = null
	for tab_container in get_tree().get_nodes_in_group("tab_group_"+str(rearrange_group)):
		print(tab_container.name)
		node = tab_container.get_node($Tabs.get_tab_title(t))
		if node:
			break
	print(node)
	if node:
		if node.get_parent() != self:
			node.get_parent().call_deferred("set_current_tab", 0)
			node.get_parent().remove_child(node)
		.add_child(node)
		node.visible = true
		node.rect_position = Vector2(0, $Tabs.rect_size.y)
		node.rect_size = rect_size - node.rect_position
	else:
		print("Did not find panel")
	emit_signal("tab_changed", t)
