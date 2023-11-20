extends Control


class FlexPanel:
	var name : String
	var widget : Control


class FlexNode:
	var type : String
	var parent : FlexNode = null
	var flexible_layout : Control
	var rect : Rect2 = Rect2(0, 0, 1000, 1000)
	
	func _init(p : FlexNode = null,fl : Control = null):
		type = "FlexNode"
		parent = p
		flexible_layout = fl
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			print("removing %s!" % type)
	
	func get_children() -> Array[FlexNode]:
		return []
	
	func get_flexnode_at(p : Vector2) -> FlexNode:
		if rect.has_point(p):
			for c in get_children():
				var rv : FlexNode = c.get_flexnode_at(p)
				if rv != null:
					return rv
			return self
		else:
			return null
			
	func replace(fn : FlexNode, new_fn : FlexNode) -> bool:
		return false


class PanelInfo:
	var flex_node : FlexNode
	var flex_panel : FlexPanel
	
	func _init(fn : FlexNode, fp : FlexPanel):
		flex_node = fn
		flex_panel = fp
		flex_node.flexible_layout.start_drag()
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			print("Goodbye!")
			flex_node.flexible_layout.end_drag()


class FlexTop:
	extends FlexNode
	var control : Control
	var child : FlexNode = null
	
	func _init(fl : Control, c : Control = null):
		type = "FlexTop"
		control = c if c else fl
		parent = null
		flexible_layout = fl
	
	func get_children() -> Array[FlexNode]:
		if child:
			return [ child ]
		return []
	
	func set_child(fn : FlexNode):
		child = fn
	
	func replace(fn : FlexNode, new_fn : FlexNode) -> bool:
		if fn != child:
			return false
		if new_fn:
			child = new_fn
			new_fn.parent = self
		else:
			child = null
		return true
	
	func layout(r : Rect2):
		rect = r
		if child:
			child.layout(r)


class FlexSplit:
	extends FlexNode
	var vertical : bool = false
	var children : Array[FlexNode] = []
	var draggers : Array[Control] = []
	
	const DRAGGER_SCENE = preload("res://addons/flexible_layout/flexible_dragger.tscn")
	
	func _init(p : FlexNode, fl : Control):
		super._init(p, fl)
		type = "FlexSplit"
	
	func get_children() -> Array[FlexNode]:
		return children
	
	func find(fn : FlexNode) -> int:
		return children.find(fn)
	
	func insert(fn : FlexNode, index : int = -1, ref_index : int = -1):
		if index == -1:
			index = children.size()
		if ref_index != -1:
			var ref : FlexNode = children[ref_index]
			if vertical:
				ref.rect.size.y /= 2
			else:
				ref.rect.size.x /= 2
			fn.rect = ref.rect
		children.insert(index, fn)
		fn.parent = self
	
	func replace(fn : FlexNode, new_fn : FlexNode) -> bool:
		var index : int = children.find(fn)
		if index == -1:
			print("Error replacing FlexNode")
			return false
		children.remove_at(index)
		if new_fn:
			new_fn.rect = fn.rect
			children.insert(index, new_fn)
			new_fn.parent = self
		if children.size() == 1:
			parent.replace(self, children[0])
			children.remove_at(0)
			for d in draggers:
				d.queue_free()
		return true
	
	func layout(r : Rect2):
		print("Layout FlexSplit (%d children) - %s" % [ children.size(), str(r) ])
		var grip_size : int = 10
		rect = r
		var children_count : int = children.size()
		var draggers_count : int = draggers.size()
		if draggers_count < children_count-1:
			for i in children_count-1-draggers_count:
				print("Creating dragger")
				var dragger = DRAGGER_SCENE.instantiate()
				draggers.append(dragger)
				flexible_layout.add_child(dragger)
		elif draggers_count > children_count-1:
			while draggers.size() > children_count-1:
				draggers.pop_back().queue_free()
		if vertical:
			var total_y_size = rect.size.y-(children_count-1)*grip_size
			var y : int = r.position.y
			var dragger_index : int = -1
			var old_height : int = 0
			var new_height : int = rect.size.y-grip_size*(children_count-1)
			for c in children:
				old_height += c.rect.size.y
			for c in children:
				if dragger_index >= 0:
					draggers[dragger_index].position = Vector2(r.position.x, y)
					draggers[dragger_index].size = Vector2(r.size.x, grip_size)
					draggers[dragger_index].set_split(self, dragger_index, vertical)
					y += grip_size
				dragger_index += 1
				var height : int = c.rect.size.y*new_height/old_height
				c.layout(Rect2(r.position.x, y, r.size.x, height))
				y += height
		else:
			var total_x_size = rect.size.x-(children_count-1)*grip_size
			var x: int = r.position.x
			var dragger_index : int = -1
			var old_width : int = 0
			var new_width : int = rect.size.x-grip_size*(children_count-1)
			for c in children:
				old_width += c.rect.size.x
			for c in children:
				if dragger_index >= 0:
					draggers[dragger_index].position = Vector2(x, r.position.y)
					draggers[dragger_index].size = Vector2(grip_size, r.size.y)
					draggers[dragger_index].set_split(self, dragger_index, vertical)
					x += grip_size
				dragger_index += 1
				var width : int = (c.rect.size.x*new_width+(old_width>>1))/old_width
				c.layout(Rect2(x, r.position.y, width, r.size.y))
				x += width
		
	func drag(dragger_index : int, p : int):
		var c1 = children[dragger_index]
		var c2 = children[dragger_index+1]
		if vertical:
			c1.layout(Rect2(c1.rect.position, Vector2(c1.rect.size.x, p-c1.rect.position.y)))
			c2.layout(Rect2(c2.rect.position.x, p+10, c1.rect.size.x, c2.rect.position.y+c2.rect.size.y-(p+10)))
		else:
			c1.layout(Rect2(c1.rect.position, Vector2(p-c1.rect.position.x, c1.rect.size.y)))
			c2.layout(Rect2(p+10, c2.rect.position.y, c2.rect.position.x+c2.rect.size.x-(p+10), c1.rect.size.y))


class FlexTab:
	extends FlexNode
	var children : Array[FlexPanel] = []
	var tabs : Control
	
	const TAB_SCENE = preload("res://addons/flexible_layout/flexible_tabs.tscn")
	
	func _init(p : FlexNode, fl : Control):
		super._init(p, fl)
		type = "FlexTab"
		assert(flexible_layout != null)
		tabs = TAB_SCENE.instantiate()
		flexible_layout.add_child(tabs)
		tabs.set_flex_tab(self)
	
	func add(fp : FlexPanel):
		children.push_back(fp)
		tabs.add(fp)
		if fp.widget.get_parent() != flexible_layout:
			flexible_layout.add_child(fp.widget)
	
	func remove(fp : FlexPanel):
		children.erase(fp)
		tabs.erase(fp)
		if children.is_empty():
			tabs.queue_free()
			parent.replace(self, null)
	
	func set_current(fp : FlexPanel):
		tabs.set_current(tabs.controls.find(fp))
	
	func layout(r : Rect2):
		print("Layout FlexTab - "+str(r))
		rect = r
		tabs.position = rect.position
		tabs.size = Vector2i(rect.size.x, 0)
		var tabs_height : int = tabs.get_combined_minimum_size().y
		for c in children:
			c.widget.position = rect.position+Vector2(0, tabs.get_combined_minimum_size().y)
			c.widget.size = rect.size-Vector2(0, tabs.get_combined_minimum_size().y)


class FlexMain:
	extends FlexNode
	var child : FlexPanel = null
	
	func _init(p : FlexNode = null, fl : Control = null):
		super._init(p, fl)
		type = "FlexMain"
	
	func add(fp : FlexPanel):
		assert(child == null)
		child = fp
		if fp.widget.get_parent() != flexible_layout:
			flexible_layout.add_child(fp.widget)
	
	func layout(r : Rect2):
		print("Layout FlexNode - "+str(r))
		rect = r
		child.widget.position = rect.position
		child.widget.size = rect.size


class FlexWindow:
	extends Window


var top : FlexTop = null
var unassigned : Array = []

var overlay : Control


const OVERLAY_SCENE = preload("res://addons/flexible_layout/flexible_overlay.tscn")


func _ready():
	var children = get_children()
	for c in children:
		if c.visible and ! c.has_meta("flexlayout"):
			add(c.name, c)
	await get_tree().process_frame
	layout()

func get_flexmain(p : FlexNode = top) -> FlexMain:
	for c in p.get_children():
		if c is FlexTab:
			return c
	for c in p.get_children():
		var rv : FlexMain = get_flexmain(c)
		if rv != null:
			return rv
	var main : FlexMain = FlexMain.new(top, top.flexible_layout)
	if top.child == null:
		top.set_child(main)
	else:
		if not top.child is FlexSplit:
			var flex_split : FlexSplit = FlexSplit.new(top, top.flexible_layout)
			flex_split.rect = top.child.rect
			flex_split.insert(top.child)
			top.set_child(flex_split)
		top.child.insert(main)
	return main

func get_default_flextab(p : FlexNode = top) -> FlexTab:
	for c in p.get_children():
		if c is FlexTab:
			return c
	for c in p.get_children():
		var rv : FlexTab = get_default_flextab(c)
		if rv != null:
			return rv
	var tab : FlexTab = FlexTab.new(top, top.flexible_layout)
	if top.child == null:
		top.set_child(tab)
	else:
		if not top.child is FlexSplit:
			var flex_split : FlexSplit = FlexSplit.new(top, top.flexible_layout)
			flex_split.rect = top.child.rect
			flex_split.insert(top.child)
			top.set_child(flex_split)
		top.child.insert(tab)
	return tab

func layout():
	var default_flextab : FlexTab = null
	print("layout")
	if top == null:
		print("creating top")
		top = FlexTop.new(self)
	for fp in unassigned:
		if fp.name == "Main":
			get_flexmain().add(fp)
		else:
			if default_flextab == null:
				default_flextab = get_default_flextab()
			default_flextab.add(fp)
	unassigned = []
	top.layout(get_rect())
	print("done")

func add(n : String, c : Control):
	var fp = FlexPanel.new()
	fp.name = n
	fp.widget = c
	unassigned.push_back(fp)

func _on_resized():
	print("resized")
	layout()

func start_drag():
	print("Starting drag")
	overlay = OVERLAY_SCENE.instantiate()
	overlay.position = Vector2(0, 0)
	overlay.size = size
	add_child(overlay)

func end_drag():
	overlay.queue_free()
	overlay = null

func get_flexnode_at(p : Vector2) -> FlexNode:
	return top.get_flexnode_at(p)

func move_panel(panel, reference_panel : FlexNode, destination):
	var parent_panel : FlexNode = reference_panel.parent
	var vertical : bool
	var offset : int
	var tab : FlexTab = null
	match destination:
		0:
			if not reference_panel is FlexTab:
				return
			tab = reference_panel
		1:
			vertical = true
			offset = 0
		2:
			vertical = false
			offset = 0
		3:
			vertical = false
			offset = 1
		4:
			vertical = true
			offset = 1
		_:
			return
	if tab == null:
		var split : FlexSplit
		if parent_panel is FlexSplit and parent_panel.vertical == vertical:
			split = parent_panel as FlexSplit
		else:
			split = FlexSplit.new(parent_panel, reference_panel.flexible_layout)
			split.vertical = vertical
			parent_panel.replace(reference_panel, split)
			split.insert(reference_panel, 0)
		tab = FlexTab.new(parent_panel, reference_panel.flexible_layout)
		var ref_index : int = split.find(reference_panel)
		split.insert(tab, ref_index+offset, ref_index)
	panel.flex_node.remove(panel.flex_panel)
	tab.add(panel.flex_panel)
	layout()
