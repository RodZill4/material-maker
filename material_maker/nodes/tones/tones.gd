extends MMGraphNodeGeneric

class Cursor:
	extends Control

	var color : Color
	var top : bool = true
	var pos : float

	const WIDTH : int = 12
	const HEIGHT : int = 12

	func _init(c, p, t = true):
		color = c
		pos = p
		top = t

	func _ready() -> void:
		position.y = -2 if top else get_parent().size.y+2-HEIGHT
		set_value(pos)
		size = Vector2(WIDTH, HEIGHT)

	func _draw() -> void:
		var polygon : PackedVector2Array
		if top:
			polygon = PackedVector2Array([Vector2(0, 0), Vector2(WIDTH/2.0, HEIGHT), Vector2(WIDTH, 0), Vector2(0, 0)])
		else:
			polygon = PackedVector2Array([Vector2(0, HEIGHT), Vector2(WIDTH/2.0, 0), Vector2(WIDTH, HEIGHT), Vector2(0, HEIGHT)])
		var c = color
		c.a = 1.0
		draw_colored_polygon(polygon, c)
		var outline_color = 0.0 if pos > 0.5 else 1.0
		draw_polyline(polygon, Color(outline_color, outline_color, outline_color), 1.0, true)

	func _gui_input(ev) -> void:
		if ev is InputEventMouseMotion && (ev.button_mask & 1) != 0:
			position.x += ev.relative.x
			position.x = min(max(-0.5*WIDTH, position.x), get_parent().size.x-0.5*WIDTH)
			update_value((position.x+0.5*WIDTH)/get_parent().size.x)

	func update_value(p : float) -> void:
		if p != pos:
			set_value(p)
			get_parent().get_parent().update_value(self, pos)
			queue_redraw()

	func set_value(v : float):
		pos = v
		position.x = pos * get_parent().size.x - 0.5*WIDTH

var cursor_in_min : Cursor
var cursor_in_mid : Cursor
var cursor_in_max : Cursor
var cursor_out_min : Cursor
var cursor_out_max : Cursor

func _ready() -> void:
	super._ready()
	var slot_color = mm_io_types.types["rgba"].color
	var slot_type = mm_io_types.types["rgba"].slot_type
	set_slot(0, true, slot_type, slot_color, true, slot_type, slot_color)
	cursor_in_min = Cursor.new(Color(0.0, 0.0, 0.0), 0.0)
	$Histogram.add_child(cursor_in_min)
	cursor_in_mid = Cursor.new(Color(0.5, 0.5, 0.5), 0.5)
	$Histogram.add_child(cursor_in_mid)
	cursor_in_max = Cursor.new(Color(1.0, 1.0, 1.0), 1.0)
	$Histogram.add_child(cursor_in_max)
	cursor_out_min = Cursor.new(Color(0.0, 0.0, 0.0), 0.0, false)
	$Histogram.add_child(cursor_out_min)
	cursor_out_max = Cursor.new(Color(1.0, 1.0, 1.0), 1.0, false)
	$Histogram.add_child(cursor_out_max)

func update_node() -> void:
	_on_Mode_item_selected(0)
	on_parameter_changed("__input_changed__", 0)
	# Preview
	restore_preview_widget()

var moving_cursor : bool = false

func on_parameter_changed(p, _v) -> void:
	if p == "__input_changed__":
		var source = generator.get_source(0)
		if source != null:
			$Histogram.set_generator(source.generator, source.output_index)
		else:
			$Histogram.set_generator(null, 0)
	elif !moving_cursor:
		var cursor = get("cursor_"+p)
		if cursor != null:
			cursor.set_value(get_parameter(p))

func get_parameter(n : String) -> float:
	var value = generator.get_parameter(n)
	match $Bar/Mode.selected:
		1:
			return value.r
		2:
			return value.g
		3:
			return value.b
		4:
			return value.a
	return (value.r+value.g+value.b)/3.0

func _on_Mode_item_selected(_id):
	cursor_in_min.set_value(get_parameter("in_min"))
	cursor_in_mid.set_value(get_parameter("in_mid"))
	cursor_in_max.set_value(get_parameter("in_max"))
	cursor_out_min.set_value(get_parameter("out_min"))
	cursor_out_max.set_value(get_parameter("out_max"))

func set_parameter(n : String, v : float, d : float) -> void:
	var value = generator.get_parameter(n)
	match $Bar/Mode.selected:
		0:
			value.r = v
			value.g = v
			value.b = v
			value.a = d
		1:
			value.r = v
		2:
			value.g = v
		3:
			value.b = v
		4:
			value.a = v
	moving_cursor = true
	get_parent().set_node_parameters(generator, { n:MMType.serialize_value(value) })
	moving_cursor = false

func update_value(control : Cursor, value : float) -> void:
	match control:
		cursor_in_min:
			set_parameter("in_min", value, 0)
		cursor_in_mid:
			set_parameter("in_mid", value, 0.5)
		cursor_in_max:
			set_parameter("in_max", value, 1)
		cursor_out_min:
			set_parameter("out_min", value, 0)
		cursor_out_max:
			set_parameter("out_max", value, 1)
	get_parent().send_changed_signal()

func _on_Auto_pressed():
	var histogram = $Histogram.get_histogram_texture().get_image()
	var in_min : int = -1
	var in_mid : int = -1
	var in_mid_value : float = 0
	var in_max : int = -1
	var histogram_size = histogram.get_size().x
	for i in range(histogram_size):
		var color : Color = histogram.get_pixel(i, 0)
		var value : float
		match $Bar/Mode.selected:
			0:
				value = (color.r+color.g+color.b)/3.0
			1:
				value = color.r
			2:
				value = color.g
			3:
				value = color.b
			4:
				value = color.a
		if value > 0.0:
			if in_min == -1:
				in_min = i
			in_max = i
			if in_mid_value < value:
				in_mid = i
				in_mid_value = value
	cursor_in_min.update_value(float(in_min)/float(histogram_size-1))
	cursor_in_mid.update_value(float(in_mid)/float(histogram_size-1))
	cursor_in_max.update_value(float(in_max)/float(histogram_size-1))
