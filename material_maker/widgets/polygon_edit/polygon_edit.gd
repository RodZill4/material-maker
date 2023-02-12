extends Control

@export var closed : bool = true : set = set_closed
var value = null : set = set_value


signal updated(polygon, old_value)

func set_closed(c : bool = true):
	closed = c
	$PolygonView.set_closed(c)

func _ready():
	set_value(MMPolygon.new())

func set_value(v) -> void:
	value = v.duplicate()
	$PolygonView.polygon = value
	$PolygonView.update()

func _on_PolygonEdit_pressed():
	var dialog = preload("res://material_maker/widgets/polygon_edit/polygon_dialog.tscn").instantiate()
	dialog.set_closed(closed)
	add_child(dialog)
	dialog.connect("polygon_changed",Callable(self,"on_value_changed"))
	var new_polygon = dialog.edit_polygon(value)
	while new_polygon is GDScriptFunctionState:
		new_polygon = await new_polygon.completed
	if new_polygon != null:
		set_value(new_polygon.value)
		emit_signal("updated", new_polygon.value.duplicate(), null if new_polygon.value.compare(new_polygon.previous_value) else new_polygon.previous_value)

func on_value_changed(v) -> void:
	set_value(v)
	emit_signal("updated", v.duplicate(), null)
