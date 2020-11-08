extends PopupPanel

var layer : Object

func configure_layer(l : Object) -> void:
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

func _on_Metallic_value_changed(value):
	layer.set_alpha("metallic", value)

func _on_Roughness_value_changed(value):
	layer.set_alpha("roughness", value)

func _on_Emission_value_changed(value):
	layer.set_alpha("emission", value)

func _on_Depth_value_changed(value):
	layer.set_alpha("depth", value)
