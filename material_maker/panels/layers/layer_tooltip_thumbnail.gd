extends ColorRect

func init(layer, channel : String) -> void:
	$Label.text = channel
	material.set_shader_param("tex", layer.get(channel))

func init_m(layer) -> void:
	$Label.text = "metallic"
	material.shader = preload("res://material_maker/panels/layers/layer_tooltip_thumbnail_m.shader")
	material.set_shader_param("tex", layer.get("mr"))

func init_r(layer) -> void:
	$Label.text = "roughness"
	material.shader = preload("res://material_maker/panels/layers/layer_tooltip_thumbnail_r.shader")
	material.set_shader_param("tex", layer.get("mr"))
