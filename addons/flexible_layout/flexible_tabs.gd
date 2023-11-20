extends Control


var flex_tab
var controls : Array = []
var current : int = -1


func _init():
	set_meta("flexlayout", true)

func add(ft):
	var tab = load("res://addons/flexible_layout/flexible_tab.tscn").instantiate()
	tab.init(ft)
	$Tabs.add_child(tab)
	custom_minimum_size.y = $Tabs.get_minimum_size().y
	controls.push_back(ft)
	if current == -1:
		set_current(0)
	else:
		ft.widget.visible = false

func erase(ft):
	var index : int = controls.find(ft)
	$Tabs.remove_child($Tabs.get_child(index))
	controls.erase(ft)
	if index == current:
		if $Tabs.get_child_count() > 0:
			set_current(0)
		else:
			set_current(-1)

func set_flex_tab(ft):
	flex_tab = ft

func set_current(c : int):
	current = c
	for i in controls.size():
		controls[i].widget.visible = (i == current)
		$Tabs.get_child(i).queue_redraw()

func _on_resized():
	print("%s: %s - %s" % [ str(self), str(position), str(size) ])
	$Tabs.queue_sort()
