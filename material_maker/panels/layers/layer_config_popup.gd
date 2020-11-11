extends PopupPanel

var paint_layers : Node
var layer : Object

func configure_layer(layers : Node, l : Object) -> void:
	paint_layers = layers
	layer = l
	$GridContainer/Albedo.set_value(l.albedo_alpha)
	$GridContainer/Metallic.set_value(l.metallic_alpha)
	$GridContainer/Roughness.set_value(l.roughness_alpha)
	$GridContainer/Emission.set_value(l.emission_alpha)
	$GridContainer/Depth.set_value(l.depth_alpha)
	popup(Rect2(get_global_mouse_position(), get_minimum_size()))

func _on_LayerConfigPopup_popup_hide():
	queue_free()

func _on_Albedo_value_changed(value):
	layer.set_alpha("albedo", value)
	paint_layers.update_alpha("albedo")
	paint_layers._on_Painter_painted()

func _on_Metallic_value_changed(value):
	layer.set_alpha("metallic", value)
	paint_layers.update_alpha("metallic")
	paint_layers._on_Painter_painted()

func _on_Roughness_value_changed(value):
	layer.set_alpha("roughness", value)
	paint_layers.update_alpha("roughness")
	paint_layers._on_Painter_painted()

func _on_Emission_value_changed(value):
	layer.set_alpha("emission", value)
	paint_layers.update_alpha("emission")
	paint_layers._on_Painter_painted()

func _on_Depth_value_changed(value):
	layer.set_alpha("depth", value)
	paint_layers.update_alpha("depth")
	paint_layers._on_Painter_painted()
