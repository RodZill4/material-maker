extends Control


class FlexNode:
	extends RefCounted
	var type : String
	var parent : WeakRef
	var flexible_layout : FlexLayout
	var rect : Rect2 = Rect2(0, 0, 1000, 1000)
	
	func _init(p : FlexNode = null, fl : FlexLayout = null, t = "FlexNode"):
		assert(fl != null)
		type = t
		parent = weakref(p)
		flexible_layout = fl
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			print("removing %s (%s)!" % [ self, type ])
			return
			if parent.get_ref() != null:
				parent.get_ref().replace(self, null)
	
	func get_minimum_size() -> Vector2i:
		assert(false)
		return Vector2i(0, 0)
	
	func serialize() -> Dictionary:
		var rv : Dictionary = { type=type, w=rect.size.x, h=rect.size.y, children=[] }
		for c in get_children():
			rv.children.append(c.serialize())
		return rv
	
	func deserialize(data : Dictionary):
		rect = Rect2(0, 0, data.w, data.h)
	
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
	var flex_panel : Control
	
	func _init(fp : Control):
		flex_panel = fp
		flex_panel.get_meta("flex_layout").start_flexlayout_drag()
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			flex_panel.get_meta("flex_layout").end_flexlayout_drag()


class FlexTop:
	extends FlexNode
	var child : FlexNode = null
	
	func _init(fl : FlexLayout):
		super._init(null, fl, "FlexTop")
	
	func get_minimum_size() -> Vector2i:
		return child.get_minimum_size() if child else Vector2i(0, 0)
	
	func deserialize(data : Dictionary):
		super.deserialize(data)
		child = flexible_layout.deserialize(self, data.children[0])
	
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
			new_fn.parent = weakref(self)
		else:
			child = null
			flexible_layout.delete_subwindow()
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
	
	func _init(p : FlexNode, fl : FlexLayout):
		super._init(p, fl, "FlexSplit")
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			for d in draggers:
				if is_instance_valid(d):
					d.queue_free()
	
	func get_minimum_size() -> Vector2i:
		var s : Vector2i
		if vertical:
			s = Vector2i(0, (10*children.size()-1))
			for c in children:
				var ms : Vector2i = c.get_minimum_size()
				s.x = max(s.x, ms.x)
				s.y += ms.y
		else:
			s = Vector2i(10*(children.size()-1), 0)
			for c in children:
				var ms : Vector2i = c.get_minimum_size()
				s.x += ms.x
				s.y = max(s.y, ms.y)
		return s
	
	func serialize() -> Dictionary:
		var rv : Dictionary = super.serialize()
		rv.dir = "v" if vertical else "h"
		return rv
	
	func deserialize(data : Dictionary):
		super.deserialize(data)
		vertical = data.dir == "v"
		children.clear()
		for c in data.children:
			children.append(flexible_layout.deserialize(self, c))
	
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
		fn.parent = weakref(self)
	
	func replace(fn : FlexNode, new_fn : FlexNode) -> bool:
		var index : int = children.find(fn)
		if index == -1:
			print("Error replacing FlexNode in FlexSplit")
			return false
		children.remove_at(index)
		if new_fn:
			new_fn.rect = fn.rect
			children.insert(index, new_fn)
			new_fn.parent = weakref(self)
		if children.size() == 1:
			parent.get_ref().replace(self, children[0])
			children.remove_at(0)
			for d in draggers:
				d.queue_free()
		return true
	
	func layout(r : Rect2):
		#print("Layout FlexSplit (%d children) - %s" % [ children.size(), str(r) ])
		var grip_size : int = 10
		rect = r
		var children_count : int = children.size()
		var draggers_count : int = draggers.size()
		if draggers_count < children_count-1:
			for i in children_count-1-draggers_count:
				var dragger = DRAGGER_SCENE.instantiate()
				draggers.append(dragger)
				flexible_layout.control.add_child(dragger)
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
	
	func start_flexlayout_drag(dragger_index : int, p : int) -> Vector2i:
		var c1 = children[dragger_index]
		var c2 = children[dragger_index+1]
		var min_c1_size : Vector2i = c1.get_minimum_size()
		var min_c2_size : Vector2i = c2.get_minimum_size()
		if vertical:
			return Vector2i(c1.rect.position.y+min_c1_size.y, c2.rect.position.y+c2.rect.size.y-min_c2_size.y-10)
		else:
			return Vector2i(c1.rect.position.x+min_c1_size.x, c2.rect.position.x+c2.rect.size.x-min_c2_size.x-10)

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
	var tabs : Control
	var adding : bool = false
	
	const TAB_SCENE = preload("res://addons/flexible_layout/flexible_tabs.tscn")
	
	func _init(p : FlexNode, fl : FlexLayout):
		assert(p != null)
		super._init(p, fl, "FlexTab")
		tabs = TAB_SCENE.instantiate()
		flexible_layout.control.add_child(tabs)
		tabs.set_flex_tab(self)
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			if is_instance_valid(tabs):
				tabs.queue_free()
	
	func get_minimum_size() -> Vector2i:
		var s : Vector2i = Vector2i(0, 0)
		for t : Control in tabs.get_controls():
			var ms : Vector2i = t.get_combined_minimum_size()
			s.x = max(s.x, ms.x)
			s.y = max(s.y, ms.y)
		s.y += tabs.get_combined_minimum_size().y
		return s
	
	func serialize() -> Dictionary:
		var rv : Dictionary = super.serialize()
		rv.tabs = []
		for t in tabs.get_controls():
			rv.tabs.append(t.name)
		rv.current = tabs.current
		return rv
	
	func deserialize(data : Dictionary):
		super.deserialize(data)
		for c in data.tabs:
			add(flexible_layout.main_control.panels[c])
		if data.has("current"):
			tabs.set_current(data.current)
	
	func add(fp : Control):
		adding = true
		if fp.has_meta("flex_node"):
			var current_owner = fp.get_meta("flex_node")
			current_owner.remove(fp)
			fp.remove_meta("flex_node")
		assert(not fp.has_meta("flex_node"))
		tabs.add(fp)
		if fp.get_parent() != flexible_layout.control:
			if fp.get_parent() != null:
				fp.get_parent().remove_child(fp)
			flexible_layout.control.add_child(fp)
		fp.set_meta("flex_node", self)
		adding = false
	
	func remove(fp : Control):
		assert(fp.get_meta("flex_node") == self)
		tabs.erase(fp)
		fp.remove_meta("flex_node")
		if not adding and tabs.get_controls().is_empty():
			tabs.queue_free()
			parent.get_ref().replace(self, null)
	
	func set_current(fp : Control):
		tabs.set_current(tabs.get_control_index(fp))
	
	func layout(r : Rect2):
		#print("Layout FlexTab - "+str(r))
		rect = r
		tabs.position = rect.position
		tabs.size = Vector2i(rect.size.x, 0)
		var tabs_height : int = tabs.get_combined_minimum_size().y
		for c : Control in tabs.get_controls():
			c.anchor_left = 0
			c.anchor_right = 0
			c.anchor_top = 0
			c.anchor_bottom = 0
			c.position = rect.position+Vector2(0, tabs_height)
			c.size = rect.size-Vector2(0, tabs_height)


class FlexMain:
	extends FlexNode
	var child : Control = null
	
	func _init(p : FlexNode = null, fl : FlexLayout = null):
		super._init(p, fl)
		type = "FlexMain"
	
	func get_minimum_size() -> Vector2i:
		return child.get_combined_minimum_size()
	
	func deserialize(data : Dictionary):
		super.deserialize(data)
		add(flexible_layout.main_control.panels["Main"])
	
	func add(fp : Control):
		#assert(child == null)
		child = fp
		fp.set_meta("flex_node", self)
		if fp.get_parent() != flexible_layout.control:
			flexible_layout.control.add_child(fp)
	
	func layout(r : Rect2):
		#print("Layout FlexNode - "+str(r))
		rect = r
		child.anchor_left = 0
		child.anchor_right = 0
		child.anchor_top = 0
		child.anchor_bottom = 0
		child.position = rect.position
		child.size = rect.size

class FlexLayout:
	var main_control : Control
	var control : Control
	var top : FlexTop = null
	
	func _init(m, c):
		main_control = m
		control = c
	
	func serialize() -> Dictionary:
		return top.serialize()
	
	func deserialize(parent : FlexNode, data : Dictionary) -> FlexNode:
		var fn : FlexNode
		match data.type:
			"FlexTop":
				fn = FlexTop.new(self)
			"FlexMain":
				fn = FlexMain.new(parent, self)
			"FlexSplit":
				fn = FlexSplit.new(parent, self)
			"FlexTab":
				fn = FlexTab.new(parent, self)
			_:
				print(data.type)
				assert(false)
		fn.deserialize(data)
		return fn
	
	func get_flexnode_at(p : Vector2) -> FlexNode:
		return top.get_flexnode_at(p)
	
	func get_flexmain(p : FlexNode = top) -> FlexMain:
		for c in p.get_children():
			if c is FlexMain:
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
	
	func is_panel_shown(panel_name : String) -> bool:
		var panel : Control = main_control.panels[panel_name]
		return (panel and panel.has_meta("flex_node"))
	
	func show_panel(panel_name : String):
		var panel : Control = main_control.panels[panel_name]
		if panel.has_meta("flex_node"):
			return
		if panel_name == "Main":
			get_flexmain().add(panel)
		else:
			get_default_flextab().add(panel)
	
	func init(layout = null):
		var default_flextab : FlexTab = null
		if layout != null:
			top = deserialize(null, layout)
		elif main_control == control:
			if top == null:
				top = FlexTop.new(self)
			for panel_name in main_control.panels.keys():
				show_panel(panel_name)
		layout()
	
	func layout():
		var rect : Rect2i = control.get_rect()
		if rect.size.x == 0 or rect.size.y == 0:
			return
		if top:
			rect.size = Vector2i(Vector2(rect.size))
			top.layout(rect)
		main_control.layout_changed.emit()
	
	func move_panel(panel, reference_panel : FlexNode, destination : int, test_only : bool = false) -> bool:
		var parent_panel : FlexNode = reference_panel.parent.get_ref() as FlexNode
		# if current container has only 1 tab, it cannot be dropped into or near itself
		var into_same_tab : bool = false
		if reference_panel is FlexTab and reference_panel == panel.flex_panel.get_meta("flex_node"):
			into_same_tab = true
			if reference_panel.tabs.get_controls().size() == 1:
				return false
		var vertical : bool
		var offset : int
		var tab : FlexTab = null
		match destination:
			0:
				if not reference_panel is FlexTab or into_same_tab:
					return false
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
				return false
		if not test_only:
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
			tab.add(panel.flex_panel)
			layout()
		return true

	func undock(panel : Control):
		main_control.subwindows.append(FlexWindow.new(main_control, panel))
		layout()
	
	func delete_subwindow():
		if control == main_control:
			return
		var subwindow : FlexWindow = control.get_window()
		main_control.subwindows.erase(subwindow)
		subwindow.queue_free()

class FlexWindow:
	extends Window
	
	var panel : Control
	var flex_layout : FlexLayout
	var overlay : Control
	
	func _init(main_control : Control, first_panel : Control = null):
		content_scale_factor = main_control.get_window().content_scale_factor
		if first_panel:
			position = Vector2i(first_panel.get_global_rect().position)+first_panel.get_window().position
			size = first_panel.size*content_scale_factor
		panel = Control.new()
		add_child(panel)
		panel.position = Vector2i(0, 0)
		panel.size = size/content_scale_factor
		panel.theme = main_control.owner.theme
		flex_layout = FlexLayout.new(main_control, panel)
		main_control.get_viewport().add_child(self)
		if first_panel:
			flex_layout.init({children=[{type="FlexTab",tabs=[first_panel.name],current=0,h=768,w=288,children=[]}],type="FlexTop",h=768,w=1024})
			resize()
	
	func _ready():
		self.size_changed.connect(self.resize)
	
	func resize():
		panel.position = Vector2i(0, 0)
		panel.size = size/content_scale_factor
		flex_layout.layout()
	
	func serialize() -> Dictionary:
		var data : Dictionary = {}
		data.screen = current_screen
		data.x = position.x
		data.y = position.y
		data.w = size.x
		data.h = size.y
		data.layout = flex_layout.serialize()
		return data
	
	func init(data : Dictionary):
		if data.has("screen"):
			current_screen = data.screen
		else:
			current_screen = 0
		position = Vector2i(data.x, data.y)
		size = Vector2i(data.w, data.h)
		flex_layout.init(data.layout)
		resize()
	
	func start_flexlayout_drag():
		overlay = OVERLAY_SCENE.instantiate()
		overlay.position = Vector2(0, 0)
		overlay.size = panel.size
		overlay.flex_layout = flex_layout
		panel.add_child(overlay)
	
	func end_flexlayout_drag():
		overlay.queue_free()
		overlay = null


@export var allow_undock : bool = false

var panels : Dictionary = {}
var flex_layout : FlexLayout
var subwindows : Array[Window]

var overlay : Control


const OVERLAY_SCENE = preload("res://addons/flexible_layout/flexible_overlay.tscn")


signal layout_changed


func _init():
	flex_layout = FlexLayout.new(self, self)

func _ready():
	var children = get_children()
	for c in children:
		if c.visible and ! c.has_meta("flexlayout"):
			add(c.name, c)

func _notification(what):
	match what:
		NOTIFICATION_THEME_CHANGED:
			var new_theme = null
			var control = self
			while control:
				if control is Control and control.theme != null:
					new_theme = control.theme
					break
				control = control.get_parent()
			if new_theme != null:
				for w in subwindows:
					for c in w.get_children():
						if c is Control:
							c.theme = new_theme

func add(n : String, c : Control):
	c.name = n
	c.set_meta("flex_layout", self)
	panels[n] = c

func init(layout = null):
	for p in panels.keys():
		show_panel(p, false)
	if layout and layout.has("main"):
		for w in layout.windows:
			var subwindow = FlexWindow.new(self)
			subwindow.init(w)
			subwindows.append(subwindow)
		flex_layout.init(layout.main)
	else:
		flex_layout.init(layout)

func layout():
	flex_layout.layout()
	for w in subwindows:
		w.flex_layout.layout()

func show_panel(panel_name : String, v : bool = true):
	if v:
		flex_layout.show_panel(panel_name)
	else:
		if panel_name == "Main":
			return
		var panel : Control = panels[panel_name]
		if panel.has_meta("flex_node"):
			var flex_node = panel.get_meta("flex_node")
			flex_node.remove(panel)

func serialize() -> Dictionary:
	var data : Dictionary = {}
	data.main = flex_layout.serialize()
	data.windows = []
	for w in subwindows:
		data.windows.append(w.serialize())
	return data

func start_flexlayout_drag():
	overlay = OVERLAY_SCENE.instantiate()
	overlay.position = Vector2(0, 0)
	overlay.size = size
	overlay.flex_layout = flex_layout
	add_child(overlay)
	for w in subwindows:
		w.start_flexlayout_drag()

func end_flexlayout_drag():
	overlay.queue_free()
	overlay = null
	for w in subwindows:
		w.end_flexlayout_drag()

func _on_resized():
	flex_layout.layout()
