extends Control

class_name OptimizedFloatEdit

# Basic optimization for FloatEdit by swapping out the
# real controls for fake ones when interacting with the graph

var float_value: float = 0.5
@export var value: float = 0.5 :
	get:
		return $FloatEdit.float_value
	set(new_value):
		value = new_value
		$FloatEdit.set_value(new_value)

@export var min_value: float = 0.0 :
	set(v):
		min_value = v
		$FloatEdit.min_value = v

@export var max_value: float = 1.0 :
	set(v):
		max_value = v
		$FloatEdit.max_value = v

@export var step: float = 0.0 :
	set(v):
		step = v
		$FloatEdit.step = v

@export var float_only: bool = false :
	set(v):
		float_only = v
		$FloatEdit.float_only = v


func set_value(v: Variant, notify : bool = false, merge_undos : bool = false) -> void:
	$FloatEdit.set_value(v, notify, merge_undos)


func should_draw_fake_controls(should_draw : bool) -> void:
	$FloatEdit.visible = not should_draw
	$FakeFloatEdit.visible = should_draw


func _ready() -> void:
	$FakeFloatEdit.hide()
	# Draw fake controls when interacting with the graph(i.e. panning)
	var graph : MMGraphEdit = mm_globals.main_window.get_current_graph_edit()
	if graph != null:
		graph.gui_input.connect(func(event : InputEvent):
			if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.is_pressed()
			or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed())
			or (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0)
			or (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0)
			or (event is InputEventPanGesture and not event.delta)):
				should_draw_fake_controls(true)
			else:
				should_draw_fake_controls(false))
