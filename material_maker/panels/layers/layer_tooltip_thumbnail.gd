extends ColorRect

func init(layer, channel : String) -> void:
	$Label.text = channel
	material.set_shader_parameter("tex", layer.get(channel))

func init_mr(layer, channel : String, element : String, text : String) -> void:
	$Label.text = text
	material.gdshader = load("res://material_maker/panels/layers/layer_tooltip_thumbnail_"+element+".shader")
	material.set_shader_parameter("tex", layer.get(channel))
