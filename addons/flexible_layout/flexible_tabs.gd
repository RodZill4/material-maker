extends Control


var flex_tab : WeakRef
var current : int = -1


func _init():
	set_meta("flexlayout", true)

func get_controls() -> Array[Control]:
	var controls : Array[Control] = []
	for c in $Tabs.get_children():
		controls.append(c.flex_panel)
	return controls

func get_control_index(fp : Control) -> int:
	for i in range($Tabs.get_child_count()):
		if fp == $Tabs.get_child(i).flex_panel:
			return i
	return -1

func add(ft : Control):
	var tab = load("res://addons/flexible_layout/flexible_tab.tscn").instantiate()
	tab.init(ft)
	$Tabs.add_child(tab)
	custom_minimum_size.y = $Tabs.get_minimum_size().y
	if current == -1:
		set_current(0)
	else:
		ft.visible = false

func erase(ft : Control):
	var index : int = get_control_index(ft)
	if ft.get_parent() != null:
		ft.get_parent().remove_child(ft)
	$Tabs.remove_child($Tabs.get_child(index))
	if index == current:
		if $Tabs.get_child_count() > 0:
			set_current(0)
		else:
			set_current(-1)

func get_flex_tab():
	return flex_tab.get_ref()

func set_flex_tab(ft):
	flex_tab = weakref(ft)

func set_current(c : int):
	current = c
	for i in range($Tabs.get_child_count()):
		$Tabs.get_child(i).flex_panel.visible = (i == current)
		$Tabs.get_child(i).queue_redraw()

func _on_resized():
	#print("%s: %s - %s" % [ str(self), str(position), str(size) ])
	$Tabs.queue_sort()
