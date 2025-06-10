extends "res://material_maker/widgets/splines_edit/splines_view.gd"


@onready var control_points : Control = $ControlPoints

var selected_control_points : Array[int] = []


signal value_changed(value : MMSplines)
signal unhandled_event(event : InputEvent)

@onready var menu_bar := $SplinesMenu

enum Modes {DRAW, SELECT}
var mode := Modes.DRAW

var progressive := false

var spline_font = preload("res://material_maker/theme/font_rubik/Rubik-Bold.ttf")
var font_size = 16
var text_bg_width = 12

func _ready():
	%DrawMode.button_group.pressed.connect(func(button):mode = Modes.DRAW if button.name == "DrawMode" else Modes.SELECT)

	%DrawMode.icon = get_theme_icon("draw", "MM_Icons")
	%SelectMode.icon = get_theme_icon("select", "MM_Icons")
	%DeleteControlPoints.icon = get_theme_icon("delete", "MM_Icons")
	%UnlinkControlPoints.icon = get_theme_icon("spline_unlink", "MM_Icons")
	%LinkControlPoints.icon = get_theme_icon("spline_link", "MM_Icons")
	%Progressive.icon = get_theme_icon("spline_progressive", "MM_Icons")
	%ReverseSelection.icon = get_theme_icon("spline_reverse", "MM_Icons")

	if get_parent().has_method("add_menu_bar"):
		menu_bar.get_parent().remove_child(menu_bar)
		get_parent().add_menu_bar(menu_bar, self)
	
	await get_tree().process_frame
	get_window().content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	get_window().min_size = get_window().get_contents_minimum_size() * get_window().content_scale_factor
	get_window().hide()
	get_window().popup_centered()

	super._ready()
	update_controls()

func _draw():
	if progressive and selected_control_points.size() > 1:
		for c in control_points.get_children():
			if c.is_selected:
				var index = 1+selected_control_points.find(c.get_meta("point"))
				var square_bg: Rect2
				if index >= 10:
					square_bg = Rect2(c.position+Vector2(12, -3), Vector2(text_bg_width * 2, 16))
				else:
					square_bg = Rect2(c.position+Vector2(12, -3), Vector2(text_bg_width, 16))
				draw_rect(square_bg, Color(0.05, 0.05, 0.05, 0.95), true, -1.0, true)
				draw_rect(square_bg, Color(1, 1, 1, 0.50), false, 1, false)
				draw_string(spline_font, c.position+Vector2(12, 10), str(index), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 1.0, 1.0, 1.0))
	super._draw()

func set_splines(p : MMSplines) -> void:
	splines = p
	selected_control_points = []
	queue_redraw()
	update_controls()

func update_controls() -> void:
	var i : int = 0
	for si in range(splines.splines.size()):
		for pi in range(4):
			if splines.is_linked(si, pi):
				continue
			var p : Vector2 = splines.splines[si].points[pi].position
			var control_point
			if i < control_points.get_child_count():
				control_point = control_points.get_child(i)
			else:
				control_point = preload("res://material_maker/widgets/polygon_edit/control_point.tscn").instantiate()
				control_point.selectable = true
				control_points.add_child(control_point)
			control_point.circle = (pi == 1 or pi == 2)
			control_point.select(selected_control_points.find(si*4+pi) != -1)
			control_point.initialize(p, self)
			control_point.setpos(transform_point(p))
			control_point.set_meta("point", splines.get_point_index(si, pi))
			control_point.moved.connect(self._on_ControlPoint_moved)
			control_point.selected.connect(self._on_ControlPoint_selected)
			i += 1
	while i < control_points.get_child_count():
		control_points.get_child(i).queue_free()
		i += 1
	emit_signal("value_changed", splines)


func update_control_positions() -> void:
	if control_points == null:
		return
	for control_point in control_points.get_children():
		var pi : int = control_point.get_meta("point")
		control_point.setpos(transform_point(splines.get_point_by_index(pi).position))


func is_editing() -> bool:
	for c in control_points.get_children():
		if c.is_moving:
			return true
	return false


func _on_ControlPoint_moved(index):
	var control_point : Control = control_points.get_child(index)
	var spline_point_index = control_point.get_meta("point")
	var selected : Array[int] = []
	if spline_point_index & 3 == 0 or spline_point_index & 3 == 3:
		for i in control_points.get_child_count():
			var cp : Control = control_points.get_child(i)
			var pi2 : int = cp.get_meta("point")
			if cp.is_selected and i != index and (pi2 & 3 == 0 or pi2 & 3 == 3):
				selected.append(pi2)
	splines.move_point(spline_point_index, reverse_transform_point(control_point.getpos()), selected)
	update_control_positions()
	queue_redraw()
	emit_signal("value_changed", splines)


func _on_ControlPoint_selected(index : int, is_control_pressed : bool, is_shift_pressed : bool):
	var cp = control_points.get_child(index)
	if is_control_pressed:
		if cp.is_selected:
			cp.select(false)
			selected_control_points.erase(cp.get_meta("point"))
		else:
			cp.select(true)
			selected_control_points.append(cp.get_meta("point"))
	elif is_shift_pressed:
		if cp.is_selected:
			return
		else:
			cp.select(true)
			if selected_control_points.is_empty():
				selected_control_points.append(cp.get_meta("point"))
			else:
				var last_selection = selected_control_points.back()
				var curr_selection = cp.get_meta("point")
				
				var next_selection = last_selection
				var increment = 1 if curr_selection > last_selection else -1
				while next_selection != curr_selection:
					next_selection += increment
					if splines.is_linked(0, next_selection):
						continue
					selected_control_points.append(next_selection)
				queue_redraw()
				update_controls()
	else:
		if not cp.is_selected:
			for c in control_points.get_children():
				c.select(false)
			cp.select(true)
			selected_control_points.clear()
			selected_control_points.append(cp.get_meta("point"))

func get_selection() -> Array[int]:
	return selected_control_points

func _on_delete_control_points_pressed():
	splines.delete_points_by_index(get_selection())
	selected_control_points = []
	queue_redraw()
	update_controls()

func _on_link_control_points_pressed():
	var s = get_selection()
	for i in range(1, s.size()):
		splines.link_points_by_index(s[0], s[i])
	selected_control_points = []
	queue_redraw()
	update_controls()

func _on_unlink_control_points_pressed():
	var s = get_selection()
	for i in range(s.size()):
		splines.unlink_points_by_index(s[i])
	queue_redraw()
	update_controls()

func _on_reverse_selection_pressed():
	selected_control_points.reverse()
	queue_redraw()

func _on_width_value_changed(value):
	splines.set_points_width(get_selection(), value, progressive)
	emit_signal("value_changed", splines)

func _on_offset_value_changed(value):
	splines.set_points_offset(get_selection(), value, progressive)
	emit_signal("value_changed", splines)


var creating : int = 0
var last_spline : int = -1

func handle_draw_mode(event : InputEvent) -> bool:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var new_point_position = reverse_transform_point(get_local_mouse_position())
			if event.pressed:
				match creating:
					0:
						edited = splines.Bezier.new()
						edited.points[0].position = new_point_position
						edited.points[1].position = new_point_position
						edited.points[2].position = new_point_position
						edited.points[3].position = new_point_position
						creating = 1
					2:
						edited.points[2].position = new_point_position
						edited.points[3].position = new_point_position
						creating = 3
			else:
				match creating:
					1:
						if new_point_position == edited.points[0].position:
							edited = null
							creating = 0
							last_spline = -1
						else:
							edited.points[1].position = new_point_position
							creating = 2
							return true
					3:
						edited.points[2].position = 2*edited.points[3].position - new_point_position
						var spline_index : int = splines.add_bezier(edited)
						if last_spline != -1:
							splines.link_points(last_spline, 3, spline_index, 0)
						last_spline = spline_index
						var new_spline = splines.Bezier.new()
						new_spline.points[0].position = edited.points[3].position
						new_spline.points[1].position = new_point_position
						edited = new_spline
						creating = 2
						return true
		elif event.button_index == MOUSE_BUTTON_RIGHT and edited != null:
			edited = null
			creating = 0
			last_spline = -1
		else:
			return false
		# Unselect all control points
		for c in control_points.get_children():
			c.select(false)
		selected_control_points = []
		update_controls()
		return true
	elif event is InputEventMouseMotion:
		var new_point_position = reverse_transform_point(get_local_mouse_position())
		match creating:
			1:
				edited.points[1].position = new_point_position
				edited.points[2].position = new_point_position
				edited.points[3].position = new_point_position
				return true
			2:
				edited.points[2].position = new_point_position
				edited.points[3].position = new_point_position
				return true
			3:
				edited.points[2].position = 2*edited.points[3].position - new_point_position
				return true
	return false


func _on_progressive_toggled(toggled_on: bool) -> void:
	progressive = toggled_on
	queue_redraw()


func handle_select_mode(event : InputEvent) -> bool:
	if event is InputEventMouseButton:
		for c in control_points.get_children():
			c.select(false)
		selected_control_points.clear()
		queue_redraw()
	return false


func _on_SplinesEditor_gui_input(event : InputEvent):
	if mode == Modes.DRAW:
		if handle_draw_mode(event):
			queue_redraw()
			return
	elif mode == Modes.SELECT:
		if handle_select_mode(event):
			queue_redraw()
			return
	unhandled_event.emit(event)

func _on_resized() -> void:
	super._on_resized()
	update_control_positions()


var generator : MMGenBase = null
var parameter_name : String

func set_view_rect(do : Vector2, ds : Vector2):
	super.set_view_rect(do, ds)
	update_control_positions()

func setup_control(g : MMGenBase, param_defs : Array) -> void:
	var need_hide : bool = true
	for p in param_defs:
		if p.type == "splines":
			if g != generator or p.name != parameter_name:
				show()
				generator = g
				parameter_name = p.name
				value_changed.connect(self.control_update_parameter)
				if not is_editing():
					set_splines(MMType.deserialize_value(g.get_parameter(p.name)))
			elif not is_editing():
				update_control_positions()
			need_hide = false
			break
	if need_hide:
		hide()
		if value_changed.is_connected(self.control_update_parameter):
			value_changed.disconnect(self.control_update_parameter)
		generator = null

func control_update_parameter(value : MMSplines):
	generator.set_parameter(parameter_name, splines.serialize())
