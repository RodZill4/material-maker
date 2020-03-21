extends MMGraphNodeBase

class Cursor:
	extends Control

	var color : Color
	var top : bool = true
	var position : float


	const WIDTH : int = 8
	const HEIGHT : int = 8

	func _init(c, p, t = true):
		color = c
		position = p
		top = t
	
	func _ready() -> void:
		rect_position = Vector2(position * get_parent().rect_size.x - 0.5*WIDTH, -2 if top else get_parent().rect_size.y+2-HEIGHT)
		rect_size = Vector2(WIDTH, HEIGHT)

	func _draw() -> void:
		var polygon : PoolVector2Array
		if top:
			polygon = PoolVector2Array([Vector2(0, 0), Vector2(WIDTH/2, HEIGHT), Vector2(WIDTH, 0), Vector2(0, 0)])
		else:
			polygon = PoolVector2Array([Vector2(0, HEIGHT), Vector2(WIDTH/2, 0), Vector2(WIDTH, HEIGHT), Vector2(0, HEIGHT)])
		var c = color
		c.a = 1.0
		draw_colored_polygon(polygon, c)
		var outline_color = 0.0 if position > 0.5 else 1.0
		draw_polyline(polygon, Color(outline_color, outline_color, outline_color), 1.0, true)

	func _gui_input(ev) -> void:
		if ev is InputEventMouseMotion && (ev.button_mask & 1) != 0:
			rect_position.x += ev.relative.x
			rect_position.x = min(max(-0.5*WIDTH, rect_position.x), get_parent().rect_size.x-0.5*WIDTH)
			var new_position = (rect_position.x+0.5*WIDTH)/get_parent().rect_size.x
			if new_position != position:
				position = new_position
				get_parent().get_parent().update_value(self, position)
				update()

	func get_position() -> Vector2:
		return rect_position.x / (get_parent().rect_size.x - WIDTH)

var cursor_in_min : Cursor
var cursor_in_mid : Cursor
var cursor_in_max : Cursor
var cursor_out_min : Cursor
var cursor_out_max : Cursor

func _ready() -> void:
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

func set_generator(g) -> void:
	.set_generator(g)
	generator.connect("parameter_changed", self, "on_parameter_changed")
	update_node()

func update_node() -> void:
	if has_node("NodeEditButtons"):
		var r = $NodeEditButtons
		remove_child(r)
		r.free()
	rect_size = Vector2(0, 0)
	if generator.is_editable():
		var edit_buttons = preload("res://material_maker/nodes/edit_buttons.tscn").instance()
		add_child(edit_buttons)
		edit_buttons.connect_buttons(self, "edit_generator", "load_generator", "save_generator")
		set_slot(edit_buttons.get_index(), false, 0, Color(0.0, 0.0, 0.0), false, 0, Color(0.0, 0.0, 0.0))

func on_parameter_changed(p, v) -> void:
	if p == "__input_changed__":
		var source = generator.get_source(0)
		var result = source.generator.render(source.output_index, 128, true)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		result.copy_to_texture($ViewportImage/ColorRect.material.get_shader_param("tex"))
		result.release()

func set_parameter(n : String, v : float, d : float) -> void:
	var value = generator.get_parameter(n)
	match $Mode.selected:
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
	generator.set_parameter(n, value)

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

func edit_generator() -> void:
	if generator.has_method("edit"):
		generator.edit(self)

func update_generator(shader_model : Dictionary) -> void:
	generator.set_shader_model(shader_model)
	update_node()

func save_generator() -> void:
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.mmg;Material Maker Generator")
	dialog.connect("file_selected", self, "do_save_generator")
	dialog.popup_centered()

func do_save_generator(file_name : String) -> void:
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		var data = generator.serialize()
		data.name = file_name.get_file().get_basename()
		data.node_position = { x=0, y=0 }
		file.store_string(JSON.print(data, "\t", true))
		file.close()
		mm_loader.update_predefined_generators()
