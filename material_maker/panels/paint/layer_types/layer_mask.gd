extends "res://material_maker/panels/paint/layer_types/layer.gd"

var mask : Texture

func get_layer_type() -> int:
	return LAYER_MASK

func duplicate():
	var layer = .duplicate()
	return layer

func get_channels() -> Array:
	return [ "mask" ]
