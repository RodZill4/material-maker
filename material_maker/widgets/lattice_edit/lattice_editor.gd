@tool
extends "res://material_maker/widgets/lattice_edit/lattice_view.gd"


@onready var control_points : Control = $ControlPoints
@onready var size_edit: Control = %Size
@onready var menu_bar: Control = $LatticeMenu

signal value_changed(value : MMLattice)
signal unhandled_event(event : InputEvent)


func _ready():
	super._ready()
	
	if get_parent().has_method("add_menu_bar"):
		menu_bar.get_parent().remove_child(menu_bar)
		get_parent().add_menu_bar(menu_bar, self)
	
	update_controls()


func set_lattice(p : MMLattice) -> void:
	lattice = p
	size_edit.value = lattice.size.x
	queue_redraw()
	update_controls()


func update_controls() -> void:
	for c in control_points.get_children():
		c.queue_free()
	for i in lattice.points.size():
		var p = lattice.points[i]
		var control_point = preload("res://material_maker/widgets/polygon_edit/control_point.tscn").instantiate()
		control_points.add_child(control_point)
		control_point.initialize(p, self)
		control_point.setpos(transform_point(p))
		control_point.connect("moved", Callable(self, "_on_ControlPoint_moved"))
	emit_signal("value_changed", lattice)


func is_editing() -> bool:
	for c in control_points.get_children():
		if c.is_moving:
			return true
	return false


func _on_size_value_changed(value):
	if value != lattice.size.x:
		lattice.resize(value, value)
		queue_redraw()
		update_controls()

func _on_ControlPoint_moved(index):
	var control_point = control_points.get_child(index)
	lattice.points[index] = reverse_transform_point(control_point.getpos())
	queue_redraw()
	emit_signal("value_changed", lattice)

func _on_LatticeEditor_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			var new_point_position = reverse_transform_point(get_local_mouse_position())
			lattice.add_point(new_point_position.x, new_point_position.y, closed)
			update_controls()
			return
	unhandled_event.emit(event)

func _on_resize() -> void:
	super._on_resize()
	update_controls()


var generator : MMGenBase = null
var parameter_name : String

func setup_control(g : MMGenBase, param_defs : Array) -> void:
	var need_hide : bool = true
	for p in param_defs:
		if p.type == "lattice":
			if g != generator or p.name != parameter_name:
				show()
				generator = g
				parameter_name = p.name
				value_changed.connect(self.control_update_parameter)
			if not is_editing():
				set_lattice(MMType.deserialize_value(g.get_parameter(p.name)))
			need_hide = false
			break
	if need_hide:
		hide()
		if value_changed.is_connected(self.control_update_parameter):
			value_changed.disconnect(self.control_update_parameter)
		generator = null

func control_update_parameter(_value : MMLattice):
	generator.set_parameter(parameter_name, lattice.serialize())
