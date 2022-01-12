extends "res://material_maker/panels/paint/layer_types/layer_paint.gd"

var material: Dictionary = {}


func get_layer_type() -> int:
	return LAYER_PROC


func duplicate():
	var layer = .duplicate()
	layer.material = material.duplicate(true)
	return layer


func _load_layer(data: Dictionary) -> void:
	._load_layer(data)
	material = data.material


func _save_layer(data: Dictionary):
	._save_layer(data)
	data.material = material
