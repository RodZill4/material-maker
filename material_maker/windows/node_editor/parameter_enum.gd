extends HBoxContainer

var enum_values = [ {name="Foo", value="foo"} ]
var enum_current = 0

const ENUM_ADD = 10000
const ENUM_EDIT = 10001
const ENUM_REMOVE = 10002
const ENUM_UP = 10003
const ENUM_DOWN = 10004

func _ready() -> void:
	update_enum_list()

func get_model_data() -> Dictionary:
	return {
		values = enum_values,
		default = enum_current,
	}

func set_model_data(data) -> void:
	enum_values = data.values.duplicate()
	if data.has("default"):
		enum_current = data.default
	else:
		enum_current = 0
	update_enum_list()

func update_enum_list() -> void:
	var options = $EnumValues
	options.clear()
	if !enum_values.is_empty():
		for i in range(enum_values.size()):
			var v = enum_values[i]
			options.add_item(v.name+" ("+v.value+")", i)
		options.add_separator()
		var v = enum_values[enum_current]
		options.add_item("Edit "+v.value, ENUM_EDIT)
		options.add_item("Remove "+v.value, ENUM_REMOVE)
		if enum_current > 0:
			options.add_item("Move "+v.value+" up", ENUM_UP)
		if enum_current < enum_values.size() - 1:
			options.add_item("Move "+v.value+" down", ENUM_DOWN)
		options.add_separator()
	options.selected = enum_current
	options.add_item("Add value", ENUM_ADD)

func _on_EnumValues_item_selected(id) -> void:
	id = $EnumValues.get_item_id(id)
	var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	if id >= 0 and id < enum_values.size():
		enum_current = id
	elif id == ENUM_EDIT:
		var dialog = preload("res://material_maker/windows/node_editor/enum_editor.tscn").instantiate()
		dialog.content_scale_factor = content_scale_factor
		dialog.min_size = Vector2(250, 90) * content_scale_factor
		var v = enum_values[enum_current]
		add_child(dialog)
		dialog.set_value(v.name, v.value)
		dialog.connect("ok", Callable(self, "update_enum_value").bind(enum_current))
		dialog.connect("popup_hide", Callable(dialog, "queue_free"))
		dialog.popup_centered()
	elif id == ENUM_ADD:
		var dialog = preload("res://material_maker/windows/node_editor/enum_editor.tscn").instantiate()
		dialog.content_scale_factor = content_scale_factor
		dialog.min_size = Vector2(250, 90) * content_scale_factor
		add_child(dialog)
		dialog.connect("ok", Callable(self, "update_enum_value").bind(-1))
		dialog.connect("popup_hide", Callable(dialog, "queue_free"))
		dialog.popup_centered()
	elif id == ENUM_REMOVE:
		enum_values.remove_at(enum_current)
		enum_current = 0
	elif id == ENUM_UP:
		var tmp = enum_values[enum_current]
		enum_values[enum_current] = enum_values[enum_current-1]
		enum_values[enum_current-1] = tmp
		enum_current -= 1
	elif id == ENUM_DOWN:
		var tmp = enum_values[enum_current]
		enum_values[enum_current] = enum_values[enum_current+1]
		enum_values[enum_current+1] = tmp
		enum_current += 1
	update_enum_list()

func update_enum_value(n, v, i) -> void:
	if i == -1:
		enum_values.append({ name=n, value=v })
		enum_current = enum_values.size()-1
	else:
		enum_values[i] = { name=n, value=v }
		enum_current = i
	update_enum_list()
