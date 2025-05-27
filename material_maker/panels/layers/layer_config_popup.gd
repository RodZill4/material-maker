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
	$GridContainer/Normal.set_value(l.normal_alpha)
	$GridContainer/Depth.set_value(l.depth_alpha)
	$GridContainer/Occlusion.set_value(l.occlusion_alpha)
	popup(Rect2($GridContainer.get_global_mouse_position() * content_scale_factor, $GridContainer.get_minimum_size()))

func _on_LayerConfigPopup_popup_hide():
	queue_free()

func _on_value_changed(value, channel):
	layer.set_alpha(channel, value)
	paint_layers.update_alpha(channel)
	paint_layers._on_Painter_painted()
